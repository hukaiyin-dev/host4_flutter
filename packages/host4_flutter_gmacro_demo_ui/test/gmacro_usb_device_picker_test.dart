import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_gmacro_demo_ui/src/pages/gmacro/gmacro_usb_device_picker.dart';
import 'package:host4_flutter_transport/host4_flutter_transport.dart';
import 'package:host4_flutter_usb/host4_flutter_usb.dart';

void main() {
  testWidgets('returns the USB device selected by the user', (tester) async {
    DeviceDescriptor? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                selected = await showGmacroUsbDevicePicker(
                  context,
                  usb: _FakeUsb(),
                );
              },
              child: const Text('选择 USB'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('选择 USB'));
    await tester.pumpAndSettle();
    expect(find.text('Jieli USB Composite Device'), findsOneWidget);
    expect(find.text('Xbox 360 Controller'), findsOneWidget);

    await tester.tap(find.text('Xbox 360 Controller'));
    await tester.pumpAndSettle();
    expect(selected?.id, '45e:28e');
  });
}

class _FakeUsb extends Host4Usb {
  @override
  DeviceDiscovery discovery() => _FakeUsbDiscovery();
}

class _FakeUsbDiscovery implements DeviceDiscovery {
  @override
  Stream<DeviceDescriptor> scan(DeviceScanQuery query) =>
      Stream<DeviceDescriptor>.fromIterable(const [
        DeviceDescriptor(
          id: '3654:4255',
          name: 'Jieli USB Composite Device',
          kind: TransportKind.usb,
        ),
        DeviceDescriptor(
          id: '45e:28e',
          name: 'Xbox 360 Controller',
          kind: TransportKind.usb,
        ),
      ]);

  @override
  Future<void> stop() async {}
}
