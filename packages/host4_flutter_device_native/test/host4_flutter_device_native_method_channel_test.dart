import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_device_native/src/native_models.dart';
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

  test('connectMfi is unsupported without calling native channel', () async {
    var nativeCallCount = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          nativeCallCount += 1;
          return 'unexpected';
        });

    await expectLater(
      platform.connectMfi(protocolString: 'customer.protocol'),
      throwsA(
        isA<PlatformException>().having(
          (error) => error.code,
          'code',
          'mfi-unsupported',
        ),
      ),
    );
    expect(nativeCallCount, isZero);
  });

  test(
    'isMfiAccessoryConnected returns false without native channel',
    () async {
      var nativeCallCount = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            nativeCallCount += 1;
            return true;
          });

      expect(
        await platform.isMfiAccessoryConnected(
          protocolString: 'customer.protocol',
        ),
        isFalse,
      );
      expect(nativeCallCount, isZero);
    },
  );

  test('mfiAccessoryEvents is empty without native event subscription', () {
    expect(
      platform.mfiAccessoryEvents(protocolString: 'customer.protocol'),
      emitsDone,
    );
  });
}
