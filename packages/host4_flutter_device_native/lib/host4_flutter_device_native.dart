import 'dart:typed_data';

import 'host4_flutter_device_native_platform_interface.dart';
import 'src/native_models.dart';
export 'src/native_models.dart';

class Host4FlutterDeviceNative {
  Future<String?> getPlatformVersion() {
    return Host4FlutterDeviceNativePlatform.instance.getPlatformVersion();
  }

  Stream<NativeDiscoveredDevice> scanBle({
    List<String> serviceIds = const [],
    Map<String, Object?> hints = const {},
  }) {
    return Host4FlutterDeviceNativePlatform.instance.scanBle(
      serviceIds: serviceIds,
      hints: hints,
    );
  }

  Future<void> stopBleScan() {
    return Host4FlutterDeviceNativePlatform.instance.stopBleScan();
  }

  Stream<NativeDiscoveredDevice> scanUsb({
    Map<String, Object?> hints = const {},
  }) {
    return Host4FlutterDeviceNativePlatform.instance.scanUsb(hints: hints);
  }

  Future<void> stopUsbScan() {
    return Host4FlutterDeviceNativePlatform.instance.stopUsbScan();
  }

  Future<String> connectBle({
    required String deviceId,
    Map<String, Object?> options = const {},
  }) {
    return Host4FlutterDeviceNativePlatform.instance.connectBle(
      deviceId: deviceId,
      options: options,
    );
  }

  Future<String> connectUsb({
    String? deviceId,
    Map<String, Object?> options = const {},
  }) {
    return Host4FlutterDeviceNativePlatform.instance.connectUsb(
      deviceId: deviceId,
      options: options,
    );
  }

  /// Re-triggers SDK [ReliableUsbCommManager.searchAndConnectAsync].
  Future<void> reconnectUsb() {
    return Host4FlutterDeviceNativePlatform.instance.reconnectUsb();
  }

  /// Tears down the USB host stack initialized by [connectUsb].
  Future<void> releaseUsb() {
    return Host4FlutterDeviceNativePlatform.instance.releaseUsb();
  }

  Future<String> connectSystemConnectedBle({
    required List<String> serviceIds,
    List<String> deviceNames = const [],
    Map<String, Object?> options = const {},
  }) {
    return Host4FlutterDeviceNativePlatform.instance.connectSystemConnectedBle(
      serviceIds: serviceIds,
      deviceNames: deviceNames,
      options: options,
    );
  }

  /// iOS only: opens a transport session with the MFi accessory matching [protocolString].
  /// Returns the transport session ID.
  Future<String> connectMfi({
    required String protocolString,
    Map<String, Object?> options = const {},
  }) {
    return Host4FlutterDeviceNativePlatform.instance.connectMfi(
      protocolString: protocolString,
      options: options,
    );
  }

  /// iOS only: returns true if an MFi accessory matching [protocolString] is connected.
  Future<bool> isMfiAccessoryConnected({required String protocolString}) {
    return Host4FlutterDeviceNativePlatform.instance.isMfiAccessoryConnected(
      protocolString: protocolString,
    );
  }

  /// iOS only: stream of MFi accessory connect/disconnect events for [protocolString].
  Stream<NativeMfiAccessoryEvent> mfiAccessoryEvents({
    required String protocolString,
  }) {
    return Host4FlutterDeviceNativePlatform.instance.mfiAccessoryEvents(
      protocolString: protocolString,
    );
  }

  Stream<NativeTransportEvent> transportEvents(String transportSessionId) {
    return Host4FlutterDeviceNativePlatform.instance.transportEvents(
      transportSessionId,
    );
  }

  /// BLE / USB: [DPKeyEventRsp] escalation events from the device.
  Stream<NativeDpKeyEvent> usbDpKeyEvents(String transportSessionId) {
    return Host4FlutterDeviceNativePlatform.instance.usbDpKeyEvents(
      transportSessionId,
    );
  }

  /// BLE / USB: [DeviceAlignRsp] calibration / align escalation events.
  Stream<NativeDeviceAlignEvent> deviceAlignEvents(String transportSessionId) {
    return Host4FlutterDeviceNativePlatform.instance.deviceAlignEvents(
      transportSessionId,
    );
  }

  /// BLE / USB: shared escalation stream (`dpKeyEvent` + `deviceAlign`).
  ///
  /// Use this when subscribing to both DP key and calibration data so only one
  /// native [EventChannel] listener is opened per transport session.
  Stream<Map<String, Object?>> transportEscalationEvents(
    String transportSessionId,
  ) {
    return Host4FlutterDeviceNativePlatform.instance.transportEscalationEvents(
      transportSessionId,
    );
  }

  Future<void> disconnectTransport(String transportSessionId) {
    return Host4FlutterDeviceNativePlatform.instance.disconnectTransport(
      transportSessionId,
    );
  }

  Future<String> attachGmacroProtocol(
    String transportSessionId, {
    Map<String, Object?> options = const {},
  }) {
    return Host4FlutterDeviceNativePlatform.instance.attachGmacroProtocol(
      transportSessionId,
      options: options,
    );
  }

  Stream<NativeProtocolEvent> protocolEvents(String protocolSessionId) {
    return Host4FlutterDeviceNativePlatform.instance.protocolEvents(
      protocolSessionId,
    );
  }

  /// OTA 升级事件流：进度 / 成功 / 失败。
  Stream<NativeOtaUpgradeEvent> otaUpgradeEvents(String protocolSessionId) {
    return Host4FlutterDeviceNativePlatform.instance.otaUpgradeEvents(
      protocolSessionId,
    );
  }

  Future<Map<String, Object?>> invokeGmacroMethod({
    required String protocolSessionId,
    required String method,
    Map<String, Object?> arguments = const {},
  }) {
    return Host4FlutterDeviceNativePlatform.instance.invokeGmacroMethod(
      protocolSessionId: protocolSessionId,
      method: method,
      arguments: arguments,
    );
  }

  Future<void> closeProtocol(String protocolSessionId) {
    return Host4FlutterDeviceNativePlatform.instance.closeProtocol(
      protocolSessionId,
    );
  }

  Future<void> startOta({
    required String protocolSessionId,
    required Uint8List firmwareData,
  }) {
    return Host4FlutterDeviceNativePlatform.instance.startOta(
      protocolSessionId: protocolSessionId,
      firmwareData: firmwareData,
    );
  }

  /// Android only: shows the system permission dialog for BLE scan (Bluetooth + location).
  /// Returns `true` when all required permissions are granted.
  Future<bool> ensureBleScanPermissions() {
    return Host4FlutterDeviceNativePlatform.instance.ensureBleScanPermissions();
  }
}
