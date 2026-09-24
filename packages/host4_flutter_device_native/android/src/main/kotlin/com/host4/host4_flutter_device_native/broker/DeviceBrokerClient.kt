package com.host4.host4_flutter_device_native.broker

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Bundle
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.ParcelFileDescriptor
import com.host4.devicebroker.IDeviceBroker
import com.host4.devicebroker.IDeviceBrokerCallback
import com.host4.devicebroker.IDeviceResultCallback
import com.host4.host4_flutter_device_native.GmacroResult
import java.io.File
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong

internal interface DeviceBrokerEventSink {
    fun onStateChanged(state: String, extras: Map<String, Any?>)
    fun onProtocolEvent(event: Map<String, Any?>)
    fun onRealtimeEvent(event: Map<String, Any?>)
    fun onOtaEvent(event: Map<String, Any?>)
}

internal interface DeviceBrokerConnector {
    fun bind(callbacks: DeviceBrokerBindCallbacks): Boolean
    fun unbind()
}

internal class DeviceBrokerBindCallbacks(
    val onConnected: (RemoteBrokerHandle) -> Unit,
    val onDisconnected: () -> Unit,
)

internal interface RemoteBrokerHandle {
    fun getState(): Map<String, Any?>
    fun openSession(clientId: String, listener: DeviceBrokerEventSink)
    fun closeSession(clientId: String)
    fun invoke(
        requestId: Long,
        method: String,
        arguments: Map<String, Any?>,
        callback: (BrokerInvokeResult) -> Unit,
    )
    fun startOta(
        requestId: Long,
        firmware: CloseableParcelFile,
        byteCount: Long,
        callback: (BrokerInvokeResult) -> Unit,
    )
    fun cancelOta(requestId: Long)
    fun linkToDeath(onDied: () -> Unit)
    fun unlinkToDeath()
}

internal interface BrokerScheduler {
    fun post(block: () -> Unit)
    fun postDelayed(delayMs: Long, token: Any, block: () -> Unit)
    fun cancel(token: Any)
    fun cancelAll()
}

internal fun interface OtaFirmwareSource {
    fun open(bytes: ByteArray): CloseableParcelFile
}

internal class CloseableParcelFile(
    private val descriptorOrNull: ParcelFileDescriptor? = null,
    private val closer: () -> Unit,
) : AutoCloseable {
    @Volatile
    var closed: Boolean = false
        private set

    val descriptor: ParcelFileDescriptor
        get() = requireNotNull(descriptorOrNull) { "Parcel file descriptor is not available." }

    override fun close() {
        if (closed) {
            return
        }
        closed = true
        closer()
    }
}

internal data class BrokerInvokeResult(
    val requestId: Long,
    val statusCode: Int,
    val errorCode: String?,
    val message: String?,
    val payload: Map<String, Any?>,
) {
    fun toGmacroResult(): GmacroResult {
        if (!errorCode.isNullOrEmpty()) {
            return GmacroResult.Error(errorCode, message, payload)
        }
        return GmacroResult.fromProtocol(statusCode, payload)
    }
}

