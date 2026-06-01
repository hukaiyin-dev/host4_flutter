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

  Future<String> connectBle({
    required String deviceId,
    Map<String, Object?> options = const {},
  }) {
    return Host4FlutterDeviceNativePlatform.instance.connectBle(
      deviceId: deviceId,
      options: options,
    );
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

  Stream<NativeTransportEvent> transportEvents(String transportSessionId) {
    return Host4FlutterDeviceNativePlatform.instance.transportEvents(
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
