import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_gmacro_demo_ui/host4_flutter_gmacro_demo_ui.dart';
import 'package:host4_flutter_transport/host4_flutter_transport.dart';

void main() {
  test('warms up BLE discovery before iOS system-connected connect', () async {
    final discovery = _FakeDiscovery();

    await warmUpBleForSystemConnect(
      isIOS: true,
      discovery: discovery,
      duration: Duration.zero,
    );

    expect(discovery.scanCount, 1);
    expect(discovery.lastQuery?.serviceIds, isEmpty);
    expect(discovery.stopCount, 1);
    expect(discovery.cancelled, isTrue);
  });

  test('skips warm-up outside iOS', () async {
    final discovery = _FakeDiscovery();

    await warmUpBleForSystemConnect(
      isIOS: false,
      discovery: discovery,
      duration: Duration.zero,
    );

    expect(discovery.scanCount, 0);
    expect(discovery.stopCount, 0);
  });
}

class _FakeDiscovery implements DeviceDiscovery {
  int scanCount = 0;
  int stopCount = 0;
  bool cancelled = false;
  DeviceScanQuery? lastQuery;

  @override
  Stream<DeviceDescriptor> scan(DeviceScanQuery query) {
    scanCount += 1;
    lastQuery = query;
    return Stream<DeviceDescriptor>.empty().transform(
      StreamTransformer.fromHandlers(
        handleDone: (sink) {
          cancelled = true;
          sink.close();
        },
      ),
    );
  }

  @override
  Future<void> stop() async {
    stopCount += 1;
  }
}
