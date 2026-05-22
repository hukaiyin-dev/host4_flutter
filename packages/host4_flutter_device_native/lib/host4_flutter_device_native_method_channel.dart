import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'host4_flutter_device_native_platform_interface.dart';
import 'src/native_models.dart';

/// An implementation of [Host4FlutterDeviceNativePlatform] that uses method channels.
class MethodChannelHost4FlutterDeviceNative
    extends Host4FlutterDeviceNativePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('host4_flutter_device_native');

  static const EventChannel _bleScanChannel = EventChannel(
    'host4_flutter_device_native/ble_scan',
  );

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Stream<NativeDiscoveredDevice> scanBle({
    List<String> serviceIds = const [],
    Map<String, Object?> hints = const {},
  }) {
    return _bleScanChannel
        .receiveBroadcastStream(<String, Object?>{
          'serviceIds': serviceIds,
          'hints': hints,
        })
        .map(
          (dynamic event) => NativeDiscoveredDevice.fromMap(
            Map<String, Object?>.from(event as Map),
          ),
        );
  }

  @override
  Future<void> stopBleScan() {
    return methodChannel.invokeMethod<void>('stopBleScan');
  }

  @override
  Future<String> connectBle({
    required String deviceId,
    Map<String, Object?> options = const {},
  }) async {
    final sessionId = await methodChannel.invokeMethod<String>(
      'connectBle',
      <String, Object?>{'deviceId': deviceId, 'options': options},
    );
    if (sessionId == null || sessionId.isEmpty) {
      throw PlatformException(
        code: 'missing-transport-session-id',
        message: 'Native BLE bridge returned an empty transport session id.',
      );
    }
    return sessionId;
  }

  @override
  Stream<NativeTransportEvent> transportEvents(String transportSessionId) {
    return EventChannel(
      'host4_flutter_device_native/transport_events/$transportSessionId',
    ).receiveBroadcastStream().map(
      (dynamic event) =>
          NativeTransportEvent.fromMap(Map<String, Object?>.from(event as Map)),
    );
  }

  @override
  Future<void> disconnectTransport(String transportSessionId) {
    return methodChannel.invokeMethod<void>(
      'disconnectTransport',
      <String, Object?>{'transportSessionId': transportSessionId},
    );
  }

  @override
  Future<String> attachGmacroProtocol(String transportSessionId) async {
    final sessionId = await methodChannel.invokeMethod<String>(
      'attachGmacroProtocol',
      <String, Object?>{'transportSessionId': transportSessionId},
    );
    if (sessionId == null || sessionId.isEmpty) {
      throw PlatformException(
        code: 'missing-protocol-session-id',
        message: 'Native GMacro bridge returned an empty protocol session id.',
      );
    }
    return sessionId;
  }

  @override
  Stream<NativeProtocolEvent> protocolEvents(String protocolSessionId) {
    return EventChannel(
      'host4_flutter_device_native/protocol_events/$protocolSessionId',
    ).receiveBroadcastStream().map(
      (dynamic event) =>
          NativeProtocolEvent.fromMap(Map<String, Object?>.from(event as Map)),
    );
  }

  @override
  Future<Map<String, Object?>> invokeGmacroMethod({
    required String protocolSessionId,
    required String method,
    Map<String, Object?> arguments = const {},
  }) async {
    final result = await methodChannel.invokeMapMethod<String, Object?>(
      'invokeGmacroMethod',
      <String, Object?>{
        'protocolSessionId': protocolSessionId,
        'method': method,
        'arguments': arguments,
      },
    );
    return Map<String, Object?>.from(result ?? const <String, Object?>{});
  }

  @override
  Future<void> closeProtocol(String protocolSessionId) {
    return methodChannel.invokeMethod<void>('closeProtocol', <String, Object?>{
      'protocolSessionId': protocolSessionId,
    });
  }


  /// 权限
  @override
  Future<bool> ensureBleScanPermissions() async {
    final granted = await methodChannel.invokeMethod<bool>(
      'ensureBleScanPermissions',
    );
    return granted ?? false;
  }
}
