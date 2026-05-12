import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_ble/host4_flutter_ble.dart';
import 'package:host4_flutter_device_native/host4_flutter_device_native.dart';
import 'package:host4_flutter_transport/host4_flutter_transport.dart';

void main() {
  test('connect returns a transport session wrapper', () async {
    final ble = Host4Ble(native: _FakeDeviceNative());
    const device = DeviceDescriptor(
      id: 'ble-device-1',
      name: 'Gamepad',
      kind: TransportKind.ble,
    );

    final session = await ble.connect(device);

    expect(session.id, 'transport-1');
    expect(session.device.id, 'ble-device-1');
  });
}

class _FakeDeviceNative extends Host4FlutterDeviceNative {
  @override
  Future<String> connectBle({
    required String deviceId,
    Map<String, Object?> options = const {},
  }) async {
    return 'transport-1';
  }
}
