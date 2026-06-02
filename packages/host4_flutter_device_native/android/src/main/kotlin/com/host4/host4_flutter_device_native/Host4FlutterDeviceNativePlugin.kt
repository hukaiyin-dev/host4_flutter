package com.host4.host4_flutter_device_native

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.host4.platform.listener.BluetoothStateListener
import com.host4.platform.listener.MessageCallBack
import com.host4.platform.listener.OnEscalationListener
import com.host4.platform.util.Constants
import com.host4.platform.listener.UsbConnectListener
import com.host4.platform.kr.response.DPKeyEventRsp
import com.host4.platform.kr.response.EscalationRsp
import com.host4.platform.manager.ReliableUsbCommManager
import com.host4.platform.v2.api.FullPlatformSdk
import com.host4.platform.v2.api.UsbDeviceSessionHandle
import com.host4.platform.v2.ble.BleMacUtils
import com.host4.platform.v2.ble.RxBleCommManager
import android.app.Activity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.Collections.emptyMap
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

/** Host4FlutterDeviceNativePlugin */
class Host4FlutterDeviceNativePlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware,
    PluginRegistry.RequestPermissionsResultListener {
    private lateinit var methodChannel: MethodChannel
    private lateinit var binaryMessenger: BinaryMessenger
    private lateinit var applicationContext: Context
    private lateinit var bleScanHandler: BleScanStreamHandler
    private lateinit var usbScanHandler: UsbScanStreamHandler

    private val mainHandler = Handler(Looper.getMainLooper())

    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var pendingPermissionResult: Result? = null

    @Volatile
    private var usbHostInitialized = false

    @Volatile
    private var activeUsbTransport: TransportSessionRecord? = null

    private val transportSessions = ConcurrentHashMap<String, TransportSessionRecord>()
    private val protocolSessions = ConcurrentHashMap<String, ProtocolSessionRecord>()

    private val platformSdk: FullPlatformSdk
        get() = FullPlatformSdk.getInstance()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext
        binaryMessenger = flutterPluginBinding.binaryMessenger
        bleScanHandler = BleScanStreamHandler(applicationContext)
        usbScanHandler = UsbScanStreamHandler(applicationContext)

        methodChannel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "host4_flutter_device_native",
        )
        methodChannel.setMethodCallHandler(this)

        EventChannel(
            flutterPluginBinding.binaryMessenger,
            "host4_flutter_device_native/ble_scan",
        ).setStreamHandler(bleScanHandler)

        EventChannel(
            flutterPluginBinding.binaryMessenger,
            "host4_flutter_device_native/usb_scan",
        ).setStreamHandler(usbScanHandler)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "stopBleScan" -> {
                bleScanHandler.stopScan()
                result.success(null)
            }
            "stopUsbScan" -> {
                usbScanHandler.stopScan()
                result.success(null)
            }
            "connectBle" -> handleConnectBle(call, result)
            "connectUsb" -> handleConnectUsb(call, result)
            "reconnectUsb" -> handleReconnectUsb(result)
            "releaseUsb" -> handleReleaseUsb(result)
            "disconnectTransport" -> handleDisconnectTransport(call, result)
            "attachGmacroProtocol" -> handleAttachGmacroProtocol(call, result)
            "invokeGmacroMethod" -> handleInvokeGmacroMethod(call, result)
            "closeProtocol" -> handleCloseProtocol(call, result)
            "ensureBleScanPermissions" -> handleEnsureBleScanPermissions(result)
            else -> result.notImplemented()
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
        activity = null
        pendingPermissionResult?.error(
            "ble-permission-cancelled",
            "Activity detached while waiting for BLE permissions.",
            null,
        )
        pendingPermissionResult = null
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != BlePermissionHelper.REQUEST_BLE_PERMISSIONS) {
            return false
        }

        val pending = pendingPermissionResult ?: return true
        pendingPermissionResult = null

        val granted = grantResults.isNotEmpty() &&
            grantResults.all { it == android.content.pm.PackageManager.PERMISSION_GRANTED }

        if (granted) {
            pending.success(true)
        } else {
            pending.success(false)
        }
        return true
    }

    private fun handleEnsureBleScanPermissions(result: Result) {
        val currentActivity = activity
        if (currentActivity == null) {
            result.error(
                "no-activity",
                "Cannot request BLE permissions without a foreground Activity.",
                null,
            )
            return
        }

        if (BlePermissionHelper.hasAllPermissions(currentActivity)) {
            result.success(true)
            return
        }

        if (pendingPermissionResult != null) {
            result.error(
                "ble-permission-in-progress",
                "Another BLE permission request is already in progress.",
                null,
            )
            return
        }

        pendingPermissionResult = result
        BlePermissionHelper.requestMissingPermissions(currentActivity)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        bleScanHandler.stopScan()
        usbScanHandler.stopScan()
        handleReleaseUsbInternal()
        protocolSessions.clear()
        transportSessions.values.forEach { it.eventChannel.setStreamHandler(null) }
        transportSessions.clear()
        platformSdk.disconnectAllBle()
    }

    private fun handleConnectBle(call: MethodCall, result: Result) {
        val arguments = call.arguments as? Map<*, *>
        val deviceId = arguments?.get("deviceId") as? String
        if (deviceId.isNullOrEmpty()) {
            result.error("invalid-arguments", "deviceId is required.", null)
            return
        }

        val mac = BleMacUtils.normalizeMac(deviceId)
        val sessionId = UUID.randomUUID().toString()
        val eventHandler = QueuedEventStreamHandler()
        val eventChannel = EventChannel(
            binaryMessenger,
            "host4_flutter_device_native/transport_events/$sessionId",
        )
        eventChannel.setStreamHandler(eventHandler)

        val record = TransportSessionRecord(
            sessionId = sessionId,
            transportKind = Host4FlutterTransportKinds.BLE,
            deviceKey = mac,
            eventChannel = eventChannel,
            eventHandler = eventHandler,
        )
        transportSessions[sessionId] = record

        val stateListener = BluetoothStateListener { _, status ->
            record.lastTransportStatus = status
            eventHandler.emit(TransportEventMapper.mapTransportEvent(status))
            if (status == Constants.COMPLETE_CONNECT) {
                emitProtocolReadyForTransport(sessionId)
            }
        }

        platformSdk.connectBle(
            applicationContext,
            mac,
            stateListener,
            MessageCallBack {
                // msgBleService + notify ready are driven by the SDK after GATT is up.
            },
        )

        result.success(sessionId)
    }

    private fun handleConnectUsb(call: MethodCall, result: Result) {
        val arguments = call.arguments as? Map<*, *>
        val deviceId = arguments?.get("deviceId") as? String

        val sessionId = UUID.randomUUID().toString()
        val eventHandler = QueuedEventStreamHandler()
        val eventChannel = EventChannel(
            binaryMessenger,
            "host4_flutter_device_native/transport_events/$sessionId",
        )
        eventChannel.setStreamHandler(eventHandler)

        val dpKeyEventHandler = QueuedEventStreamHandler()
        val dpKeyEventChannel = EventChannel(
            binaryMessenger,
            "host4_flutter_device_native/usb_dp_key_events/$sessionId",
        )
        dpKeyEventChannel.setStreamHandler(dpKeyEventHandler)

        val usbHandle: UsbDeviceSessionHandle = platformSdk.usb()
        val record = TransportSessionRecord(
            sessionId = sessionId,
            transportKind = Host4FlutterTransportKinds.USB,
            deviceKey = usbHandle.deviceId,
            eventChannel = eventChannel,
            eventHandler = eventHandler,
            dpKeyEventChannel = dpKeyEventChannel,
            dpKeyEventHandler = dpKeyEventHandler,
        )
        transportSessions[sessionId] = record
        activeUsbTransport = record

        // Return sessionId first so Flutter can subscribe to transport_events
        // before SDK init() runs (init triggers permission UI + connect).
        result.success(sessionId)

        mainHandler.post {
            startUsbHostConnection(usbHandle, deviceId, record)
        }
    }

    private fun startUsbHostConnection(
        usbHandle: UsbDeviceSessionHandle,
        deviceId: String?,
        record: TransportSessionRecord,
    ) {
        val wasInitialized = usbHostInitialized
        ensureUsbHostInitialized(usbHandle, deviceId)

        val usbManager = ReliableUsbCommManager.getInstance()
        when {
            usbManager.isConnected -> {
                record.lastTransportStatus = ReliableUsbCommManager.CONNECT_COMPLETED
                record.eventHandler.emit(mapOf("type" to "ready"))
            }
            !wasInitialized -> {
                // init() already calls searchAndConnectAsync(); do not duplicate.
                record.eventHandler.emit(mapOf("type" to "connecting"))
                scheduleUsbPermissionWatchdog(record)
            }
            else -> {
                record.eventHandler.emit(mapOf("type" to "connecting"))
                usbManager.searchAndConnectAsync()
            }
        }
    }

    /**
     * Manual reconnect after a failed attempt. Clears stale USB handles (same as
     * unplug/replug) then searches again — required when the device was already
     * plugged before [UsbDeviceSessionHandle.init].
     */
    private fun recoverUsbHostConnection(
        usbHandle: UsbDeviceSessionHandle,
        deviceId: String?,
        record: TransportSessionRecord,
    ) {
        ensureUsbHostInitialized(usbHandle, deviceId)
        val usbManager = ReliableUsbCommManager.getInstance()
        if (usbManager.isConnected) {
            record.lastTransportStatus = ReliableUsbCommManager.CONNECT_COMPLETED
            record.eventHandler.emit(mapOf("type" to "ready"))
            return
        }
        record.usbRecoverScheduled = false
        runCatching { usbManager.close() }
        record.eventHandler.emit(mapOf("type" to "connecting"))
        usbManager.searchAndConnectAsync()
    }

    private fun scheduleUsbPermissionWatchdog(record: TransportSessionRecord) {
        mainHandler.postDelayed({
            if (activeUsbTransport !== record) return@postDelayed
            val usbManager = ReliableUsbCommManager.getInstance()
            if (usbManager.isConnected) return@postDelayed
            usbManager.searchAndConnectAsync()
        }, USB_PERMISSION_WATCHDOG_MS)
    }

    private fun scheduleUsbRecoverAfterFailure(record: TransportSessionRecord) {
        if (record.usbRecoverScheduled) return
        record.usbRecoverScheduled = true
        mainHandler.postDelayed({
            if (activeUsbTransport !== record) return@postDelayed
            val usbManager = ReliableUsbCommManager.getInstance()
            if (usbManager.isConnected) return@postDelayed
            runCatching { usbManager.close() }
            record.eventHandler.emit(mapOf("type" to "connecting"))
            usbManager.searchAndConnectAsync()
        }, USB_RECOVER_AFTER_FAIL_MS)
    }

    private fun handleReconnectUsb(result: Result) {
        val record = activeUsbTransport
        if (record == null) {
            result.error(
                "usb-session-missing",
                "No active USB transport session. Open the USB connect page first.",
                null,
            )
            return
        }

        val usbHandle = platformSdk.usb()
        mainHandler.post {
            recoverUsbHostConnection(usbHandle, null, record)
        }
        result.success(null)
    }

    private fun handleReleaseUsb(result: Result) {
        handleReleaseUsbInternal()
        result.success(null)
    }

    private fun handleReleaseUsbInternal() {
        val usbSessionIds = transportSessions.filterValues {
            it.transportKind == Host4FlutterTransportKinds.USB
        }.keys.toList()

        for (sessionId in usbSessionIds) {
            transportSessions.remove(sessionId)?.let { record ->
                record.eventChannel.setStreamHandler(null)
                record.dpKeyEventChannel?.setStreamHandler(null)
            }
            removeProtocolSessionsForTransport(sessionId)
        }

        activeUsbTransport = null
        if (usbHostInitialized) {
            runCatching { platformSdk.usb().disconnect() }
            usbHostInitialized = false
        }
    }

    /**
     * Delegates permission, attach/detach broadcasts, and connect retries to
     * [ReliableUsbCommManager] inside bluetooth_communication JAR.
     */
    private fun ensureUsbHostInitialized(usbHandle: UsbDeviceSessionHandle, deviceId: String?) {
        usbHandle.setUsbConnectListener(usbConnectListener)
        usbHandle.registerAllEscalationListener(usbAllEscalationListener)
        if (usbHostInitialized) {
            return
        }

        val vidPid = deviceId?.let { UsbDeviceIds.parse(it) }
        if (vidPid != null) {
            usbHandle.init(applicationContext, vidPid.second, vidPid.first)
        } else {
            usbHandle.init(applicationContext)
        }
        usbHostInitialized = true
    }

    private val usbAllEscalationListener = OnEscalationListener<EscalationRsp> { message ->
        if (message !is DPKeyEventRsp) return@OnEscalationListener
        val modeEvent = message.modeEvent ?: return@OnEscalationListener
        val record = activeUsbTransport ?: return@OnEscalationListener
        record.dpKeyEventHandler?.emit(DpKeyEventMapper.map(modeEvent))
    }

    private val usbConnectListener = UsbConnectListener { status ->
        val record = activeUsbTransport ?: return@UsbConnectListener
        record.lastTransportStatus = status
        when (status) {
            ReliableUsbCommManager.CONNECT_COMPLETED -> {
                record.usbRecoverScheduled = false
            }
            ReliableUsbCommManager.CONNECT_FAIL -> {
                scheduleUsbRecoverAfterFailure(record)
            }
        }
        record.eventHandler.emit(UsbTransportEventMapper.mapTransportEvent(status))
        if (status == ReliableUsbCommManager.CONNECT_COMPLETED) {
            emitProtocolReadyForTransport(record.sessionId)
        }
    }

    private fun handleDisconnectTransport(call: MethodCall, result: Result) {
        val arguments = call.arguments as? Map<*, *>
        val transportSessionId = arguments?.get("transportSessionId") as? String
        val record = transportSessionId?.let { transportSessions.remove(it) }
        if (record == null) {
            result.error(
                "transport-session-not-found",
                "No transport session exists for the provided transportSessionId.",
                null,
            )
            return
        }

        record.eventChannel.setStreamHandler(null)
        record.dpKeyEventChannel?.setStreamHandler(null)
        when (record.transportKind) {
            Host4FlutterTransportKinds.USB -> {
                if (activeUsbTransport?.sessionId == transportSessionId) {
                    activeUsbTransport = null
                }
            }
            else -> platformSdk.disconnectBle(record.deviceKey)
        }
        removeProtocolSessionsForTransport(transportSessionId)
        result.success(null)
    }

    private fun handleAttachGmacroProtocol(call: MethodCall, result: Result) {
        val arguments = call.arguments as? Map<*, *>
        val transportSessionId = arguments?.get("transportSessionId") as? String
        val transportRecord = transportSessionId?.let { transportSessions[it] }
        if (transportRecord == null) {
            result.error(
                "transport-session-not-found",
                "No transport session exists for the provided transportSessionId.",
                null,
            )
            return
        }

        val protocolSessionId = UUID.randomUUID().toString()
        val eventHandler = QueuedEventStreamHandler()
        val eventChannel = EventChannel(
            binaryMessenger,
            "host4_flutter_device_native/protocol_events/$protocolSessionId",
        )
        eventChannel.setStreamHandler(eventHandler)

        protocolSessions[protocolSessionId] = ProtocolSessionRecord(
            protocolSessionId = protocolSessionId,
            transportSessionId = transportSessionId,
            deviceKey = transportRecord.deviceKey,
            transportKind = transportRecord.transportKind,
            eventChannel = eventChannel,
            eventHandler = eventHandler,
        )

        if (transportRecord.transportKind == Host4FlutterTransportKinds.BLE) {
            platformSdk.setActiveBleDevice(transportRecord.deviceKey)
        }

        val isTransportReady = when (transportRecord.transportKind) {
            Host4FlutterTransportKinds.USB ->
                transportRecord.lastTransportStatus == ReliableUsbCommManager.CONNECT_COMPLETED
            else ->
                transportRecord.lastTransportStatus == Constants.COMPLETE_CONNECT
        }
        if (isTransportReady) {
            eventHandler.emit(mapOf("type" to "ready"))
        }

        result.success(protocolSessionId)
    }

    private fun handleInvokeGmacroMethod(call: MethodCall, result: Result) {
        val payload = call.arguments as? Map<*, *>
        val protocolSessionId = payload?.get("protocolSessionId") as? String
        val method = payload?.get("method") as? String
        val protocolRecord = protocolSessionId?.let { protocolSessions[it] }

        if (protocolRecord == null || method.isNullOrEmpty()) {
            result.error(
                "invalid-arguments",
                "protocolSessionId and method are required.",
                null,
            )
            return
        }

        @Suppress("UNCHECKED_CAST")
        val invokeArguments = (payload["arguments"] as? Map<String, Any?>) ?: emptyMap()

        GmacroMethodInvoker.invoke(
            deviceKey = protocolRecord.deviceKey,
            transportKind = protocolRecord.transportKind,
            method = method,
            arguments = invokeArguments,
            result = result,
        )
    }

    private fun handleCloseProtocol(call: MethodCall, result: Result) {
        val arguments = call.arguments as? Map<*, *>
        val protocolSessionId = arguments?.get("protocolSessionId") as? String
        val record = protocolSessionId?.let { protocolSessions.remove(it) }
        if (record == null) {
            result.error(
                "protocol-session-not-found",
                "No protocol session exists for the provided protocolSessionId.",
                null,
            )
            return
        }

        record.eventChannel.setStreamHandler(null)
        result.success(null)
    }

    private fun emitProtocolReadyForTransport(transportSessionId: String) {
        protocolSessions.values
            .filter { it.transportSessionId == transportSessionId }
            .forEach { it.eventHandler.emit(mapOf("type" to "ready")) }
    }

    private fun removeProtocolSessionsForTransport(transportSessionId: String) {
        val toRemove = protocolSessions.filterValues { it.transportSessionId == transportSessionId }
        toRemove.keys.forEach { key ->
            protocolSessions.remove(key)?.eventChannel?.setStreamHandler(null)
        }
    }

    private data class TransportSessionRecord(
        val sessionId: String,
        val transportKind: String,
        val deviceKey: String,
        val eventChannel: EventChannel,
        val eventHandler: QueuedEventStreamHandler,
        val dpKeyEventChannel: EventChannel? = null,
        val dpKeyEventHandler: QueuedEventStreamHandler? = null,
        @Volatile var lastTransportStatus: Int = Constants.CONNECTING,
        @Volatile var usbRecoverScheduled: Boolean = false,
    )

    private companion object {
        /** Retry search if permission was granted but the first open did not complete. */
        const val USB_PERMISSION_WATCHDOG_MS = 1500L

        /** Delay before auto-recovering from CONNECT_FAIL (mirrors replug). */
        const val USB_RECOVER_AFTER_FAIL_MS = 400L
    }

    private data class ProtocolSessionRecord(
        val protocolSessionId: String,
        val transportSessionId: String,
        val deviceKey: String,
        val transportKind: String,
        val eventChannel: EventChannel,
        val eventHandler: QueuedEventStreamHandler,
    )
}
