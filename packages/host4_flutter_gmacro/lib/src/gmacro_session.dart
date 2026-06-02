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
  /// 所有订阅者（realtimeEvents、GmacroSessionPage、GmacroApiTestPage 等）
  /// 共享同一个 native [EventChannel] 连接，不会有重复创建/订阅丢失问题。
  final StreamController<ProtocolEvent> _eventController =
      StreamController<ProtocolEvent>.broadcast();

  StreamSubscription<NativeProtocolEvent>? _nativeSub;

  void _initEvents() {
    _nativeSub = _native
        .protocolEvents(id)
        .listen(
          (nativeEvent) => _eventController.add(_mapProtocolEvent(nativeEvent)),
        );
  }

  @override
  Stream<ProtocolEvent> get events => _eventController.stream;

  /// 实时按键/摇杆/扳机事件流。
  ///
  /// 从共享 [_eventController] 流中的 [ProtocolBusy] 事件解析而来。
  /// [ProtocolBusy.reason] 为事件名（`devKeysState` / `testKeys`），
  /// [ProtocolBusy.payload] 为事件数据字段（`keys` / `j1x` / `j1y` 等）。
  ///
  /// 每次访问此 getter 都会创建一个新的变换管道，
  /// 但所有管道都监听同一个共享的 _eventController 广播流，
  /// 因此不会产生重复的 native EventChannel 订阅。
  Stream<GmacroRealtimeEvent> get realtimeEvents {
    return events.where((e) => e is ProtocolBusy).cast<ProtocolBusy>().expand((
      busy,
    ) {
      final eventName = busy.reason;

      switch (eventName) {
        case 'devKeysState':
          return <GmacroRealtimeEvent>[
            DeviceKeysStateEvent.fromMap(busy.payload),
          ];
        case 'testKeys':
          return <GmacroRealtimeEvent>[TestEventMode.fromMap(busy.payload)];
        default:
          return const Iterable<GmacroRealtimeEvent>.empty();
      }
    });
  }

  /// Android USB 回退实时流由 `DPKeyEventRsp` 转换而来。
  /// 这使得输入/光标用户始终使用统一的 `GmacroRealtimeEvent` 模型。
  /// 即使平台在专用事件通道上发出 USB 键帧。
  Stream<GmacroRealtimeEvent> get usbRealtimeEvents {
    if (transport.device.kind != TransportKind.usb) {
      return const Stream<GmacroRealtimeEvent>.empty();
    }
    return _native
        .usbDpKeyEvents(transport.id)
        .map<GmacroRealtimeEvent>(DeviceKeysStateEvent.fromNativeDpKeyEvent);
  }

  @override
  Future<void> close() async {
    await _nativeSub?.cancel();
    await _eventController.close();
    return _native.closeProtocol(id);
  }

  Future<void> startOta(Uint8List firmwareData) {
    return _native.startOta(protocolSessionId: id, firmwareData: firmwareData);
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
