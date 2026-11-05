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

  test('systemConnectedDevices returns every matching BLE device', () async {
    final ble = Host4Ble(native: _FakeDeviceNative());

    final devices = await ble.systemConnectedDevices(const <String>[
      'FF00',
      'FF10',
    ]);

    expect(devices, hasLength(2));
    expect(devices.first.id, 'system-device-1');
    expect(devices.first.name, 'Controller A');
    expect(devices.first.kind, TransportKind.ble);
    expect(devices.first.metadata['systemConnected'], isTrue);
    expect(devices.last.id, 'system-device-2');
  });

  test(
    'connectSystemConnectedDevice targets and retains the selected device',
    () async {
      final native = _FakeDeviceNative();
      final ble = Host4Ble(native: native);
      const selected = DeviceDescriptor(
        id: 'system-device-2',
        name: 'GameMacro',
        kind: TransportKind.ble,
        metadata: <String, Object?>{'systemConnected': true},
      );

      final session = await ble.connectSystemConnectedDevice(
        selected,
        serviceIds: const <String>['FF00', 'FF10'],
      );

      expect(native.connectedSystemDeviceId, 'system-device-2');
      expect(session.id, 'system-transport-2');
      expect(session.device.id, 'system-device-2');
    },
  );
}

class _FakeDeviceNative extends Host4FlutterDeviceNative {
  String? connectedSystemDeviceId;

  @override
  Future<List<NativeDiscoveredDevice>> getSystemConnectedBleDevices({
    required List<String> serviceIds,
  }) async {
    expect(serviceIds, <String>['FF00', 'FF10']);
    return const <NativeDiscoveredDevice>[
      NativeDiscoveredDevice(
        deviceId: 'system-device-1',
        name: 'Controller A',
        kind: NativeTransportKind.ble,
        metadata: <String, Object?>{'systemConnected': true},
      ),
      NativeDiscoveredDevice(
        deviceId: 'system-device-2',
        name: 'Controller B',
        kind: NativeTransportKind.ble,
        metadata: <String, Object?>{'systemConnected': true},
      ),
    ];
  }

  @override
  Future<String> connectBle({
    required String deviceId,
    Map<String, Object?> options = const {},
  }) async {
    return 'transport-1';
  }

  @override
  Future<String> connectSystemConnectedBle({
    required List<String> serviceIds,
    List<String> deviceNames = const [],
    String? deviceId,
    Map<String, Object?> options = const {},
  }) async {
    connectedSystemDeviceId = deviceId;
    return 'system-transport-2';
  }
}
