package com.host4.host4_flutter_device_native.broker

import com.host4.host4_flutter_device_native.GmacroResult
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertTrue

internal class DeviceBrokerClientTest {
    @Test
    fun connect_opensSessionAndForwardsReady() {
        val env = Env()
        val states = mutableListOf<String>()
        env.client.events = RecordingSink(onState = { state, _ -> states.add(state) })

        env.client.connect()

        assertEquals(1, env.connector.bindCount)
        assertEquals(env.clientId, env.connector.broker.openedClientId)
        assertTrue(states.isNotEmpty())
        assertTrue(states.all { it == DeviceBrokerContract.STATE_READY })
        assertTrue(env.client.isConnected)
    }

    @Test
    fun invoke_successAndFailureMatchDirectBackendShape() {
        val env = Env()
        env.client.connect()
        env.connector.broker.nextResult = { requestId, method, arguments ->
            assertEquals("fetchDeviceVersion", method)
            assertEquals(mapOf("profile" to 1), arguments)
            BrokerInvokeResult(
                requestId = requestId,
                statusCode = 0,
                errorCode = null,
                message = null,
                payload = mapOf("project" to "M6"),
            )
        }

        val backend = AidlGmacroBackend(env.client)
        val success = capture { backend.invoke("fetchDeviceVersion", mapOf("profile" to 1), it) }
        assertEquals(GmacroResult.Success(mapOf("project" to "M6")), success)

        env.connector.broker.nextResult = { requestId, _, _ ->
            BrokerInvokeResult(
                requestId = requestId,
                statusCode = 7,
                errorCode = null,
                message = null,
                payload = mapOf("code" to 7),
            )
        }
        val failed = capture { backend.invoke("fetchDeviceVersion", emptyMap(), it) }
        val error = assertIs<GmacroResult.Error>(failed)
        assertEquals(GmacroResult.FAILED_CODE, error.code)
        assertEquals("GMacro method failed with code=7", error.message)
    }

    @Test
    fun binderDeath_failsPendingRequestReconnectsAndDropsLateCallback() {
        val env = Env()
        env.client.connect()

        val delivered = mutableListOf<GmacroResult>()
        env.connector.broker.holdCallbacks = true
        env.client.invoke("fetchCurrentProfile", emptyMap()) { delivered.add(it) }
        val staleCallback = env.connector.broker.heldCallback
        val staleRequestId = env.connector.broker.lastRequestId

        env.connector.broker.fireDeath()
        assertFalse(env.client.isConnected)
        val disconnected = assertIs<GmacroResult.Error>(delivered.single())
        assertEquals(DeviceBrokerContract.ERROR_DISCONNECTED, disconnected.code)

        staleCallback?.invoke(
            BrokerInvokeResult(
                requestId = staleRequestId,
                statusCode = 0,
                errorCode = null,
                message = null,
                payload = mapOf("profile" to 9),
            ),
        )
        assertEquals(1, delivered.size)

        env.scheduler.runDelayed()
        assertTrue(env.client.isConnected)
        assertEquals(2, env.connector.bindCount)

        env.connector.broker.holdCallbacks = false
        env.connector.broker.nextResult = { requestId, _, _ ->
            BrokerInvokeResult(requestId, 0, null, null, mapOf("profile" to 3))
        }
        val success = capture { env.client.invoke("fetchCurrentProfile", emptyMap(), it) }
        assertEquals(GmacroResult.Success(mapOf("profile" to 3)), success)
    }

    @Test
    fun bindFailure_usesExponentialBackoffThenRecovers() {
        val env = Env()
        env.connector.bindSucceeds = false
        val states = mutableListOf<String>()
        env.client.events = RecordingSink(onState = { state, _ -> states.add(state) })

        env.client.connect()
        assertEquals(
            listOf(
                DeviceBrokerContract.STATE_DISCONNECTED,
                DeviceBrokerContract.STATE_RECOVERING,
            ),
            states,
        )
        assertEquals(listOf(1_000L), env.scheduler.delayHistory)

        env.scheduler.runDelayed()
        assertEquals(listOf(1_000L, 2_000L), env.scheduler.delayHistory)

        env.connector.bindSucceeds = true
        env.scheduler.runDelayed()
        assertTrue(env.client.isConnected)
        assertTrue(states.contains(DeviceBrokerContract.STATE_READY))
    }

