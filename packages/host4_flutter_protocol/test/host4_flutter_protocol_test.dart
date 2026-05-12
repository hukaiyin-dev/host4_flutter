import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_protocol/host4_flutter_protocol.dart';

void main() {
  test('protocol busy event exposes reason', () {
    const busy = ProtocolBusy('waiting-for-native-attach');

    expect(busy.reason, 'waiting-for-native-attach');
  });
}
