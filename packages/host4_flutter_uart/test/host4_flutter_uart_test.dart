import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_device_native/host4_flutter_device_native.dart';
import 'package:host4_flutter_transport/host4_flutter_transport.dart';
import 'package:host4_flutter_uart/host4_flutter_uart.dart';

void main() {
  test('connect creates uart transport and forwards broker events', () async {
    final native = _FakeUartNative();
    final uart = Host4Uart(native: native);

    final session = await uart.connect();
    expect(session.id, 'uart-session-1');
    expect(session.device.id, Host4Uart.deviceId);
    expect(session.device.kind, TransportKind.uart);

    final events = <TransportEvent>[];
    final sub = session.events.listen(events.add);
    await Future<void>.delayed(Duration.zero);
    expect(events, isEmpty);

    native.emit(
      const NativeTransportEvent(type: NativeTransportEventType.connecting),
    );
    native.emit(const NativeTransportEvent(type: NativeTransportEventType.ready));
    native.emit(
      const NativeTransportEvent(type: NativeTransportEventType.disconnected),
    );
    native.emit(
      const NativeTransportEvent(type: NativeTransportEventType.recovering),
    );
    await Future<void>.delayed(Duration.zero);

    expect(events[0], isA<TransportConnecting>());
    expect(events[1], isA<TransportReady>());
    expect(events[2], isA<TransportDisconnected>());
    expect(events[3], isA<TransportRecovering>());

    await session.disconnect();
    expect(native.disconnected, 'uart-session-1');
    await sub.cancel();
    await native.dispose();
  });
}

class _FakeUartNative extends Host4FlutterDeviceNative {
  final StreamController<NativeTransportEvent> _events =
      StreamController<NativeTransportEvent>.broadcast();
  String? disconnected;

  @override
  Future<String> connectUart({Map<String, Object?> options = const {}}) async {
    return 'uart-session-1';
  }

  @override
  Stream<NativeTransportEvent> transportEvents(String transportSessionId) {
    return _events.stream;
  }

  @override
  Future<void> disconnectTransport(String transportSessionId) async {
    disconnected = transportSessionId;
  }

  void emit(NativeTransportEvent event) {
    _events.add(event);
  }

  Future<void> dispose() => _events.close();
}
