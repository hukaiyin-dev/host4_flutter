import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_gmacro/host4_flutter_gmacro.dart';
import 'package:host4_flutter_device_native/host4_flutter_device_native.dart';
import 'package:host4_flutter_transport/host4_flutter_transport.dart';

void main() {
  test('attach wraps a transport session as gmacro protocol session', () async {
    final gmacro = Host4Gmacro(native: _FakeDeviceNative());
    final transport = _FakeTransportSession();

    final session = await gmacro.attach(transport);

    expect(session.id, 'protocol-1');
    expect(session.protocolName, 'gmacro');
    expect(session.transport.id, 'transport-1');
  });
}

class _FakeDeviceNative extends Host4FlutterDeviceNative {
  @override
  Future<String> attachGmacroProtocol(
    String transportSessionId, {
    Map<String, Object?> options = const {},
  }) async {
    return 'protocol-1';
  }
}

class _FakeTransportSession implements TransportSession {
  @override
  final DeviceDescriptor device = const DeviceDescriptor(
    id: 'ble-device-1',
    name: 'Gamepad',
    kind: TransportKind.ble,
  );

  @override
  Future<void> disconnect() async {}

  @override
  Stream<TransportEvent> get events => const Stream<TransportEvent>.empty();

  @override
  String get id => 'transport-1';
}
