import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_gmacro_demo_ui/host4_flutter_gmacro_demo_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('host4_flutter_device_native');
  String? connectedDeviceId;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    connectedDeviceId = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getSystemConnectedBleDevices') {
            expect(call.arguments, <String, Object?>{
              'serviceIds': <String>['FF00', 'FF10'],
            });
            return <Object?>[
              <String, Object?>{
                'deviceId': '11:22:33:44:55:66',
                'name': 'GameMacro',
                'kind': 'ble',
                'metadata': <String, Object?>{'systemConnected': true},
              },
              <String, Object?>{
                'deviceId': 'AA:BB:CC:DD:EE:FF',
                'name': 'Connected controller',
                'kind': 'ble',
                'metadata': <String, Object?>{'systemConnected': true},
              },
            ];
          }
          if (call.method == 'connectSystemConnectedBle') {
            final arguments = call.arguments as Map;
            expect(arguments['serviceIds'], <String>['FF00', 'FF10']);
            expect(arguments['deviceNames'], isEmpty);
            expect(arguments['options'], <String, Object?>{
              'protocolType': 'gmacro',
            });
            connectedDeviceId = arguments['deviceId'] as String;
            throw PlatformException(code: 'test-connect-failed');
          }
          throw PlatformException(
            code: 'unexpected-call',
            message: call.method,
          );
        });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('connects the selected system-connected BLE device', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GmacroBleScanPage()));

    await tester.tap(find.text('选择已连接设备'));
    await tester.pumpAndSettle();
    expect(find.text('Connected controller'), findsOneWidget);
    expect(find.text('AA:BB:CC:DD:EE:FF'), findsOneWidget);

    await tester.tap(find.text('Connected controller'));
    await tester.pumpAndSettle();
    expect(connectedDeviceId, 'AA:BB:CC:DD:EE:FF');
    expect(find.textContaining('连接失败'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });
}
