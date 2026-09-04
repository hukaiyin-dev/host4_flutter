class Host4WebEmulatorBridgeMessage {
  const Host4WebEmulatorBridgeMessage({
    required this.type,
    required this.requestId,
    required this.ok,
    this.data,
    this.error,
  });

  factory Host4WebEmulatorBridgeMessage.fromPayload(Object? payload) {
    if (payload is! Map) {
      throw const FormatException('Web emulator bridge payload must be a map.');
    }
    final type = payload['type'];
    final requestId = payload['requestId'];
    final ok = payload['ok'];
    if (type is! String || requestId is! String || ok is! bool) {
      throw const FormatException('Invalid web emulator bridge envelope.');
    }
    return Host4WebEmulatorBridgeMessage(
      type: type,
      requestId: requestId,
      ok: ok,
      data: payload['data'],
      error: payload['error'],
    );
  }

  factory Host4WebEmulatorBridgeMessage.success({
    required String type,
    required String requestId,
    Object? data,
  }) {
    return Host4WebEmulatorBridgeMessage(
      type: type,
      requestId: requestId,
      ok: true,
      data: data,
    );
  }

  factory Host4WebEmulatorBridgeMessage.failure({
    required String type,
    required String requestId,
    required Object error,
  }) {
    return Host4WebEmulatorBridgeMessage(
      type: type,
      requestId: requestId,
      ok: false,
      error: error,
    );
  }

  final String type;
  final String requestId;
  final bool ok;
  final Object? data;
  final Object? error;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'type': type,
      'requestId': requestId,
      'ok': ok,
      'data': data,
      'error': error,
    };
  }
}
