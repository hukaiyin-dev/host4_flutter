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
  /// 所有订阅者（GmacroSessionPage、GmacroApiTestPage 等）
  /// 共享同一个 native [EventChannel] 连接，不会有重复创建/订阅丢失问题。
  final StreamController<ProtocolEvent> _eventController =
      StreamController<ProtocolEvent>.broadcast();

  /// 共享的实时输入事件广播流。
  ///
  /// BLE 来自 [ProtocolBusy]（`devKeysState` / `testKeys`）；
  /// Android USB 额外合并 `DPKeyEventRsp` 转换后的同构事件。
  /// 上层只需订阅 [realtimeEvents]，无需区分 transport。
  final StreamController<GmacroRealtimeEvent> _realtimeEventController =
      StreamController<GmacroRealtimeEvent>.broadcast();

  StreamSubscription<NativeProtocolEvent>? _nativeSub;
  StreamSubscription<ProtocolEvent>? _realtimeProtocolSub;
  StreamSubscription<GmacroRealtimeEvent>? _usbRealtimeSub;

  void _initEvents() {
    _nativeSub = _native
        .protocolEvents(id)
        .listen(
          (nativeEvent) => _eventController.add(_mapProtocolEvent(nativeEvent)),
        );

    _realtimeProtocolSub = _eventController.stream.listen(
      _forwardProtocolRealtimeEvents,
    );

    if (transport.device.kind == TransportKind.usb) {
      _usbRealtimeSub = _native
          .usbDpKeyEvents(transport.id)
          .map<GmacroRealtimeEvent>(DeviceKeysStateEvent.fromNativeDpKeyEvent)
          .listen(_realtimeEventController.add);
    }
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
  /// BLE 与 USB 共用此流：BLE 来自 [ProtocolBusy]（`devKeysState` / `testKeys`），
  /// Android USB 额外合并 `DPKeyEventRsp` 转换后的 [DeviceKeysStateEvent]。
  Stream<GmacroRealtimeEvent> get realtimeEvents =>
      _realtimeEventController.stream;

  @override
  Future<void> close() async {
    await _nativeSub?.cancel();
    await _realtimeProtocolSub?.cancel();
    await _usbRealtimeSub?.cancel();
    await _eventController.close();
    await _realtimeEventController.close();
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
