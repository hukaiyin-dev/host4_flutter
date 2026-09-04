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

  static const EventChannel _usbScanChannel = EventChannel(
    'host4_flutter_device_native/usb_scan',
  );

  /// One cached stream per session — multiple Dart listeners must not open
  /// duplicate native [EventChannel] subscriptions (that overwrites [eventSink]).
  final Map<String, Stream<NativeTransportEvent>> _transportEventStreams =
      <String, Stream<NativeTransportEvent>>{};

  final Map<String, Stream<Map<String, Object?>>> _escalationEventStreams =
      <String, Stream<Map<String, Object?>>>{};

  final Map<String, Stream<NativeProtocolEvent>> _protocolEventStreams =
      <String, Stream<NativeProtocolEvent>>{};
  final Map<String, Stream<NativeOtaUpgradeEvent>> _otaEventStreams =
      <String, Stream<NativeOtaUpgradeEvent>>{};

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
  Stream<NativeDiscoveredDevice> scanUsb({
    Map<String, Object?> hints = const {},
  }) {
    return _usbScanChannel
        .receiveBroadcastStream(<String, Object?>{'hints': hints})
        .map(
          (dynamic event) => NativeDiscoveredDevice.fromMap(
            Map<String, Object?>.from(event as Map),
          ),
        );
  }

  @override
  Future<void> stopUsbScan() {
    return methodChannel.invokeMethod<void>('stopUsbScan');
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
  Future<String> connectUsb({
    String? deviceId,
    Map<String, Object?> options = const {},
  }) async {
    final sessionId = await methodChannel.invokeMethod<String>(
      'connectUsb',
      <String, Object?>{'deviceId': deviceId, 'options': options},
    );
    if (sessionId == null || sessionId.isEmpty) {
      throw PlatformException(
        code: 'missing-transport-session-id',
        message: 'Native USB bridge returned an empty transport session id.',
      );
    }
    return sessionId;
  }

  @override
  Future<void> reconnectUsb() {
    return methodChannel.invokeMethod<void>('reconnectUsb');
  }

  @override
  Future<void> releaseUsb() {
    return methodChannel.invokeMethod<void>('releaseUsb');
  }

  @override
  Future<String> connectSystemConnectedBle({
    required List<String> serviceIds,
    List<String> deviceNames = const [],
    Map<String, Object?> options = const {},
  }) async {
    final sessionId = await methodChannel.invokeMethod<String>(
      'connectSystemConnectedBle',
      <String, Object?>{
        'serviceIds': serviceIds,
        'deviceNames': deviceNames,
        'options': options,
      },
    );
    if (sessionId == null || sessionId.isEmpty) {
      throw PlatformException(
        code: 'missing-transport-session-id',
        message:
            'Native system-connected BLE bridge returned an empty transport session id.',
      );
    }
    return sessionId;
  }

  @override
  Future<String> connectMfi({
    required String protocolString,
    Map<String, Object?> options = const {},
  }) async {
    throw PlatformException(
      code: 'mfi-unsupported',
      message: 'MFi transport is not available in this build.',
    );
  }

  @override
  Future<bool> isMfiAccessoryConnected({required String protocolString}) async {
    return false;
  }

  @override
  Stream<NativeMfiAccessoryEvent> mfiAccessoryEvents({
    required String protocolString,
  }) {
    return const Stream<NativeMfiAccessoryEvent>.empty();
  }

  @override
  Stream<NativeTransportEvent> transportEvents(String transportSessionId) {
    return _transportEventStreams.putIfAbsent(transportSessionId, () {
      return EventChannel(
        'host4_flutter_device_native/transport_events/$transportSessionId',
      ).receiveBroadcastStream().map(
        (dynamic event) => NativeTransportEvent.fromMap(
          Map<String, Object?>.from(event as Map),
        ),
      );
    });
  }

  Stream<Map<String, Object?>> _transportEscalationEvents(
    String transportSessionId,
  ) {
    return _escalationEventStreams.putIfAbsent(transportSessionId, () {
      return EventChannel(
        'host4_flutter_device_native/transport_escalation_events/$transportSessionId',
      ).receiveBroadcastStream().map(
        (dynamic event) => Map<String, Object?>.from(event as Map),
      );
    });
  }

  @override
  Stream<Map<String, Object?>> transportEscalationEvents(
    String transportSessionId,
  ) {
    return _transportEscalationEvents(transportSessionId);
  }

  @override
  Stream<NativeDpKeyEvent> usbDpKeyEvents(String transportSessionId) {
    return _transportEscalationEvents(transportSessionId)
        .where((event) => event['type'] == 'dpKeyEvent')
        .map(NativeDpKeyEvent.fromMap);
  }

  @override
  Stream<NativeDeviceAlignEvent> deviceAlignEvents(String transportSessionId) {
    return _transportEscalationEvents(transportSessionId)
        .where((event) => event['type'] == 'deviceAlign')
        .map(NativeDeviceAlignEvent.fromMap);
  }

  @override
  Future<void> disconnectTransport(String transportSessionId) {
    _transportEventStreams.remove(transportSessionId);
    _escalationEventStreams.remove(transportSessionId);
    return methodChannel.invokeMethod<void>(
      'disconnectTransport',
      <String, Object?>{'transportSessionId': transportSessionId},
    );
  }

  @override
  Future<String> attachGmacroProtocol(
    String transportSessionId, {
    Map<String, Object?> options = const {},
  }) async {
    final sessionId = await methodChannel.invokeMethod<String>(
      'attachGmacroProtocol',
      <String, Object?>{'transportSessionId': transportSessionId, ...options},
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
    return _protocolEventStreams.putIfAbsent(protocolSessionId, () {
      return EventChannel(
        'host4_flutter_device_native/protocol_events/$protocolSessionId',
      ).receiveBroadcastStream().map((dynamic event) {
        print('[NativeChannel] protocol event received raw=$event');
        final map = Map<String, Object?>.from(event as Map);
        if (map['reason'] == 'calibrationFinished') {
          print('[NativeChannel] protocol calibrationFinished map=$map');
        }
        return NativeProtocolEvent.fromMap(map);
      });
    });
  }

  @override
  Stream<NativeOtaUpgradeEvent> otaUpgradeEvents(String protocolSessionId) {
    return _otaEventStreams.putIfAbsent(protocolSessionId, () {
      return EventChannel(
        'host4_flutter_device_native/ota_events/$protocolSessionId',
      ).receiveBroadcastStream().map(
        (dynamic event) => NativeOtaUpgradeEvent.fromMap(
          Map<String, Object?>.from(event as Map),
        ),
      );
    });
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
    _protocolEventStreams.remove(protocolSessionId);
    _otaEventStreams.remove(protocolSessionId);
    return methodChannel.invokeMethod<void>('closeProtocol', <String, Object?>{
      'protocolSessionId': protocolSessionId,
    });
  }

  @override
  Future<void> startOta({
    required String protocolSessionId,
    required Uint8List firmwareData,
  }) {
    return methodChannel.invokeMethod<void>('startOta', <String, Object?>{
      'protocolSessionId': protocolSessionId,
      'firmwareData': firmwareData,
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
