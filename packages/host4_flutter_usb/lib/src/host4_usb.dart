import 'package:host4_flutter_transport/host4_flutter_transport.dart';

class Host4Usb {
  const Host4Usb();

  bool get isImplemented => false;

  String get pendingReason =>
      'USB is reserved for a later phase after the native transport API is defined.';

  DeviceDiscovery discovery() {
    throw UnsupportedError(pendingReason);
  }

  Future<TransportSession> connect(
    DeviceDescriptor device, {
    Map<String, Object?> options = const <String, Object?>{},
  }) {
    return Future<TransportSession>.error(UnsupportedError(pendingReason));
  }
}
