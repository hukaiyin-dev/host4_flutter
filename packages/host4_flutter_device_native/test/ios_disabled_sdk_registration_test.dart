import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('disabled iOS SDK branch still registers static event channels',
      () async {
    final source = await File(
      'ios/Classes/Host4FlutterDeviceNativePlugin.swift',
    ).readAsString();
    final disabledBranch = source.substring(0, source.indexOf('#else'));

    expect(disabledBranch, contains('DisabledEventStreamHandler'));
    expect(
      disabledBranch,
      contains('host4_flutter_device_native/ble_scan'),
    );
    expect(
      disabledBranch,
      contains('host4_flutter_device_native/native_log'),
    );
    expect(
      disabledBranch,
      contains('host4_flutter_device_native/mfi_accessory_events'),
    );
    expect(
      '.setStreamHandler(disabledEventStreamHandler)'.allMatches(
        disabledBranch,
      ),
      hasLength(1),
    );
  });
}
