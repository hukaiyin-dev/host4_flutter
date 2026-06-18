package com.host4.host4_flutter_device_native

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.host4.platform.listener.BluetoothStateListener
import com.host4.platform.listener.MessageCallBack
import com.host4.platform.listener.OnEscalationListener
import com.host4.platform.listener.UpgradeCallBack
import com.host4.platform.util.Constants
import com.host4.platform.listener.UsbConnectListener
import com.host4.platform.kr.response.EscalationRsp
import com.host4.platform.manager.ReliableUsbCommManager
import com.host4.platform.v2.api.FullPlatformSdk
import com.host4.platform.v2.api.UsbDeviceSessionHandle
import com.host4.platform.v2.ble.BleMacUtils
import com.host4.platform.v2.ble.RxBleCommManager
import android.app.Activity
import com.host4.platform.v2.api.PlatformSdkFactory
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
import java.util.Collections.emptyList
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

    /** USB 连接辅助类，管理 SDK 初始化与释放 */
    private lateinit var usbConnection: UsbConnectionHelper

    @Volatile
    private var activeUsbTransport: TransportSessionRecord? = null

    private val transportSessions = ConcurrentHashMap<String, TransportSessionRecord>()

    private fun escalationEventChannelName(sessionId: String): String =
        "host4_flutter_device_native/transport_escalation_events/$sessionId"
    private fun otaEventChannelName(protocolSessionId: String): String =
        "host4_flutter_device_native/ota_events/$protocolSessionId"
    private val protocolSessions = ConcurrentHashMap<String, ProtocolSessionRecord>()

    private val platformSdk: FullPlatformSdk
        get() = FullPlatformSdk.getInstance()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext
        binaryMessenger = flutterPluginBinding.binaryMessenger
        bleScanHandler = BleScanStreamHandler(applicationContext)
        usbScanHandler = UsbScanStreamHandler(applicationContext)
        usbConnection = UsbConnectionHelper(applicationContext)

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
            "connectSystemConnectedBle" -> handleConnectSystemConnectedBle(call, result)
            "connectUsb" -> handleConnectUsb(call, result)
            "reconnectUsb" -> handleReconnectUsb(result)
            "releaseUsb" -> handleReleaseUsb(result)
            "disconnectTransport" -> handleDisconnectTransport(call, result)
            "attachGmacroProtocol" -> handleAttachGmacroProtocol(call, result)
            "invokeGmacroMethod" -> handleInvokeGmacroMethod(call, result)
            "closeProtocol" -> handleCloseProtocol(call, result)
            "startOta" -> handleStartOta(call, result)
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

        startBleTransportSession(BleMacUtils.normalizeMac(deviceId), result)
    }

    private fun handleConnectSystemConnectedBle(call: MethodCall, result: Result) {
        val arguments = call.arguments as? Map<*, *>
        val serviceIds = (arguments?.get("serviceIds") as? List<*>)?.mapNotNull { it as? String }
            ?: emptyList()
        val deviceNames = (arguments?.get("deviceNames") as? List<*>)?.mapNotNull { it as? String }
            ?: emptyList()

        if (serviceIds.isEmpty()) {
            result.error("invalid-arguments", "serviceIds is required.", null)
            return
        }

        if (!BlePermissionHelper.hasAllPermissions(applicationContext)) {
            result.error(
                "ble-permission-denied",
                "System-connected BLE requires Bluetooth permissions on Android.",
                null,
            )
            return
        }

        val mac = SystemConnectedBleResolver.resolveMac(
            context = applicationContext,
            platformSdk = platformSdk,
            deviceNames = deviceNames,
        )
        if (mac.isNullOrEmpty()) {
            result.error(
                "ble-connect-failed",
                "No system-connected or bonded BLE device matched " +
                    "deviceNames=$deviceNames serviceIds=$serviceIds.",
                null,
            )
            return
        }

        startBleTransportSession(mac, result)
    }

    private fun startBleTransportSession(mac: String, result: Result) {
        val sessionId = UUID.randomUUID().toString()
        val eventHandler = QueuedEventStreamHandler()
        val eventChannel = EventChannel(
            binaryMessenger,
            "host4_flutter_device_native/transport_events/$sessionId",
        )
        eventChannel.setStreamHandler(eventHandler)

        val escalationEventHandler = QueuedEventStreamHandler()
        val escalationEventChannel = EventChannel(
            binaryMessenger,
            escalationEventChannelName(sessionId),
        )
        escalationEventChannel.setStreamHandler(escalationEventHandler)

        val record = TransportSessionRecord(
            sessionId = sessionId,
            transportKind = Host4FlutterTransportKinds.BLE,
            deviceKey = mac,
            eventChannel = eventChannel,
            eventHandler = eventHandler,
            escalationEventChannel = escalationEventChannel,
            escalationEventHandler = escalationEventHandler,
        )
        transportSessions[sessionId] = record

        registerBleAllEscalationListener(mac)

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

    /**
     * 建立 USB 传输会话。
     *
     * 流程：创建 EventChannel → 返回 sessionId → 主线程初始化 USB Host 并连接。
     * 支持通过 deviceId（"vid:pid"）或 options.pids / options.vids 指定目标设备。
     */
    private fun handleConnectUsb(call: MethodCall, result: Result) {
        val arguments = call.arguments as? Map<*, *>
        val deviceId = arguments?.get("deviceId") as? String
        val options = arguments?.get("options") as? Map<*, *>
        val filter = UsbDeviceIds.parseFilter(deviceId, options)

        val sessionId = UUID.randomUUID().toString()
        val eventHandler = QueuedEventStreamHandler()
        val eventChannel = EventChannel(
            binaryMessenger,
            "host4_flutter_device_native/transport_events/$sessionId",
        )
        eventChannel.setStreamHandler(eventHandler)

        val escalationEventHandler = QueuedEventStreamHandler()
        val escalationEventChannel = EventChannel(
            binaryMessenger,
            escalationEventChannelName(sessionId),
        )
        escalationEventChannel.setStreamHandler(escalationEventHandler)

        val usbHandle = platformSdk.usb()
        val record = TransportSessionRecord(
            sessionId = sessionId,
            transportKind = Host4FlutterTransportKinds.USB,
            deviceKey = usbHandle.deviceId,
            eventChannel = eventChannel,
            eventHandler = eventHandler,
            escalationEventChannel = escalationEventChannel,
            escalationEventHandler = escalationEventHandler,
        )
        transportSessions[sessionId] = record
        activeUsbTransport = record

        // 先返回 sessionId，确保 Flutter 能在 init 触发权限弹窗前订阅事件
        result.success(sessionId)

        mainHandler.post {
            startUsbConnection(usbHandle, filter, record)
        }
    }

    /** 启动 USB 连接：注册监听 → initUsbPidVid → 同步已连接状态 */
    private fun startUsbConnection(
        usbHandle: UsbDeviceSessionHandle,
        filter: UsbPidVidFilter,
        record: TransportSessionRecord,
    ) {
        usbConnection.registerListeners(usbHandle, usbConnectListener, usbAllEscalationListener)
        usbConnection.initUsbPidVid(usbHandle, filter)
        usbConnection.syncConnectedState {
            record.lastTransportStatus = ReliableUsbCommManager.CONNECT_COMPLETED
            record.eventHandler.emit(mapOf("type" to "ready"))
        }
    }

    /** 重新搜索并连接 USB 设备（拔出重插后使用） */
    private fun handleReconnectUsb(result: Result) {
        if (activeUsbTransport == null) {
            result.error(
                "usb-session-missing",
                "No active USB transport session. Open the USB connect page first.",
                null,
            )
            return
        }
        if (!usbConnection.initialized) {
            result.error(
                "usb-not-initialized",
                "Call connectUsb() first to initialize the USB host stack.",
                null,
            )
            return
        }

        mainHandler.post { usbConnection.reconnect() }
        result.success(null)
    }

    /** 释放 USB Host 资源并清理所有 USB 传输会话 */
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
                record.escalationEventChannel?.setStreamHandler(null)
            }
            removeProtocolSessionsForTransport(sessionId)
        }

        activeUsbTransport = null
        usbConnection.release(platformSdk.usb())
    }

    /**
     * Registers [OnEscalationListener] on the BLE session handle for [mac], mirroring USB
     * [UsbDeviceSessionHandle.registerAllEscalationListener].
     */
    private fun registerBleAllEscalationListener(mac: String) {
        platformSdk.registerAllEscalationListener(bleEscalationListenerFor(mac))
    }

    private fun bleEscalationListenerFor(mac: String): OnEscalationListener<EscalationRsp> {
        return OnEscalationListener { message ->
            val record = transportSessions.values.firstOrNull {
                it.transportKind == Host4FlutterTransportKinds.BLE && it.deviceKey == mac
            }
            EscalationEventEmitter.emit(record?.escalationEventHandler, message)
        }
    }

    private val usbAllEscalationListener = OnEscalationListener<EscalationRsp> { message ->
        EscalationEventEmitter.emit(activeUsbTransport?.escalationEventHandler, message)
    }

    /** USB 连接状态回调，将 SDK 状态映射为 Flutter 传输事件 */
    private val usbConnectListener = UsbConnectListener { status ->
        val record = activeUsbTransport ?: return@UsbConnectListener
        record.lastTransportStatus = status
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
        record.escalationEventChannel?.setStreamHandler(null)
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
        val otaEventHandler = QueuedEventStreamHandler()
        val otaEventChannel = EventChannel(
            binaryMessenger,
            otaEventChannelName(protocolSessionId),
        )
        otaEventChannel.setStreamHandler(otaEventHandler)

        protocolSessions[protocolSessionId] = ProtocolSessionRecord(
            protocolSessionId = protocolSessionId,
            transportSessionId = transportSessionId,
            deviceKey = transportRecord.deviceKey,
            transportKind = transportRecord.transportKind,
            eventChannel = eventChannel,
            eventHandler = eventHandler,
            otaEventChannel = otaEventChannel,
            otaEventHandler = otaEventHandler,
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
        record.otaEventChannel?.setStreamHandler(null)
        result.success(null)
    }

    /**
     * 启动 OTA 升级。
     *
     * 统一走 JAR v2 的 [FullPlatformSdk.otaUpgrade]：
     * - USB：使用当前激活传输直接升级
     * - BLE：先设置当前活跃设备，再按 MAC 发起升级
     */
    private fun handleStartOta(call: MethodCall, result: Result) {
        val arguments = call.arguments as? Map<*, *>
        val protocolSessionId = arguments?.get("protocolSessionId") as? String
        val firmwareData = arguments?.get("firmwareData") as? ByteArray
        val protocolRecord = protocolSessionId?.let { protocolSessions[it] }

        if (protocolRecord == null || firmwareData == null) {
            result.error(
                "invalid-arguments",
                "protocolSessionId and firmwareData are required.",
                null,
            )
            return
        }


        runCatching {
            registerOtaUpgradeListener(protocolRecord)
            when (protocolRecord.transportKind) {
                Host4FlutterTransportKinds.USB -> {
                    // USB 场景：由 v2 SDK 根据当前激活传输路由到 USB 通道。
                    platformSdk.otaUpgrade(firmwareData)
                }
                else -> {
                    // BLE 场景：显式指定 MAC，避免多设备时升级到错误设备。
                    platformSdk.setActiveBleDevice(protocolRecord.deviceKey)
                    platformSdk.otaUpgrade(protocolRecord.deviceKey, firmwareData)
                }
            }
        }.onSuccess {
            result.success(null)
        }.onFailure { error ->
            result.error(
                "ota-start-failed",
                error.message ?: "Failed to start OTA with v2 SDK.",
                null,
            )
        }
    }

    /**
     * 注册 OTA 升级回调。
     *
     * 通过 v2 [FullPlatformSdk.registerUpgradeListener] 统一监听升级进度、成功、失败，
     * 并转发到 Flutter `ota_events/{protocolSessionId}` 事件流。
     */
    private fun registerOtaUpgradeListener(protocolRecord: ProtocolSessionRecord) {
        val callback = object : UpgradeCallBack {
            override fun upgradeProgress(progress: Int, total: Int) {
                val percent = if (total > 0) {
                    (progress.toDouble() / total.toDouble()).coerceIn(0.0, 1.0)
                } else {
                    0.0
                }
                protocolRecord.otaEventHandler?.emit(
                    mapOf(
                        "type" to "progress",
                        "progress" to progress,
                        "total" to total,
                        "percent" to percent,
                    ),
                )
            }

            override fun upgradeFail(code: Int) {
                protocolRecord.otaEventHandler?.emit(
                    mapOf(
                        "type" to "failed",
                        "code" to code,
                    ),
                )
            }

            override fun upgradeSuccess() {
                protocolRecord.otaEventHandler?.emit(
                    mapOf(
                        "type" to "success",
                    ),
                )
            }
        }

        if (protocolRecord.transportKind == Host4FlutterTransportKinds.USB) {
            platformSdk.registerUpgradeListener(callback)
        } else {
            platformSdk.registerUpgradeListener(protocolRecord.deviceKey, callback)
        }
    }

    private fun emitProtocolReadyForTransport(transportSessionId: String) {
        protocolSessions.values
            .filter { it.transportSessionId == transportSessionId }
            .forEach { it.eventHandler.emit(mapOf("type" to "ready")) }
    }

    private fun removeProtocolSessionsForTransport(transportSessionId: String) {
        val toRemove = protocolSessions.filterValues { it.transportSessionId == transportSessionId }
        toRemove.keys.forEach { key ->
            protocolSessions.remove(key)?.let { record ->
                record.eventChannel.setStreamHandler(null)
                record.otaEventChannel?.setStreamHandler(null)
            }
        }
    }

    private data class TransportSessionRecord(
        val sessionId: String,
        val transportKind: String,
        val deviceKey: String,
        val eventChannel: EventChannel,
        val eventHandler: QueuedEventStreamHandler,
        val escalationEventChannel: EventChannel? = null,
        val escalationEventHandler: QueuedEventStreamHandler? = null,
        @Volatile var lastTransportStatus: Int = Constants.CONNECTING,
    )

    private data class ProtocolSessionRecord(
        val protocolSessionId: String,
        val transportSessionId: String,
        val deviceKey: String,
        val transportKind: String,
        val eventChannel: EventChannel,
        val eventHandler: QueuedEventStreamHandler,
        val otaEventChannel: EventChannel? = null,
        val otaEventHandler: QueuedEventStreamHandler? = null,
    )
}
