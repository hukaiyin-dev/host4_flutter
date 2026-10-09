import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_transport/host4_flutter_transport.dart';

void main() {
  test('device descriptor keeps transport metadata', () {
    const descriptor = DeviceDescriptor(
      id: 'ble-1',
      name: 'Controller',
      kind: TransportKind.ble,
      metadata: <String, Object?>{'rssi': -42},
    );

    expect(descriptor.id, 'ble-1');
    expect(descriptor.kind, TransportKind.ble);
    expect(descriptor.metadata['rssi'], -42);
  });

  test('uart descriptor is a first-class transport kind', () {
    const descriptor = DeviceDescriptor(
      id: '__uart__',
      name: 'UART Device',
      kind: TransportKind.uart,
    );

    expect(descriptor.kind, TransportKind.uart);
    expect(TransportKind.values, contains(TransportKind.uart));
  });
}
