import 'package:host4_flutter_transport/host4_flutter_transport.dart';

class Host4Mfi {
  const Host4Mfi();

  bool get isImplemented => false;

  String get pendingReason =>
      'MFi is reserved for a later phase after the native runtime is unified.';

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
