import 'protocol_failure.dart';

sealed class ProtocolEvent {
  const ProtocolEvent();
}

class ProtocolReady extends ProtocolEvent {
  const ProtocolReady();
}

class ProtocolBusy extends ProtocolEvent {
  const ProtocolBusy(
    this.reason, {
    this.payload = const <String, Object?>{},
  });

  final String reason;
  final Map<String, Object?> payload;
}

class ProtocolError extends ProtocolEvent {
  const ProtocolError(this.failure);

  final ProtocolFailure failure;
}
