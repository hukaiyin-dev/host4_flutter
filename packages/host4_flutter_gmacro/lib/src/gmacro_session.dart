import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:host4_flutter_device_native/host4_flutter_device_native.dart';
import 'package:host4_flutter_protocol/host4_flutter_protocol.dart';
import 'package:host4_flutter_transport/host4_flutter_transport.dart';

import 'Models/gmacro_protocol_events.dart';
import 'Models/gmacro_support_enums.dart';

class GmacroSession implements ProtocolSession {
  GmacroSession({
    required this.id,
    required this.transport,
    required Host4FlutterDeviceNative native,
  }) : _native = native {
    _initEvents();
  }

  final Host4FlutterDeviceNative _native;

  @override
  final String id;

  @override
  String get protocolName => 'gmacro';

  @override
  final TransportSession transport;

  /// 共享的协议事件广播流。
  ///
  /// 所有订阅者（GmacroSessionPage、GmacroApiTestPage 等）
  /// 共享同一个 native [EventChannel] 连接，不会有重复创建/订阅丢失问题。
  final StreamController<ProtocolEvent> _eventController =
      StreamController<ProtocolEvent>.broadcast();

  /// 共享的实时输入事件广播流。
  ///
  /// BLE / USB 均可来自 [ProtocolBusy]（`devKeysState` / `testKeys`）；
  /// Android BLE / USB 额外合并 native `DPKeyEventRsp` 转换后的同构事件。
  /// 上层只需订阅 [realtimeEvents]，无需区分 transport。
  final StreamController<GmacroRealtimeEvent> _realtimeEventController =
      StreamController<GmacroRealtimeEvent>.broadcast();

  /// Android BLE / USB：native `DeviceAlignRsp` 校准进度。
  final StreamController<DeviceCalibrationEvent> _calibrationEventController =
      StreamController<DeviceCalibrationEvent>.broadcast();

  StreamSubscription<NativeProtocolEvent>? _nativeSub;
  StreamSubscription<ProtocolEvent>? _realtimeProtocolSub;
  StreamSubscription<Map<String, Object?>>? _escalationSub;

  void _initEvents() {
    _nativeSub = _native
        .protocolEvents(id)
        .listen(
          (nativeEvent) {
            if (nativeEvent.reason == 'calibrationFinished') {
              print(
                '[GmacroSession] native calibrationFinished event '
                'payload=${nativeEvent.payload}',
              );
            }
            _eventController.add(_mapProtocolEvent(nativeEvent));
          },
          onError: (Object error, StackTrace stackTrace) {
            print('[GmacroSession] protocolEvents error: $error');
            print('$stackTrace');
          },
        );

    _realtimeProtocolSub = _eventController.stream.listen(
      _forwardProtocolRealtimeEvents,
    );

    // iOS：校准完成事件（calibrationFinished）通过 protocol_events 通道以 busy 形式推送
    // Android：通过独立的 escalation_events 通道以 deviceAlign 形式推送
    // 这里统一监听 protocol_events 通道，处理 iOS 的校准事件
    _eventController.stream.listen(_forwardProtocolCalibrationEvents);

    if (_shouldMergeNativeEscalationEvents) {
      // Single native EventChannel subscription; fan out by event type on Dart side.
      _escalationSub = _native
          .transportEscalationEvents(transport.id)
          .listen(_onTransportEscalationEvent);
    }
  }

  void _onTransportEscalationEvent(Map<String, Object?> event) {
    switch (event['type']) {
      case 'dpKeyEvent':
        _realtimeEventController.add(
          DeviceKeysStateEvent.fromNativeDpKeyEvent(
            NativeDpKeyEvent.fromMap(event),
          ),
        );
      case 'testModeEvent':
        _realtimeEventController.add(
          TestEventMode.fromNativeDpKeyEvent(NativeDpKeyEvent.fromMap(event)),
        );
      case 'deviceAlign':
        _calibrationEventController.add(
          DeviceCalibrationEvent.fromNative(
            NativeDeviceAlignEvent.fromMap(event),
          ),
        );
    }
  }

  /// Android BLE / USB：native 侧通过 escalation 推送 DP 按键与校准数据。
  bool get _shouldMergeNativeEscalationEvents {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    return switch (transport.device.kind) {
      TransportKind.ble || TransportKind.usb => true,
      TransportKind.mfi => false,
    };
  }

