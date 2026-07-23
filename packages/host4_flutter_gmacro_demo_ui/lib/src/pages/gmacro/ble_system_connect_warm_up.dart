import 'dart:async';

import 'package:host4_flutter_transport/host4_flutter_transport.dart';

Future<void> warmUpBleForSystemConnect({
  required bool isIOS,
  required DeviceDiscovery discovery,
  Duration duration = const Duration(milliseconds: 900),
}) async {
  if (!isIOS) return;

  final subscription = discovery
      .scan(const DeviceScanQuery(serviceIds: []))
      .listen((_) {});
  try {
    await Future<void>.delayed(duration);
  } finally {
    await subscription.cancel();
    await discovery.stop();
  }
}
