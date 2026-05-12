enum NativeTransportKind { ble, mfi, usb }

class NativeFailure {
  const NativeFailure({
    required this.code,
    required this.message,
    this.details = const <String, Object?>{},
  });

  factory NativeFailure.fromMap(Map<String, Object?> map) {
    return NativeFailure(
      code: map['code'] as String? ?? 'unknown',
      message: map['message'] as String? ?? 'Unknown native failure.',
      details: Map<String, Object?>.from(
        map['details'] as Map? ?? const <String, Object?>{},
      ),
    );
  }

  final String code;
  final String message;
  final Map<String, Object?> details;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'code': code,
      'message': message,
      'details': details,
    };
  }
}

class NativeDiscoveredDevice {
  const NativeDiscoveredDevice({
    required this.deviceId,
    required this.name,
    required this.kind,
    this.metadata = const <String, Object?>{},
  });

  factory NativeDiscoveredDevice.fromMap(Map<String, Object?> map) {
    return NativeDiscoveredDevice(
      deviceId: map['deviceId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      kind: _nativeTransportKindFromName(map['kind'] as String?),
      metadata: Map<String, Object?>.from(
        map['metadata'] as Map? ?? const <String, Object?>{},
      ),
    );
  }

  final String deviceId;
  final String name;
  final NativeTransportKind kind;
  final Map<String, Object?> metadata;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'deviceId': deviceId,
      'name': name,
      'kind': kind.name,
      'metadata': metadata,
    };
  }
}

enum NativeTransportEventType {
  connecting,
  connected,
  ready,
  disconnected,
  error,
}

class NativeTransportEvent {
  const NativeTransportEvent({required this.type, this.failure});

  factory NativeTransportEvent.fromMap(Map<String, Object?> map) {
    final failureMap = map['failure'];
    return NativeTransportEvent(
      type: _nativeTransportEventTypeFromName(map['type'] as String?),
      failure: failureMap is Map
          ? NativeFailure.fromMap(Map<String, Object?>.from(failureMap))
          : null,
    );
  }

  final NativeTransportEventType type;
  final NativeFailure? failure;

  Map<String, Object?> toMap() {
    return <String, Object?>{'type': type.name, 'failure': failure?.toMap()};
  }
}

enum NativeProtocolEventType { ready, busy, error }

class NativeProtocolEvent {
  const NativeProtocolEvent({
    required this.type,
    this.reason,
    this.failure,
    this.payload = const <String, Object?>{},
  });

  factory NativeProtocolEvent.fromMap(Map<String, Object?> map) {
    final failureMap = map['failure'];
    return NativeProtocolEvent(
      type: _nativeProtocolEventTypeFromName(map['type'] as String?),
      reason: map['reason'] as String?,
      failure: failureMap is Map
          ? NativeFailure.fromMap(Map<String, Object?>.from(failureMap))
          : null,
      payload: Map<String, Object?>.from(
        map['payload'] as Map? ?? const <String, Object?>{},
      ),
    );
  }

  final NativeProtocolEventType type;
  final String? reason;
  final NativeFailure? failure;
  final Map<String, Object?> payload;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'type': type.name,
      'reason': reason,
      'failure': failure?.toMap(),
      'payload': payload,
    };
  }
}

NativeTransportKind _nativeTransportKindFromName(String? value) {
  return NativeTransportKind.values.firstWhere(
    (kind) => kind.name == value,
    orElse: () => NativeTransportKind.ble,
  );
}

NativeTransportEventType _nativeTransportEventTypeFromName(String? value) {
  return NativeTransportEventType.values.firstWhere(
    (eventType) => eventType.name == value,
    orElse: () => NativeTransportEventType.error,
  );
}

NativeProtocolEventType _nativeProtocolEventTypeFromName(String? value) {
  return NativeProtocolEventType.values.firstWhere(
    (eventType) => eventType.name == value,
    orElse: () => NativeProtocolEventType.error,
  );
}
