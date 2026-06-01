import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_usb/host4_flutter_usb.dart';

void main() {
  test('usb package exposes discovery and connect API', () {
    final usb = Host4Usb();

    expect(usb.isImplemented, isTrue);
    expect(usb.discovery(), isA<Host4UsbDiscovery>());
    expect(usb.reconnect, isA<Function>());
    expect(usb.release, isA<Function>());
  });
}