internal class DeviceBrokerClient(
    private val connector: DeviceBrokerConnector,
    private val scheduler: BrokerScheduler,
    private val firmwareSource: OtaFirmwareSource,
    private val clientId: String = UUID.randomUUID().toString(),
    private val initialBackoffMs: Long = 1_000L,
    private val maxBackoffMs: Long = 30_000L,
) {
    var events: DeviceBrokerEventSink? = null

    @Volatile
    var closed: Boolean = false
        private set

    @Volatile
    private var handle: RemoteBrokerHandle? = null

    private val generation = AtomicInteger(0)
    private val requestIds = AtomicLong(1)
    private val pending = ConcurrentHashMap<Long, PendingRequest>()
    private var attempt = 0
    private val reconnectToken = Any()

    val isConnected: Boolean
        get() = handle != null && !closed

    fun connect() {
        if (closed) {
            return
        }
        bindNow()
    }

    fun close() {
        closed = true
        scheduler.cancelAll()
        val current = handle
        handle = null
        generation.incrementAndGet()
        failPendingRequests("Device broker client was closed.")
        runCatching { current?.closeSession(clientId) }
        runCatching { current?.unlinkToDeath() }
        connector.unbind()
    }

    fun invoke(
        method: String,
        arguments: Map<String, Any?>,
        callback: (GmacroResult) -> Unit,
    ) {
        val broker = handle
        if (broker == null) {
            callback(
                GmacroResult.Error(
                    DeviceBrokerContract.ERROR_DISCONNECTED,
                    "Device broker is not connected.",
                ),
            )
            return
        }
        val gen = generation.get()
        val requestId = requestIds.getAndIncrement()
        pending[requestId] = PendingRequest(gen, callback)
        try {
            broker.invoke(requestId, method, arguments) { result ->
                dispatch(gen) { deliver(result) }
            }
        } catch (error: Exception) {
            pending.remove(requestId)
            callback(GmacroResult.invocationError(method, error))
        }
    }

    fun startOta(firmwareData: ByteArray, callback: (GmacroResult) -> Unit) {
        val broker = handle
        if (broker == null) {
            callback(
                GmacroResult.Error(
                    DeviceBrokerContract.ERROR_DISCONNECTED,
                    "Device broker is not connected.",
                ),
            )
            return
        }
        val gen = generation.get()
        val requestId = requestIds.getAndIncrement()
        pending[requestId] = PendingRequest(gen, callback)
        var parcelFile: CloseableParcelFile? = null
        try {
            parcelFile = firmwareSource.open(firmwareData)
            broker.startOta(
                requestId,
                parcelFile,
                firmwareData.size.toLong(),
            ) { result ->
                dispatch(gen) { deliver(result) }
            }
        } catch (error: Exception) {
            pending.remove(requestId)
            callback(GmacroResult.invocationError("startOta", error))
        } finally {
            parcelFile?.close()
        }
    }

    fun cancelOta() {
        val requestId = requestIds.getAndIncrement()
        runCatching { handle?.cancelOta(requestId) }
    }

    private fun bindNow() {
        if (closed) {
            return
        }
        val bound = connector.bind(
            DeviceBrokerBindCallbacks(
                onConnected = { remote -> onConnected(remote) },
                onDisconnected = { onServiceDisconnected() },
            ),
        )
        if (!bound) {
            emitState(
                DeviceBrokerContract.STATE_DISCONNECTED,
                mapOf("reason" to "bind-failed"),
            )
            emitState(DeviceBrokerContract.STATE_RECOVERING, emptyMap())
            scheduleReconnect()
        }
    }

    private fun onConnected(remote: RemoteBrokerHandle) {
        if (closed) {
            connector.unbind()
            return
        }
        handle = remote
        attempt = 0
        val gen = generation.incrementAndGet()
        remote.linkToDeath { onBinderDied() }
        remote.openSession(clientId, forwardingSink(gen))
        runCatching {
            val state = remote.getState()
            val name = state["state"] as? String
            if (!name.isNullOrEmpty()) {
                emitState(name, state)
            }
        }
    }

    private fun onServiceDisconnected() {
        if (closed) {
            return
        }
        dropRemote("service-disconnected")
        scheduleReconnect()
    }

    private fun onBinderDied() {
        if (closed) {
            return
        }
        dropRemote("binder-died")
        scheduleReconnect()
    }

    private fun dropRemote(reason: String) {
        val current = handle
        handle = null
        generation.incrementAndGet()
        failPendingRequests("Device broker disconnected: $reason.")
        runCatching { current?.unlinkToDeath() }
        emitState(
            DeviceBrokerContract.STATE_DISCONNECTED,
            mapOf("reason" to reason),
        )
        emitState(DeviceBrokerContract.STATE_RECOVERING, emptyMap())
    }

    private fun scheduleReconnect() {
        if (closed) {
            return
        }
        scheduler.cancel(reconnectToken)
        val delay = reconnectDelayMs()
        attempt += 1
        scheduler.postDelayed(delay, reconnectToken) {
            if (!closed && handle == null) {
                bindNow()
            }
        }
    }

    private fun reconnectDelayMs(): Long {
        val shift = attempt.coerceAtMost(5)
        val delay = initialBackoffMs shl shift
        return delay.coerceAtMost(maxBackoffMs)
    }

    private fun forwardingSink(expectedGeneration: Int): DeviceBrokerEventSink {
        return object : DeviceBrokerEventSink {
            override fun onStateChanged(state: String, extras: Map<String, Any?>) {
                dispatch(expectedGeneration) { events?.onStateChanged(state, extras) }
            }

            override fun onProtocolEvent(event: Map<String, Any?>) {
                dispatch(expectedGeneration) { events?.onProtocolEvent(event) }
            }

            override fun onRealtimeEvent(event: Map<String, Any?>) {
                dispatch(expectedGeneration) { events?.onRealtimeEvent(event) }
            }

            override fun onOtaEvent(event: Map<String, Any?>) {
                dispatch(expectedGeneration) { events?.onOtaEvent(event) }
            }
        }
    }

    private fun deliver(result: BrokerInvokeResult) {
        val pendingRequest = pending.remove(result.requestId) ?: return
        if (pendingRequest.generation != generation.get()) {
            return
        }
        pendingRequest.callback(result.toGmacroResult())
    }

    private fun failPendingRequests(message: String) {
        pending.entries.forEach { (requestId, request) ->
            if (pending.remove(requestId, request)) {
                request.callback(
                    GmacroResult.Error(
                        DeviceBrokerContract.ERROR_DISCONNECTED,
                        message,
                    ),
                )
            }
        }
    }

    private fun dispatch(expectedGeneration: Int, block: () -> Unit) {
        scheduler.post {
            if (closed || expectedGeneration != generation.get()) {
                return@post
            }
            block()
        }
    }

    private fun emitState(state: String, extras: Map<String, Any?>) {
        scheduler.post {
            if (!closed) {
                events?.onStateChanged(state, extras)
            }
        }
    }

    private data class PendingRequest(
        val generation: Int,
        val callback: (GmacroResult) -> Unit,
    )
}

