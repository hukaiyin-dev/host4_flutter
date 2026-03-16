import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_bridge/host4_flutter_bridge.dart';
import 'package:host4_flutter_bridge/host4_flutter_bridge_platform_interface.dart';
import 'package:host4_flutter_bridge/host4_flutter_bridge_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockHost4FlutterBridgePlatform
    with MockPlatformInterfaceMixin
    implements Host4FlutterBridgePlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final Host4FlutterBridgePlatform initialPlatform = Host4FlutterBridgePlatform.instance;

  test('$MethodChannelHost4FlutterBridge is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelHost4FlutterBridge>());
  });

  test('getPlatformVersion', () async {
    Host4FlutterBridge host4FlutterBridgePlugin = Host4FlutterBridge();
    MockHost4FlutterBridgePlatform fakePlatform = MockHost4FlutterBridgePlatform();
    Host4FlutterBridgePlatform.instance = fakePlatform;

    expect(await host4FlutterBridgePlugin.getPlatformVersion(), '42');
  });
}
