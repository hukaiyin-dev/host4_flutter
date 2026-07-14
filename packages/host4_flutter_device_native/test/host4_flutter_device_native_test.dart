import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_device_native/host4_flutter_device_native.dart';
import 'package:host4_flutter_device_native/host4_flutter_device_native_platform_interface.dart';
import 'package:host4_flutter_device_native/host4_flutter_device_native_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockHost4FlutterDeviceNativePlatform
    with MockPlatformInterfaceMixin
    implements Host4FlutterDeviceNativePlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<String> attachGmacroProtocol(
    String transportSessionId, {
    Map<String, Object?> options = const {},
  }) async {
    return 'protocol-1';
  }

  @override
  Future<void> closeProtocol(String protocolSessionId) async {}

  @override
  Future<String> connectBle({
    required String deviceId,
    Map<String, Object?> options = const {},
  }) async {
    return 'transport-1';
  }

  @override
  Future<String> connectUsb({
    String? deviceId,
    Map<String, Object?> options = const {},
  }) async {
    return 'transport-usb-1';
  }

  @override
  Future<String> connectSystemConnectedBle({
    required List<String> serviceIds,
    List<String> deviceNames = const [],
    Map<String, Object?> options = const {},
  }) async {
    return 'transport-system-1';
  }

  @override
  Future<String> connectMfi({
    required String protocolString,
    Map<String, Object?> options = const {},
  }) async {
    return 'transport-mfi-1';
  }

  @override
  Future<bool> isMfiAccessoryConnected({required String protocolString}) async {
    return protocolString == 'customer.protocol';
  }

  @override
  Stream<NativeMfiAccessoryEvent> mfiAccessoryEvents({
    required String protocolString,
  }) {
    return Stream<NativeMfiAccessoryEvent>.value(
      NativeMfiAccessoryEvent(
        type: NativeMfiAccessoryEventType.connected,
        protocolString: protocolString,
        name: 'MFi Pad',
        metadata: const <String, Object?>{'serialNumber': 'SN-1'},
      ),
    );
  }

  @override
  Future<void> disconnectTransport(String transportSessionId) async {}

  @override
  Future<Map<String, Object?>> invokeGmacroMethod({
    required String protocolSessionId,
    required String method,
    Map<String, Object?> arguments = const {},
  }) async {
    return <String, Object?>{};
  }

  @override
  Stream<NativeProtocolEvent> protocolEvents(String protocolSessionId) {
    return const Stream<NativeProtocolEvent>.empty();
  }

  @override
  Stream<NativeOtaUpgradeEvent> otaUpgradeEvents(String protocolSessionId) {
    return const Stream<NativeOtaUpgradeEvent>.empty();
  }

  @override
  Stream<NativeDiscoveredDevice> scanBle({
    List<String> serviceIds = const [],
    Map<String, Object?> hints = const {},
  }) {
    return const Stream<NativeDiscoveredDevice>.empty();
  }

  @override
  Future<void> stopBleScan() async {}

  @override
  Stream<NativeDiscoveredDevice> scanUsb({
    Map<String, Object?> hints = const {},
  }) {
    return const Stream<NativeDiscoveredDevice>.empty();
  }

  @override
  Future<void> stopUsbScan() async {}

  @override
  Future<void> reconnectUsb() async {}

  @override
  Future<void> releaseUsb() async {}

  @override
  Stream<NativeTransportEvent> transportEvents(String transportSessionId) {
    return const Stream<NativeTransportEvent>.empty();
  }

  @override
  Stream<NativeDpKeyEvent> usbDpKeyEvents(String transportSessionId) {
    return const Stream<NativeDpKeyEvent>.empty();
  }

  @override
  Stream<NativeDeviceAlignEvent> deviceAlignEvents(String transportSessionId) {
    return const Stream<NativeDeviceAlignEvent>.empty();
  }

  @override
  Stream<Map<String, Object?>> transportEscalationEvents(
    String transportSessionId,
  ) {
    return const Stream<Map<String, Object?>>.empty();
  }

  @override
  Future<void> startOta({
    required String protocolSessionId,
    required Uint8List firmwareData,
  }) async {}

  @override
  Future<bool> ensureBleScanPermissions() async => true;
}

void main() {
  final Host4FlutterDeviceNativePlatform initialPlatform =
      Host4FlutterDeviceNativePlatform.instance;

  test('$MethodChannelHost4FlutterDeviceNative is the default instance', () {
    expect(
      initialPlatform,
      isInstanceOf<MethodChannelHost4FlutterDeviceNative>(),
    );
  });

  test('getPlatformVersion', () async {
    Host4FlutterDeviceNative host4FlutterDeviceNativePlugin =
        Host4FlutterDeviceNative();
    MockHost4FlutterDeviceNativePlatform fakePlatform =
        MockHost4FlutterDeviceNativePlatform();
    Host4FlutterDeviceNativePlatform.instance = fakePlatform;

    expect(await host4FlutterDeviceNativePlugin.getPlatformVersion(), '42');
  });

  test('connectMfi returns native MFi transport session id', () async {
    final plugin = Host4FlutterDeviceNative();
    final fakePlatform = MockHost4FlutterDeviceNativePlatform();
    Host4FlutterDeviceNativePlatform.instance = fakePlatform;

    expect(
      await plugin.connectMfi(protocolString: 'customer.protocol'),
      'transport-mfi-1',
    );
  });

  test('isMfiAccessoryConnected forwards protocol string', () async {
    final plugin = Host4FlutterDeviceNative();
    final fakePlatform = MockHost4FlutterDeviceNativePlatform();
    Host4FlutterDeviceNativePlatform.instance = fakePlatform;

    expect(
      await plugin.isMfiAccessoryConnected(protocolString: 'customer.protocol'),
      isTrue,
    );
  });

  test('mfiAccessoryEvents forwards protocol string and maps events', () async {
    final plugin = Host4FlutterDeviceNative();
    final fakePlatform = MockHost4FlutterDeviceNativePlatform();
    Host4FlutterDeviceNativePlatform.instance = fakePlatform;

    final event = await plugin
        .mfiAccessoryEvents(protocolString: 'customer.protocol')
        .first;

    expect(event.type, NativeMfiAccessoryEventType.connected);
    expect(event.protocolString, 'customer.protocol');
    expect(event.name, 'MFi Pad');
    expect(event.metadata['serialNumber'], 'SN-1');
  });
}
