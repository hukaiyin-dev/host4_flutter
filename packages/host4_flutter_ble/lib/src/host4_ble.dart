import 'package:host4_flutter_device_native/host4_flutter_device_native.dart';
import 'package:host4_flutter_transport/host4_flutter_transport.dart';

class Host4Ble {
  Host4Ble({Host4FlutterDeviceNative? native})
    : _native = native ?? Host4FlutterDeviceNative();

  final Host4FlutterDeviceNative _native;

  DeviceDiscovery discovery() => Host4BleDiscovery(_native);

  Future<TransportSession> connect(
    DeviceDescriptor device, {
    Map<String, Object?> options = const <String, Object?>{},
  }) async {
    final sessionId = await _native.connectBle(
      deviceId: device.id,
      options: options,
    );
    return Host4BleTransportSession(
      id: sessionId,
      device: device,
      native: _native,
    );
  }

  Future<TransportSession> connectSystemConnected(
    List<String> serviceIds, {
    List<String> deviceNames = const [],
    Map<String, Object?> options = const <String, Object?>{},
  }) async {
    final sessionId = await _native.connectSystemConnectedBle(
      serviceIds: serviceIds,
      deviceNames: deviceNames,
      options: options,
    );

    return Host4BleTransportSession(
      id: sessionId,
      device: DeviceDescriptor(
        id: 'system-connected',
        name: deviceNames.isNotEmpty
            ? deviceNames.first
            : 'System Connected BLE',
        kind: TransportKind.ble,
        metadata: <String, Object?>{'serviceIds': serviceIds},
      ),
      native: _native,
    );
  }
}

class Host4BleDiscovery implements DeviceDiscovery {
  Host4BleDiscovery(this._native);

  final Host4FlutterDeviceNative _native;

  @override
  Stream<DeviceDescriptor> scan(DeviceScanQuery query) {
    return _native
        .scanBle(serviceIds: query.serviceIds, hints: query.hints)
        .map(_mapDevice);
  }

  @override
  Future<void> stop() {
    return _native.stopBleScan();
  }

  DeviceDescriptor _mapDevice(NativeDiscoveredDevice device) {
    return DeviceDescriptor(
      id: device.deviceId,
      name: device.name,
      kind: TransportKind.ble,
      metadata: device.metadata,
    );
  }
}

class Host4BleTransportSession implements TransportSession {
  Host4BleTransportSession({
    required this.id,
    required this.device,
    required Host4FlutterDeviceNative native,
  }) : _native = native;

  final Host4FlutterDeviceNative _native;

  @override
  final DeviceDescriptor device;

  @override
  final String id;

  @override
  Stream<TransportEvent> get events {
    return _native.transportEvents(id).map(_mapTransportEvent);
  }

  @override
  Future<void> disconnect() {
    return _native.disconnectTransport(id);
  }

  TransportEvent _mapTransportEvent(NativeTransportEvent event) {
    final failure = event.failure == null
        ? null
        : TransportFailure(
            code: event.failure!.code,
            message: event.failure!.message,
            details: event.failure!.details,
          );

    switch (event.type) {
      case NativeTransportEventType.connecting:
        return const TransportConnecting();
      case NativeTransportEventType.connected:
        return const TransportConnected();
      case NativeTransportEventType.ready:
        return const TransportReady();
      case NativeTransportEventType.disconnected:
        return TransportDisconnected(cause: failure);
      case NativeTransportEventType.error:
        return TransportError(
          failure ??
              const TransportFailure(
                code: 'native-transport-error',
                message: 'Native transport reported an unspecified error.',
              ),
        );
    }
  }
}
