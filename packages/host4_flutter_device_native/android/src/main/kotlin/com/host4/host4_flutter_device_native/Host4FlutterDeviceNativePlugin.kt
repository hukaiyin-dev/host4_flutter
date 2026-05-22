package com.host4.host4_flutter_device_native

import android.content.Context
import com.host4.platform.listener.BluetoothStateListener
import com.host4.platform.listener.MessageCallBack
import com.host4.platform.util.Constants
import com.host4.platform.v2.api.FullPlatformSdk
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

    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var pendingPermissionResult: Result? = null

    private val transportSessions = ConcurrentHashMap<String, TransportSessionRecord>()
    private val protocolSessions = ConcurrentHashMap<String, ProtocolSessionRecord>()

    private val platformSdk: FullPlatformSdk
        get() = FullPlatformSdk.getInstance()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext
        binaryMessenger = flutterPluginBinding.binaryMessenger
        bleScanHandler = BleScanStreamHandler(applicationContext)

        methodChannel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "host4_flutter_device_native",
        )
        methodChannel.setMethodCallHandler(this)

        EventChannel(
            flutterPluginBinding.binaryMessenger,
            "host4_flutter_device_native/ble_scan",
        ).setStreamHandler(bleScanHandler)
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
            "connectBle" -> handleConnectBle(call, result)
            "disconnectTransport" -> handleDisconnectTransport(call, result)
            "attachGmacroProtocol" -> handleAttachGmacroProtocol(call, result)
            "invokeGmacroMethod" -> handleInvokeGmacroMethod(call, result)
            "closeProtocol" -> handleCloseProtocol(call, result)
            "queryDeviceInfo" -> handleQueryDeviceInfo(call, result)
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
            mac = mac,
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
        platformSdk.disconnectBle(record.mac)
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
            mac = transportRecord.mac,
            eventChannel = eventChannel,
            eventHandler = eventHandler,
        )

        platformSdk.setActiveBleDevice(transportRecord.mac)

        if (transportRecord.lastTransportStatus == Constants.COMPLETE_CONNECT) {
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
            mac = protocolRecord.mac,
            method = method,
            arguments = invokeArguments,
            result = result,
        )
    }

    private fun handleQueryDeviceInfo(call: MethodCall, result: Result) {
        val arguments = call.arguments as? Map<*, *>
        val deviceMac = arguments?.get("deviceMac") as? String
        if (deviceMac.isNullOrEmpty()) {
            result.error("invalid-arguments", "deviceMac is required.", null)
            return
        }

        KrDeviceInfoQuery.query(deviceMac, result)
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
        val mac: String,
        val eventChannel: EventChannel,
        val eventHandler: QueuedEventStreamHandler,
        @Volatile var lastTransportStatus: Int = Constants.CONNECTING,
    )

    private data class ProtocolSessionRecord(
        val protocolSessionId: String,
        val transportSessionId: String,
        val mac: String,
        val eventChannel: EventChannel,
        val eventHandler: QueuedEventStreamHandler,
    )
}
