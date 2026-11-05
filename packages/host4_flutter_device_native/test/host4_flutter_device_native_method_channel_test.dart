import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_device_native/host4_flutter_device_native_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelHost4FlutterDeviceNative platform =
      MethodChannelHost4FlutterDeviceNative();
  const MethodChannel channel = MethodChannel('host4_flutter_device_native');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return '42';
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });

  test('connectUart returns native uart session id', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          expect(methodCall.method, 'connectUart');
          return 'uart-session-1';
        });

    expect(await platform.connectUart(), 'uart-session-1');
  });

  test('getSystemConnectedBleDevices returns every native device', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          expect(methodCall.method, 'getSystemConnectedBleDevices');
          expect(methodCall.arguments, <String, Object?>{
            'serviceIds': <String>['FF00', 'FF10'],
          });
          return <Object?>[
            <String, Object?>{
              'deviceId': 'device-a',
              'name': 'Controller A',
              'kind': 'ble',
              'metadata': <String, Object?>{
                'systemConnected': true,
                'serviceIds': <String>['FF00', 'FF10'],
              },
            },
            <String, Object?>{
              'deviceId': 'device-b',
              'name': 'Controller B',
              'kind': 'ble',
              'metadata': <String, Object?>{
                'systemConnected': true,
                'serviceIds': <String>['FF00', 'FF10'],
              },
            },
          ];
        });

    final devices = await platform.getSystemConnectedBleDevices(
      serviceIds: const <String>['FF00', 'FF10'],
    );

    expect(devices, hasLength(2));
    expect(devices.first.deviceId, 'device-a');
    expect(devices.first.name, 'Controller A');
    expect(devices.first.metadata['systemConnected'], isTrue);
    expect(devices.last.deviceId, 'device-b');
  });

  test('connectSystemConnectedBle forwards selected device ID', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          expect(call.method, 'connectSystemConnectedBle');
          expect(call.arguments, <String, Object?>{
            'serviceIds': <String>['FF00', 'FF10'],
            'deviceNames': <String>[],
            'deviceId': 'device-b',
            'options': <String, Object?>{},
          });
          return 'transport-b';
        });

    final sessionId = await platform.connectSystemConnectedBle(
      serviceIds: const <String>['FF00', 'FF10'],
      deviceId: 'device-b',
    );

    expect(sessionId, 'transport-b');
  });
}