internal class ContextDeviceBrokerConnector(
    private val context: Context,
    private val serviceClassName: String = DeviceBrokerContract.SERVICE_CLASS_NAME,
) : DeviceBrokerConnector {
    private var connection: ServiceConnection? = null

    override fun bind(callbacks: DeviceBrokerBindCallbacks): Boolean {
        unbind()
        val connection = object : ServiceConnection {
            override fun onServiceConnected(name: ComponentName, service: IBinder) {
                callbacks.onConnected(
                    AidlRemoteBrokerHandle(IDeviceBroker.Stub.asInterface(service)),
                )
            }

            override fun onServiceDisconnected(name: ComponentName) {
                callbacks.onDisconnected()
            }
        }
        this.connection = connection
        val intent = Intent(DeviceBrokerContract.SERVICE_ACTION)
            .setClassName(context.packageName, serviceClassName)
        return BrokerServiceLaunchPolicy.startThenBind(
            startService = {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            },
            bindService = {
                context.bindService(intent, connection, Context.BIND_AUTO_CREATE)
            },
        )
    }

    override fun unbind() {
        val current = connection ?: return
        connection = null
        runCatching { context.unbindService(current) }
    }
}

internal object BrokerServiceLaunchPolicy {
    fun startThenBind(
        startService: () -> Unit,
        bindService: () -> Boolean,
    ): Boolean {
        runCatching(startService)
        return runCatching(bindService).getOrDefault(false)
    }
}

