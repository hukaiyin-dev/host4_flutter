import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('disabled iOS SDK branch registers only BLE and log channels', () async {
    final source = await File(
      'ios/Classes/Host4FlutterDeviceNativePlugin.swift',
    ).readAsString();
    final disabledBranch = source.substring(0, source.indexOf('#else'));

    expect(disabledBranch, contains('DisabledEventStreamHandler'));
    expect(disabledBranch, contains('host4_flutter_device_native/ble_scan'));
    expect(disabledBranch, contains('host4_flutter_device_native/native_log'));
    expect(
      disabledBranch,
      isNot(contains('host4_flutter_device_native/mfi_accessory_events')),
    );
    expect(
      '.setStreamHandler(disabledEventStreamHandler)'.allMatches(
        disabledBranch,
      ),
      hasLength(1),
    );
  });

  test('enabled iOS SDK branch exposes BLE without MFi transport', () async {
    final source = await File(
      'ios/Classes/Host4FlutterDeviceNativePlugin.swift',
    ).readAsString();
    final enabledBranch = source.substring(source.indexOf('#else'));

    expect(enabledBranch, contains('case "connectBle"'));
    expect(enabledBranch, isNot(contains('mfi_accessory_events')));
    expect(enabledBranch, isNot(contains('case "connectMfi"')));
    expect(enabledBranch, isNot(contains('case "isMfiAccessoryConnected"')));
    expect(enabledBranch, isNot(contains('mfiUnsupportedError')));
  });

  test('bundled GMacro iOS SDK excludes private MFi transport', () async {
    final sdkDirectory = Directory(
      'ios/Frameworks/GMacroProtocolSDK.xcframework',
    );
    final leakedFiles = <String>[];

    await for (final entity in sdkDirectory.list(recursive: true)) {
      if (entity is! File) {
        continue;
      }

      final content = String.fromCharCodes(
        await entity.readAsBytes(),
      ).toLowerCase();
      if (content.contains('mfi') ||
          content.contains('iap2') ||
          content.contains('externalaccessory')) {
        leakedFiles.add(entity.path);
      }
    }

    expect(leakedFiles, isEmpty, reason: leakedFiles.join('\n'));
  });
}
