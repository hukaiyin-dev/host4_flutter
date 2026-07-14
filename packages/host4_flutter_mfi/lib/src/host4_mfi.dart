import 'package:host4_flutter_device_native/host4_flutter_device_native.dart';
import 'package:host4_flutter_transport/host4_flutter_transport.dart';

class Host4Mfi {
  Host4Mfi({Host4FlutterDeviceNative? native})
    : _native = native ?? Host4FlutterDeviceNative();

  final Host4FlutterDeviceNative _native;
  String? _protocolString;
  Host4MfiTransportSession? _activeSession;

  bool get isImplemented => true;

  Future<bool> start() async {
    return true;
  }

  Future<bool> updateProtocol(String protocolString) async {
    if (protocolString.trim().isEmpty) {
      throw ArgumentError.value(
        protocolString,
        'protocolString',
        'MFi protocol string must not be empty.',
      );
    }
    _protocolString = protocolString;
    return true;
  }

  Future<bool> isAccessoryConnected({String? protocolString}) {
    final resolvedProtocol = protocolString ?? _protocolString;
    if (resolvedProtocol == null || resolvedProtocol.isEmpty) {
      throw StateError(
        'Call updateProtocol(protocolString) or pass protocolString first.',
      );
    }
    return _native.isMfiAccessoryConnected(protocolString: resolvedProtocol);
  }

  Stream<MfiAccessoryEvent> get accessoryEvents {
    final resolvedProtocol = _protocolString;
    if (resolvedProtocol == null || resolvedProtocol.isEmpty) {
      throw StateError('Call updateProtocol(protocolString) first.');
    }
    return _native
        .mfiAccessoryEvents(protocolString: resolvedProtocol)
        .map(MfiAccessoryEvent.fromNative);
  }

  Future<Host4MfiTransportSession> connect({
    String? protocolString,
    Map<String, Object?> options = const <String, Object?>{},
  }) async {
    final resolvedProtocol = protocolString ?? _protocolString;
    if (resolvedProtocol == null || resolvedProtocol.isEmpty) {
      throw StateError(
        'Call updateProtocol(protocolString) or pass protocolString first.',
      );
    }

    _protocolString = resolvedProtocol;
    final sessionId = await _native.connectMfi(
      protocolString: resolvedProtocol,
      options: options,
    );
    final session = Host4MfiTransportSession(
      id: sessionId,
      device: DeviceDescriptor(
        id: sessionId,
        name: 'MFi Accessory',
        kind: TransportKind.mfi,
        metadata: <String, Object?>{'protocolString': resolvedProtocol},
      ),
      native: _native,
    );
    _activeSession = session;
    return session;
  }

  Future<bool> disconnect() async {
    final session = _activeSession;
    if (session == null) {
      return true;
    }
    await session.disconnect();
    _activeSession = null;
    return true;
  }

  Stream<TransportEvent> get events {
    final session = _activeSession;
    if (session == null) {
      return const Stream<TransportEvent>.empty();
    }
    return session.events;
  }
}

enum MfiAccessoryEventType { connected, disconnected, failed }

class MfiAccessoryEvent {
  const MfiAccessoryEvent({
    required this.type,
    required this.protocolString,
    this.name = '',
    this.metadata = const <String, Object?>{},
    this.failure,
  });

  factory MfiAccessoryEvent.fromNative(NativeMfiAccessoryEvent event) {
    return MfiAccessoryEvent(
      type: switch (event.type) {
        NativeMfiAccessoryEventType.connected =>
          MfiAccessoryEventType.connected,
        NativeMfiAccessoryEventType.disconnected =>
          MfiAccessoryEventType.disconnected,
        NativeMfiAccessoryEventType.failed => MfiAccessoryEventType.failed,
      },
      protocolString: event.protocolString,
      name: event.name,
      metadata: event.metadata,
      failure: event.failure == null
          ? null
          : TransportFailure(
              code: event.failure!.code,
              message: event.failure!.message,
              details: event.failure!.details,
            ),
    );
  }

  final MfiAccessoryEventType type;
  final String protocolString;
  final String name;
  final Map<String, Object?> metadata;
  final TransportFailure? failure;
}

class Host4MfiTransportSession implements TransportSession {
  Host4MfiTransportSession({
    required this.id,
    required this.device,
    required Host4FlutterDeviceNative native,
  }) : _native = native;

  final Host4FlutterDeviceNative _native;

  @override
  final String id;

  @override
  final DeviceDescriptor device;

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
                message: 'Native MFi transport reported an unspecified error.',
              ),
        );
    }
  }
}
