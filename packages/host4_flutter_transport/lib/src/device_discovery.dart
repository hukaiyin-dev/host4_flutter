import 'device_descriptor.dart';
import 'device_scan_query.dart';

abstract class DeviceDiscovery {
  Stream<DeviceDescriptor> scan(DeviceScanQuery query);

  Future<void> stop();
}
