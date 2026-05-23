import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'host4_flutter_device_native_method_channel.dart';
import 'src/native_models.dart';

abstract class Host4FlutterDeviceNativePlatform extends PlatformInterface {
  /// Constructs a Host4FlutterDeviceNativePlatform.
  Host4FlutterDeviceNativePlatform() : super(token: _token);

  static final Object _token = Object();

  static Host4FlutterDeviceNativePlatform _instance =
      MethodChannelHost4FlutterDeviceNative();

  /// The default instance of [Host4FlutterDeviceNativePlatform] to use.
  ///
  /// Defaults to [MethodChannelHost4FlutterDeviceNative].
  static Host4FlutterDeviceNativePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [Host4FlutterDeviceNativePlatform] when
  /// they register themselves.
  static set instance(Host4FlutterDeviceNativePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Stream<NativeDiscoveredDevice> scanBle({
    List<String> serviceIds = const [],
    Map<String, Object?> hints = const {},
  }) {
    throw UnimplementedError('scanBle() has not been implemented.');
  }

  Future<void> stopBleScan() {
    throw UnimplementedError('stopBleScan() has not been implemented.');
  }

  Future<String> connectBle({
    required String deviceId,
    Map<String, Object?> options = const {},
  }) {
    throw UnimplementedError('connectBle() has not been implemented.');
  }

  Stream<NativeTransportEvent> transportEvents(String transportSessionId) {
    throw UnimplementedError('transportEvents() has not been implemented.');
  }

  Future<void> disconnectTransport(String transportSessionId) {
    throw UnimplementedError('disconnectTransport() has not been implemented.');
  }

  Future<String> attachGmacroProtocol(String transportSessionId) {
    throw UnimplementedError(
      'attachGmacroProtocol() has not been implemented.',
    );
  }

  Stream<NativeProtocolEvent> protocolEvents(String protocolSessionId) {
    throw UnimplementedError('protocolEvents() has not been implemented.');
  }

  Future<Map<String, Object?>> invokeGmacroMethod({
    required String protocolSessionId,
    required String method,
    Map<String, Object?> arguments = const {},
  }) {
    throw UnimplementedError('invokeGmacroMethod() has not been implemented.');
  }

  Future<void> closeProtocol(String protocolSessionId) {
    throw UnimplementedError('closeProtocol() has not been implemented.');
  }

  /// Android only: requests Bluetooth + location permissions required for BLE scan.
  Future<bool> ensureBleScanPermissions() {
    throw UnimplementedError('ensureBleScanPermissions() has not been implemented.');
  }
}