  /// iOS: 转发校准完成事件（calibrationFinished）到 _calibrationEventController
  ///
  /// iOS 的校准完成事件通过 protocol_events 通道以 busy + reason: "calibrationFinished"
  /// 形式推送，这里将其转换为 DeviceCalibrationEvent 并添加到校准事件流。
  void _forwardProtocolCalibrationEvents(ProtocolEvent event) {
    if (event is! ProtocolBusy || event.reason != 'calibrationFinished') {
      return;
    }
    final payload = event.payload;
    final subId = _asInt(payload['subId']);
    final result = _asInt(payload['result']);

    print('[GmacroSession] calibrationFinished payload=$payload');
    _calibrationEventController.add(
      DeviceCalibrationEvent(
        subId: subId,
        kind: DeviceCalibrationSubId.fromValue(subId),
        result: result,
        param1: _asIntList(payload['param1']),
        param2: _asIntList(payload['param2']),
      ),
    );
  }

  void _forwardProtocolRealtimeEvents(ProtocolEvent event) {
    if (event is! ProtocolBusy) {
      return;
    }
    for (final realtimeEvent in _mapProtocolBusyToRealtimeEvents(event)) {
      _realtimeEventController.add(realtimeEvent);
    }
  }

  Iterable<GmacroRealtimeEvent> _mapProtocolBusyToRealtimeEvents(
    ProtocolBusy busy,
  ) {
    switch (busy.reason) {
      case 'devKeysState':
        return <GmacroRealtimeEvent>[
          DeviceKeysStateEvent.fromMap(busy.payload),
        ];
      case 'testKeys':
        return <GmacroRealtimeEvent>[TestEventMode.fromMap(busy.payload)];
      default:
        return const Iterable<GmacroRealtimeEvent>.empty();
    }
  }

  @override
  Stream<ProtocolEvent> get events => _eventController.stream;

  /// 实时按键/摇杆/扳机事件流。
  ///
  /// BLE 与 USB 共用此流：均可来自 [ProtocolBusy]（`devKeysState` / `testKeys`），
  /// Android BLE / USB 额外合并 `DPKeyEventRsp` 转换后的 [DeviceKeysStateEvent]。
  Stream<GmacroRealtimeEvent> get realtimeEvents =>
      _realtimeEventController.stream;

  /// 设备校准进度（陀螺仪 / 摇杆 / 扳机等），来自 [DeviceAlignRsp]。
  Stream<DeviceCalibrationEvent> get calibrationEvents =>
      _calibrationEventController.stream;

  /// OTA 升级事件（进度 / 成功 / 失败）。
  Stream<NativeOtaUpgradeEvent> get otaUpgradeEvents =>
      _native.otaUpgradeEvents(id);

  @override
  Future<void> close() async {
    await _nativeSub?.cancel();
    await _realtimeProtocolSub?.cancel();
    await _escalationSub?.cancel();
    await _eventController.close();
    await _realtimeEventController.close();
    await _calibrationEventController.close();
    return _native.closeProtocol(id);
  }

  Future<void> startOta(Uint8List firmwareData) {
    return _native.startOta(protocolSessionId: id, firmwareData: firmwareData);
  }

  Future<Map<String, Object?>> invoke(
    String method, {
    Map<String, Object?> arguments = const <String, Object?>{},
  }) {
    return _native
        .invokeGmacroMethod(
          protocolSessionId: id,
          method: method,
          arguments: arguments,
        )
        .timeout(const Duration(seconds: 3));
  }

  ProtocolEvent _mapProtocolEvent(NativeProtocolEvent event) {
    switch (event.type) {
      case NativeProtocolEventType.ready:
        return const ProtocolReady();
      case NativeProtocolEventType.busy:
        return ProtocolBusy(event.reason ?? 'busy', payload: event.payload);
      case NativeProtocolEventType.error:
        final failure = event.failure;
        return ProtocolError(
          ProtocolFailure(
            code: failure?.code ?? 'native-protocol-error',
            message:
                failure?.message ??
                'Native protocol reported an unspecified error.',
            details: failure?.details ?? const <String, Object?>{},
          ),
        );
    }
  }
}

int _asInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) {
    return defaultValue;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString()) ?? defaultValue;
}

List<int> _asIntList(dynamic value) {
  if (value is! List) {
    return const <int>[];
  }
  return value
      .map((item) {
        if (item is int) return item;
        if (item is num) return item.toInt();
        return int.tryParse(item.toString()) ?? 0;
      })
      .toList(growable: false);
}
