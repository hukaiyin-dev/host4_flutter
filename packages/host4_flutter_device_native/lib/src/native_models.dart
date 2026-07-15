enum NativeTransportKind { ble, mfi, usb }

enum NativeMfiAccessoryEventType { connected, disconnected, failed }

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

class NativeMfiAccessoryEvent {
  const NativeMfiAccessoryEvent({
    required this.type,
    required this.protocolString,
    this.name = '',
    this.metadata = const <String, Object?>{},
    this.failure,
  });

  factory NativeMfiAccessoryEvent.fromMap(Map<String, Object?> map) {
    final failureMap = map['failure'];
    return NativeMfiAccessoryEvent(
      type: _nativeMfiAccessoryEventTypeFromName(map['type'] as String?),
      protocolString: map['protocolString'] as String? ?? '',
      name: map['name'] as String? ?? '',
      metadata: Map<String, Object?>.from(
        map['metadata'] as Map? ?? const <String, Object?>{},
      ),
      failure: failureMap is Map
          ? NativeFailure.fromMap(Map<String, Object?>.from(failureMap))
          : null,
    );
  }

  final NativeMfiAccessoryEventType type;
  final String protocolString;
  final String name;
  final Map<String, Object?> metadata;
  final NativeFailure? failure;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'type': type.name,
      'protocolString': protocolString,
      'name': name,
      'metadata': metadata,
      'failure': failure?.toMap(),
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

enum NativeOtaUpgradeEventType { progress, success, failed }

/// Calibration / align progress from [DeviceAlignRsp] escalation callbacks.
class NativeDeviceAlignEvent {
  const NativeDeviceAlignEvent({
    required this.subId,
    required this.result,
    this.param1 = const <int>[],
    this.param2 = const <int>[],
  });

  factory NativeDeviceAlignEvent.fromMap(Map<String, Object?> map) {
    return NativeDeviceAlignEvent(
      subId: _readInt(map['subId']),
      result: _readInt(map['result']),
      param1: _readIntList(map['param1']),
      param2: _readIntList(map['param2']),
    );
  }

  /// Matches native calibration sub-ids (gyro `0x01`, rocker `0x02`, trigger `0x03`).
  final int subId;
  final int result;
  final List<int> param1;
  final List<int> param2;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'type': 'deviceAlign',
      'subId': subId,
      'result': result,
      'param1': param1,
      'param2': param2,
    };
  }

  @override
  String toString() {
    return 'NativeDeviceAlignEvent(subId: 0x${subId.toRadixString(16)}, '
        'result: $result, param1: $param1, param2: $param2)';
  }
}

/// Device key / test-mode input from [DPKeyEventRsp] escalation callbacks.
class NativeDpKeyEvent {
  const NativeDpKeyEvent({
    required this.keyValue,
    this.keys = const <int>[],
    this.leftRockerXValue = 0,
    this.leftRockerYValue = 0,
    this.rightRockerXValue = 0,
    this.rightRockerYValue = 0,
    this.leftKeyLTwoValue = 0,
    this.rightKeyRTwoValue = 0,
    this.leftRockerXOriginalValue = 0,
    this.leftRockerYOriginalValue = 0,
    this.rightRockerXOriginalValue = 0,
    this.rightRockerYOriginalValue = 0,
    this.leftKeyLTOriginalValue = 0,
    this.rightKeyRTOriginalValue = 0,
  });

  factory NativeDpKeyEvent.fromMap(Map<String, Object?> map) {
    final rawKeys = map['keys'];
    return NativeDpKeyEvent(
      keyValue: _readInt(map['keyValue']),
      keys: rawKeys is List
          ? rawKeys.map((value) => _readInt(value)).toList(growable: false)
          : const <int>[],
      leftRockerXValue: _readInt(map['leftRockerXValue']),
      leftRockerYValue: _readInt(map['leftRockerYValue']),
      rightRockerXValue: _readInt(map['rightRockerXValue']),
      rightRockerYValue: _readInt(map['rightRockerYValue']),
      leftKeyLTwoValue: _readInt(map['leftKeyLTwoValue']),
      rightKeyRTwoValue: _readInt(map['rightKeyRTwoValue']),
      leftRockerXOriginalValue: _readInt(map['leftRockerXOriginalValue']),
      leftRockerYOriginalValue: _readInt(map['leftRockerYOriginalValue']),
      rightRockerXOriginalValue: _readInt(map['rightRockerXOriginalValue']),
      rightRockerYOriginalValue: _readInt(map['rightRockerYOriginalValue']),
      leftKeyLTOriginalValue: _readInt(map['leftKeyLTOriginalValue']),
      rightKeyRTOriginalValue: _readInt(map['rightKeyRTOriginalValue']),
    );
  }