    @Test
    fun close_unbindsAndDoesNotReconnect() {
        val env = Env()
        env.client.connect()
        env.connector.broker.holdCallbacks = true
        var result: GmacroResult? = null
        env.client.invoke("fetchCurrentProfile", emptyMap()) { result = it }
        env.client.close()

        assertTrue(env.connector.unbound)
        assertTrue(env.client.closed)
        val disconnected = assertIs<GmacroResult.Error>(result)
        assertEquals(DeviceBrokerContract.ERROR_DISCONNECTED, disconnected.code)
        env.connector.broker.fireDeath()
        env.scheduler.runDelayed()
        assertEquals(1, env.connector.bindCount)
    }

    @Test
    fun startOta_closesParcelFileDescriptor() {
        val env = Env()
        env.client.connect()
        env.connector.broker.nextResult = { requestId, _, _ ->
            BrokerInvokeResult(requestId, 0, null, null, emptyMap())
        }

        val firmware = byteArrayOf(1, 2, 3)
        capture { env.client.startOta(firmware, it) }

        assertTrue(env.firmware.closed)
        assertTrue(env.firmware.lastBytes.contentEquals(firmware))
        assertEquals(3L, env.connector.broker.lastByteCount)
    }

    @Test
    fun startOta_firmwareOpenFailureCompletesRequest() {
        val env = Env()
        env.client.connect()
        env.firmware.openFailure = IllegalStateException("cache unavailable")

        val result = capture { env.client.startOta(byteArrayOf(1, 2, 3), it) }

        val error = assertIs<GmacroResult.Error>(result)
        assertEquals(GmacroResult.INVOCATION_ERROR, error.code)
        assertEquals("cache unavailable", error.message)
    }

    @Test
    fun events_areForwardedUntilGenerationChanges() {
        val env = Env()
        val protocol = mutableListOf<Map<String, Any?>>()
        val realtime = mutableListOf<Map<String, Any?>>()
        val ota = mutableListOf<Map<String, Any?>>()
        env.client.events = RecordingSink(
            onProtocol = { protocol.add(it) },
            onRealtime = { realtime.add(it) },
            onOta = { ota.add(it) },
        )
        env.client.connect()

        env.connector.broker.listener?.onProtocolEvent(mapOf("type" to "ready"))
        env.connector.broker.listener?.onRealtimeEvent(mapOf("type" to "dpKeyEvent", "keyValue" to 1))
        env.connector.broker.listener?.onOtaEvent(mapOf("type" to "progress", "percent" to 0.5))

        assertEquals("ready", protocol.single()["type"])
        assertEquals(1, realtime.single()["keyValue"])
        assertEquals(0.5, ota.single()["percent"])

        val staleListener = env.connector.broker.listener
        env.connector.broker.fireDeath()
        staleListener?.onRealtimeEvent(mapOf("type" to "dpKeyEvent", "keyValue" to 99))
        assertEquals(1, realtime.size)
    }

    @Test
    fun invokeWhileDisconnected_returnsBrokerError() {
        val env = Env()
        val result = capture { env.client.invoke("fetchDeviceVersion", emptyMap(), it) }
        val error = assertIs<GmacroResult.Error>(result)
        assertEquals(DeviceBrokerContract.ERROR_DISCONNECTED, error.code)
    }

    @Test
    fun brokerLifecycleStatesMapToStableTransportEvents() {
        assertEquals(
            "connecting",
            BrokerTransportMapper.toTransportEvent(
                DeviceBrokerContract.STATE_CREATED,
                emptyMap(),
            )["type"],
        )
        assertEquals(
            "disconnected",
            BrokerTransportMapper.toTransportEvent(
                DeviceBrokerContract.STATE_STOPPED,
                emptyMap(),
            )["type"],
        )
    }

    private fun capture(block: ((GmacroResult) -> Unit) -> Unit): GmacroResult {
        var captured: GmacroResult? = null
        block { captured = it }
        return requireNotNull(captured)
    }

    private class Env {
        val clientId = "client-1"
        val firmware = FakeOtaFirmwareSource()
        val scheduler = FakeScheduler()
        val connector = FakeDeviceBrokerConnector()
        val client = DeviceBrokerClient(
            connector = connector,
            scheduler = scheduler,
            firmwareSource = firmware,
            clientId = clientId,
            initialBackoffMs = 1_000L,
            maxBackoffMs = 30_000L,
        )
    }
}

private class FakeScheduler : BrokerScheduler {
    val delayed = mutableListOf<DelayedTask>()
    val delayHistory = mutableListOf<Long>()
    val delays: List<Long>
        get() = delayed.map { it.delayMs }

