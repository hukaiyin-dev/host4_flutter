import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_device_native/host4_flutter_device_native.dart';
import 'package:host4_flutter_mfi/host4_flutter_mfi.dart';
import 'package:host4_flutter_transport/host4_flutter_transport.dart';

void main() {
  test('connect returns a MFi transport session wrapper', () async {
    final native = _FakeDeviceNative();
    final mfi = Host4Mfi(native: native);

    final session = await mfi.connect(protocolString: 'customer.protocol');

    expect(session.id, 'mfi-transport-1');
    expect(session.device.kind, TransportKind.mfi);
    expect(session.device.metadata['protocolString'], 'customer.protocol');
    expect(native.protocolString, 'customer.protocol');
  });

  test('accessoryEvents requires protocol and maps native events', () async {
    final native = _FakeDeviceNative();
    final mfi = Host4Mfi(native: native);

    expect(() => mfi.accessoryEvents, throwsStateError);

    await mfi.updateProtocol('customer.protocol');
    final event = await mfi.accessoryEvents.first;

    expect(event.type, MfiAccessoryEventType.connected);
    expect(event.protocolString, 'customer.protocol');
    expect(event.name, 'MFi Pad');
    expect(event.metadata['serialNumber'], 'SN-1');
  });
}

class _FakeDeviceNative extends Host4FlutterDeviceNative {
  String? protocolString;

  @override
  Future<String> connectMfi({
    required String protocolString,
    Map<String, Object?> options = const {},
  }) async {
    this.protocolString = protocolString;
    return 'mfi-transport-1';
  }

  @override
  Stream<NativeMfiAccessoryEvent> mfiAccessoryEvents({
    required String protocolString,
  }) {
    return Stream<NativeMfiAccessoryEvent>.value(
      NativeMfiAccessoryEvent(
        type: NativeMfiAccessoryEventType.connected,
        protocolString: protocolString,
        name: 'MFi Pad',
        metadata: const <String, Object?>{'serialNumber': 'SN-1'},
      ),
    );
  }
}
