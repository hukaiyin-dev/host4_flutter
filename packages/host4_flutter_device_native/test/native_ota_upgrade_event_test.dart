import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_device_native/host4_flutter_device_native.dart';

void main() {
  test('parses unified OTA event progress from progress field', () {
    final event = NativeOtaUpgradeEvent.fromMap(<String, Object?>{
      'type': 'progress',
      'code': 100,
      'progress': 0.45,
    });

    expect(event.type, NativeOtaUpgradeEventType.progress);
    expect(event.code, 100);
    expect(event.percent, 0.45);
  });

  test('keeps backward compatibility with percent field', () {
    final event = NativeOtaUpgradeEvent.fromMap(<String, Object?>{
      'type': 'progress',
      'code': 100,
      'percent': 0.75,
    });

    expect(event.type, NativeOtaUpgradeEventType.progress);
    expect(event.code, 100);
    expect(event.percent, 0.75);
  });
}
