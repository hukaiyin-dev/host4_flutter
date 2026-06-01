import 'package:host4_flutter_device_native/host4_flutter_device_native.dart';
import 'package:host4_flutter_transport/host4_flutter_transport.dart';

class Host4Usb {
  Host4Usb({Host4FlutterDeviceNative? native})
    : _native = native ?? Host4FlutterDeviceNative();

  final Host4FlutterDeviceNative _native;

  bool get isImplemented => true;

  DeviceDiscovery discovery() => Host4UsbDiscovery(_native);

  /// Starts the SDK USB host stack ([UsbDeviceSessionHandle.init]) and opens a
  /// transport session. Permission and plug/unplug are handled inside the JAR.
  Future<TransportSession> connectAuto({
    Map<String, Object?> options = const <String, Object?>{},
  }) async {
    final sessionId = await _native.connectUsb(options: options);
    return Host4UsbTransportSession(
      id: sessionId,
      device: const DeviceDescriptor(
        id: 'usb-auto',
        name: 'USB Device',
        kind: TransportKind.usb,
      ),
      native: _native,
    );
  }

  Future<TransportSession> connect(
    DeviceDescriptor device, {
    Map<String, Object?> options = const <String, Object?>{},
  }) async {
    final sessionId = await _native.connectUsb(
      deviceId: device.id,
      options: options,
    );
    return Host4UsbTransportSession(
      id: sessionId,
      device: device,
      native: _native,
    );
  }

  Future<void> reconnect() => _native.reconnectUsb();

  Future<void> release() => _native.releaseUsb();
}

class Host4UsbDiscovery implements DeviceDiscovery {
  Host4UsbDiscovery(this._native);

  final Host4FlutterDeviceNative _native;

  @override
  Stream<DeviceDescriptor> scan(DeviceScanQuery query) {
    return _native.scanUsb(hints: query.hints).map(_mapDevice);
  }

  @override
  Future<void> stop() {
    return _native.stopUsbScan();
  }

  DeviceDescriptor _mapDevice(NativeDiscoveredDevice device) {
    return DeviceDescriptor(
      id: device.deviceId,
      name: device.name,
      kind: TransportKind.usb,
      metadata: device.metadata,
    );
  }
}

class Host4UsbTransportSession implements TransportSession {
  Host4UsbTransportSession({
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
