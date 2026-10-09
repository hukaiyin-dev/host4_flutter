import 'package:host4_flutter_device_native/host4_flutter_device_native.dart';
import 'package:host4_flutter_transport/host4_flutter_transport.dart';

class Host4Uart {
  Host4Uart({Host4FlutterDeviceNative? native})
    : _native = native ?? Host4FlutterDeviceNative();

  final Host4FlutterDeviceNative _native;

  static const String deviceId = '__uart__';

  /// Binds the in-app DeviceBroker and returns a transport session.
  ///
  /// Ready / disconnected / recovering / error come from the broker. This
  /// method does not fabricate a connected session.
  Future<TransportSession> connect({
    Map<String, Object?> options = const <String, Object?>{},
  }) async {
    final sessionId = await _native.connectUart(options: options);
    return Host4UartTransportSession(
      id: sessionId,
      device: const DeviceDescriptor(
        id: deviceId,
        name: 'UART Device',
        kind: TransportKind.uart,
      ),
      native: _native,
    );
  }
}

class Host4UartTransportSession implements TransportSession {
  Host4UartTransportSession({
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

  Stream<NativeDpKeyEvent> get dpKeyEvents => _native.usbDpKeyEvents(id);

  Stream<NativeDeviceAlignEvent> get calibrationEvents =>
      _native.deviceAlignEvents(id);

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
      case NativeTransportEventType.recovering:
        return TransportRecovering(cause: failure);
      case NativeTransportEventType.error:
        return TransportError(
          failure ??
              const TransportFailure(
                code: 'native-transport-error',
                message: 'Native UART transport reported an unspecified error.',
              ),
        );
    }
  }
}
