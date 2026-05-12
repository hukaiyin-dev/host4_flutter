import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_mfi/host4_flutter_mfi.dart';

void main() {
  test('mfi package is scaffolded but not enabled yet', () {
    const mfi = Host4Mfi();

    expect(mfi.isImplemented, isFalse);
    expect(mfi.pendingReason, contains('later phase'));
  });
}
