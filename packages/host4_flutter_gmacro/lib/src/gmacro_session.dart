import 'dart:async';
import 'dart:typed_data';

import 'package:host4_flutter_device_native/host4_flutter_device_native.dart';
import 'package:host4_flutter_protocol/host4_flutter_protocol.dart';
import 'package:host4_flutter_transport/host4_flutter_transport.dart';

import 'Models/gmacro_protocol_events.dart';

class GmacroSession implements ProtocolSession {
  GmacroSession({
    required this.id,
    required this.transport,
    required Host4FlutterDeviceNative native,
  }) : _native = native;

  final Host4FlutterDeviceNative _native;

  @override
  final String id;

  @override
  String get protocolName => 'gmacro';

  @override
  final TransportSession transport;

  @override
  Stream<ProtocolEvent> get events {
    return _native.protocolEvents(id).map(_mapProtocolEvent);
  }

  /// 实时按键/摇杆/扳机事件流。
  ///
  /// 从 [events] 流中的 [ProtocolBusy] 事件解析而来。
  /// 当 payload 中的 `event` 字段为 `devKeysState` 或 `testKeys` 时触发。
  Stream<GmacroRealtimeEvent> get realtimeEvents {
    return events
        .where((e) => e is ProtocolBusy)
        .cast<ProtocolBusy>()
        .expand((busy) {
      final eventName = busy.payload['event'] as String?;
      if (eventName == null) return const Iterable<GmacroRealtimeEvent>.empty();

      switch (eventName) {
        case 'devKeysState':
          return <GmacroRealtimeEvent>[
            DeviceKeysStateEvent.fromMap(busy.payload),
          ];
        case 'testKeys':
          return <GmacroRealtimeEvent>[
            TestEventMode.fromMap(busy.payload),
          ];
        default:
          return const Iterable<GmacroRealtimeEvent>.empty();
      }
    });
  }

  @override
  Future<void> close() {
    return _native.closeProtocol(id);
  }

  Future<void> startOta(Uint8List firmwareData) {
    return _native.startOta(
      protocolSessionId: id,
      firmwareData: firmwareData,
    );
  }

  Future<Map<String, Object?>> invoke(
    String method, {
    Map<String, Object?> arguments = const <String, Object?>{},
  }) {
    return _native.invokeGmacroMethod(
      protocolSessionId: id,
      method: method,
      arguments: arguments,
    );
  }

  ProtocolEvent _mapProtocolEvent(NativeProtocolEvent event) {
    switch (event.type) {
      case NativeProtocolEventType.ready:
        return const ProtocolReady();
      case NativeProtocolEventType.busy:
        return ProtocolBusy(
          event.reason ?? 'busy',
          payload: event.payload,
        );
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