internal class AidlRemoteBrokerHandle(
    private val broker: IDeviceBroker,
) : RemoteBrokerHandle {
    private var deathRecipient: IBinder.DeathRecipient? = null

    override fun getState(): Map<String, Any?> {
        return BrokerBundleCodec.toMap(broker.state)
    }

    override fun openSession(clientId: String, listener: DeviceBrokerEventSink) {
        broker.openSession(
            clientId,
            object : IDeviceBrokerCallback.Stub() {
                override fun onStateChanged(state: String, extras: Bundle?) {
                    listener.onStateChanged(state, BrokerBundleCodec.toMap(extras))
                }

                override fun onProtocolEvent(event: Bundle?) {
                    listener.onProtocolEvent(BrokerBundleCodec.toMap(event))
                }

                override fun onRealtimeEvent(event: Bundle?) {
                    listener.onRealtimeEvent(BrokerBundleCodec.toMap(event))
                }

                override fun onOtaEvent(event: Bundle?) {
                    listener.onOtaEvent(BrokerBundleCodec.toMap(event))
                }
            },
        )
    }

    override fun closeSession(clientId: String) {
        broker.closeSession(clientId)
    }

    override fun invoke(
        requestId: Long,
        method: String,
        arguments: Map<String, Any?>,
        callback: (BrokerInvokeResult) -> Unit,
    ) {
        broker.invoke(
            requestId,
            method,
            BrokerBundleCodec.toBundle(arguments),
            resultCallback(callback),
        )
    }

    override fun startOta(
        requestId: Long,
        firmware: CloseableParcelFile,
        byteCount: Long,
        callback: (BrokerInvokeResult) -> Unit,
    ) {
        broker.startOta(requestId, firmware.descriptor, byteCount, resultCallback(callback))
    }

    override fun cancelOta(requestId: Long) {
        broker.cancelOta(requestId)
    }

    override fun linkToDeath(onDied: () -> Unit) {
        unlinkToDeath()
        val recipient = IBinder.DeathRecipient { onDied() }
        deathRecipient = recipient
        broker.asBinder().linkToDeath(recipient, 0)
    }

    override fun unlinkToDeath() {
        val recipient = deathRecipient ?: return
        deathRecipient = null
        runCatching { broker.asBinder().unlinkToDeath(recipient, 0) }
    }

    private fun resultCallback(
        callback: (BrokerInvokeResult) -> Unit,
    ): IDeviceResultCallback {
        return object : IDeviceResultCallback.Stub() {
            override fun onResult(
                requestId: Long,
                statusCode: Int,
                errorCode: String?,
                message: String?,
                payload: Bundle?,
            ) {
                callback(
                    BrokerInvokeResult(
                        requestId = requestId,
                        statusCode = statusCode,
                        errorCode = errorCode,
                        message = message,
                        payload = BrokerBundleCodec.toMap(payload),
                    ),
                )
            }
        }
    }
}

internal class MainHandlerBrokerScheduler(
    private val handler: Handler,
) : BrokerScheduler {
    private val tokens = ConcurrentHashMap<Any, Runnable>()

    override fun post(block: () -> Unit) {
        handler.post(block)
    }

    override fun postDelayed(delayMs: Long, token: Any, block: () -> Unit) {
        cancel(token)
        val runnable = Runnable {
            tokens.remove(token)
            block()
        }
        tokens[token] = runnable
        handler.postDelayed(runnable, delayMs)
    }

    override fun cancel(token: Any) {
        val runnable = tokens.remove(token) ?: return
        handler.removeCallbacks(runnable)
    }

    override fun cancelAll() {
        tokens.values.forEach { handler.removeCallbacks(it) }
        tokens.clear()
    }
}

internal class TempFileOtaFirmwareSource(
    private val cacheDir: File,
) : OtaFirmwareSource {
    override fun open(bytes: ByteArray): CloseableParcelFile {
        val file = File.createTempFile("host4-ota-", ".bin", cacheDir)
        file.writeBytes(bytes)
        val descriptor = ParcelFileDescriptor.open(
            file,
            ParcelFileDescriptor.MODE_READ_ONLY,
        )
        return CloseableParcelFile(descriptor) {
            runCatching { descriptor.close() }
            file.delete()
        }
    }
}

internal object BrokerTransportMapper {
    fun toTransportEvent(state: String, extras: Map<String, Any?>): Map<String, Any?> {
        val reason = extras["reason"]?.toString()
        val failure = reason?.let {
            mapOf(
                "code" to (extras["code"] as? String ?: it),
                "message" to (extras["message"] as? String ?: it),
                "details" to extras,
            )
        }
        val type = when (state) {
            DeviceBrokerContract.STATE_CREATED,
            DeviceBrokerContract.STATE_OPENING -> "connecting"
            DeviceBrokerContract.STATE_READY -> "ready"
            DeviceBrokerContract.STATE_DISCONNECTED -> "disconnected"
            DeviceBrokerContract.STATE_STOPPED -> "disconnected"
            DeviceBrokerContract.STATE_RECOVERING -> "recovering"
            DeviceBrokerContract.STATE_ERROR -> "error"
            else -> "error"
        }
        return buildMap {
            put("type", type)
            if (failure != null && type != "ready" && type != "connecting") {
                put("failure", failure)
            }
        }
    }
}
