import 'device_descriptor.dart';
import 'transport_event.dart';

abstract class TransportSession {
  String get id;

  DeviceDescriptor get device;

  Stream<TransportEvent> get events;

  Future<void> disconnect();
}
