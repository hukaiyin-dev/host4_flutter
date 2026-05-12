import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_usb/host4_flutter_usb.dart';

void main() {
  test('usb package is scaffolded but not enabled yet', () {
    const usb = Host4Usb();

    expect(usb.isImplemented, isFalse);
    expect(usb.pendingReason, contains('later phase'));
  });
}