    override fun post(block: () -> Unit) {
        block()
    }

    override fun postDelayed(delayMs: Long, token: Any, block: () -> Unit) {
        delayHistory.add(delayMs)
        delayed.removeAll { it.token == token }
        delayed.add(DelayedTask(delayMs, token, block))
    }

    override fun cancel(token: Any) {
        delayed.removeAll { it.token == token }
    }

    override fun cancelAll() {
        delayed.clear()
    }

    fun runDelayed() {
        val tasks = delayed.toList()
        delayed.clear()
        tasks.forEach { it.block() }
    }
}

private data class DelayedTask(
    val delayMs: Long,
    val token: Any,
    val block: () -> Unit,
)

private class FakeDeviceBrokerConnector(
    var bindSucceeds: Boolean = true,
) : DeviceBrokerConnector {
    var bindCount = 0
    var unbound = false
    var callbacks: DeviceBrokerBindCallbacks? = null
    val broker = FakeRemoteBrokerHandle()

    override fun bind(callbacks: DeviceBrokerBindCallbacks): Boolean {
        bindCount += 1
        unbound = false
        this.callbacks = callbacks
        if (!bindSucceeds) {
            return false
        }
        callbacks.onConnected(broker)
        return true
    }

    override fun unbind() {
        unbound = true
    }
}

private class FakeRemoteBrokerHandle : RemoteBrokerHandle {
    var listener: DeviceBrokerEventSink? = null
    var openedClientId: String? = null
    var lastRequestId: Long = 0
    var lastByteCount: Long = 0
    var holdCallbacks = false
    var heldCallback: ((BrokerInvokeResult) -> Unit)? = null
    var nextResult: ((Long, String, Map<String, Any?>) -> BrokerInvokeResult)? = null
    var death: (() -> Unit)? = null
    var currentState: Map<String, Any?> = mapOf("state" to DeviceBrokerContract.STATE_READY)

    override fun getState(): Map<String, Any?> = currentState

    override fun openSession(clientId: String, listener: DeviceBrokerEventSink) {
        openedClientId = clientId
        this.listener = listener
        listener.onStateChanged(DeviceBrokerContract.STATE_READY, currentState)
    }

    override fun closeSession(clientId: String) {
        if (openedClientId == clientId) {
            listener = null
        }
    }

    override fun invoke(
        requestId: Long,
        method: String,
        arguments: Map<String, Any?>,
        callback: (BrokerInvokeResult) -> Unit,
    ) {
        lastRequestId = requestId
        if (holdCallbacks) {
            heldCallback = callback
            return
        }
        callback(nextResult?.invoke(requestId, method, arguments) ?: BrokerInvokeResult(requestId, 0, null, null, emptyMap()))
    }

    override fun startOta(
        requestId: Long,
        firmware: CloseableParcelFile,
        byteCount: Long,
        callback: (BrokerInvokeResult) -> Unit,
    ) {
        lastRequestId = requestId
        lastByteCount = byteCount
        callback(nextResult?.invoke(requestId, "startOta", emptyMap()) ?: BrokerInvokeResult(requestId, 0, null, null, emptyMap()))
    }

    override fun cancelOta(requestId: Long) {
        lastRequestId = requestId
    }

    override fun linkToDeath(onDied: () -> Unit) {
        death = onDied
    }

    override fun unlinkToDeath() {
        death = null
    }

    fun fireDeath() {
        death?.invoke()
    }
}

private class FakeOtaFirmwareSource : OtaFirmwareSource {
    var closed = false
    var lastBytes: ByteArray = byteArrayOf()
    var openFailure: RuntimeException? = null

    override fun open(bytes: ByteArray): CloseableParcelFile {
        openFailure?.let { throw it }
        lastBytes = bytes
        closed = false
        return CloseableParcelFile { closed = true }
    }
}

private class RecordingSink(
    private val onState: (String, Map<String, Any?>) -> Unit = { _, _ -> },
    private val onProtocol: (Map<String, Any?>) -> Unit = {},
    private val onRealtime: (Map<String, Any?>) -> Unit = {},
    private val onOta: (Map<String, Any?>) -> Unit = {},
) : DeviceBrokerEventSink {
    override fun onStateChanged(state: String, extras: Map<String, Any?>) = onState(state, extras)
    override fun onProtocolEvent(event: Map<String, Any?>) = onProtocol(event)
    override fun onRealtimeEvent(event: Map<String, Any?>) = onRealtime(event)
    override fun onOtaEvent(event: Map<String, Any?>) = onOta(event)
}