  final int keyValue;
  final List<int> keys;
  final int leftRockerXValue;
  final int leftRockerYValue;
  final int rightRockerXValue;
  final int rightRockerYValue;
  final int leftKeyLTwoValue;
  final int rightKeyRTwoValue;
  final int leftRockerXOriginalValue;
  final int leftRockerYOriginalValue;
  final int rightRockerXOriginalValue;
  final int rightRockerYOriginalValue;
  final int leftKeyLTOriginalValue;
  final int rightKeyRTOriginalValue;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'type': 'dpKeyEvent',
      'keyValue': keyValue,
      'keys': keys,
      'leftRockerXValue': leftRockerXValue,
      'leftRockerYValue': leftRockerYValue,
      'rightRockerXValue': rightRockerXValue,
      'rightRockerYValue': rightRockerYValue,
      'leftKeyLTwoValue': leftKeyLTwoValue,
      'rightKeyRTwoValue': rightKeyRTwoValue,
      'leftRockerXOriginalValue': leftRockerXOriginalValue,
      'leftRockerYOriginalValue': leftRockerYOriginalValue,
      'rightRockerXOriginalValue': rightRockerXOriginalValue,
      'rightRockerYOriginalValue': rightRockerYOriginalValue,
      'leftKeyLTOriginalValue': leftKeyLTOriginalValue,
      'rightKeyRTOriginalValue': rightKeyRTOriginalValue,
    };
  }

  @override
  String toString() {
    return 'NativeDpKeyEvent(keyValue: $keyValue, keys: $keys, '
        'LX: $leftRockerXValue, LY: $leftRockerYValue, '
        'RX: $rightRockerXValue, RY: $rightRockerYValue)';
  }
}

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

class NativeOtaUpgradeEvent {
  const NativeOtaUpgradeEvent({
    required this.type,
    this.progress = 0,
    this.total = 0,
    this.percent = 0,
    this.code,
  });

  factory NativeOtaUpgradeEvent.fromMap(Map<String, Object?> map) {
    return NativeOtaUpgradeEvent(
      type: _nativeOtaUpgradeEventTypeFromName(map['type'] as String?),
      progress: _readInt(map['progress']),
      total: _readInt(map['total']),
      percent: _readDouble(map['percent']),
      code: map['code'] == null ? null : _readInt(map['code']),
    );
  }

  final NativeOtaUpgradeEventType type;
  final int progress;
  final int total;
  final double percent;
  final int? code;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'type': type.name,
      'progress': progress,
      'total': total,
      'percent': percent,
      'code': code,
    };
  }
}

NativeTransportKind _nativeTransportKindFromName(String? value) {
  return NativeTransportKind.values.firstWhere(
    (kind) => kind.name == value,
    orElse: () => NativeTransportKind.ble,
  );
}

NativeMfiAccessoryEventType _nativeMfiAccessoryEventTypeFromName(
  String? value,
) {
  return NativeMfiAccessoryEventType.values.firstWhere(
    (eventType) => eventType.name == value,
    orElse: () => NativeMfiAccessoryEventType.failed,
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

NativeOtaUpgradeEventType _nativeOtaUpgradeEventTypeFromName(String? value) {
  return NativeOtaUpgradeEventType.values.firstWhere(
    (eventType) => eventType.name == value,
    orElse: () => NativeOtaUpgradeEventType.failed,
  );
}

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return 0;
}

double _readDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return 0;
}

List<int> _readIntList(Object? value) {
  if (value is! List) {
    return const <int>[];
  }
  return value.map((item) => _readInt(item)).toList(growable: false);
}
