import 'package:flutter/foundation.dart';
import 'package:host4_flutter_device_native/host4_flutter_device_native.dart';
import 'package:host4_flutter_transport/host4_flutter_transport.dart';

class Host4Ble {
  Host4Ble({Host4FlutterDeviceNative? native})
    : _native = native ?? Host4FlutterDeviceNative();

  final Host4FlutterDeviceNative _native;

  DeviceDiscovery discovery() => Host4BleDiscovery(_native);

  Future<List<DeviceDescriptor>> systemConnectedDevices(
    List<String> serviceIds,
  ) async {
    final devices = await _native.getSystemConnectedBleDevices(
      serviceIds: serviceIds,
    );
    return devices
        .map(
          (device) => DeviceDescriptor(
            id: device.deviceId,
            name: device.name,
            kind: TransportKind.ble,
            metadata: device.metadata,
          ),
        )
        .toList(growable: false);
  }

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
    // The legacy name-based native API returns only a transport session ID.
    // Resolve the actual peripheral first on iOS so callers never receive a
    // fabricated device ID when several system-connected devices are present.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      final devices = await systemConnectedDevices(serviceIds);
      for (final device in devices) {
        if (deviceNames.isEmpty ||
            deviceNames.any((name) => device.name.contains(name))) {
          return connectSystemConnectedDevice(
            device,
            serviceIds: serviceIds,
            options: options,
          );
        }
      }
      throw StateError('No system-connected BLE device matched $deviceNames.');
    }

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

  /// Connects the exact system-connected BLE device selected from [systemConnectedDevices].
  Future<TransportSession> connectSystemConnectedDevice(
    DeviceDescriptor device, {
    required List<String> serviceIds,
    Map<String, Object?> options = const <String, Object?>{},
  }) async {
    if (device.kind != TransportKind.ble || device.id.isEmpty) {
      throw ArgumentError.value(
        device,
        'device',
        'A BLE device ID is required.',
      );
    }
    final sessionId = await _native.connectSystemConnectedBle(
      serviceIds: serviceIds,
      deviceId: device.id,
      options: options,
    );
    return Host4BleTransportSession(
      id: sessionId,
      device: device,
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

  Stream<NativeDeviceAlignEvent> get calibrationEvents =>
      _native.deviceAlignEvents(id);

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
      case NativeTransportEventType.recovering:
        return TransportRecovering(cause: failure);
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
