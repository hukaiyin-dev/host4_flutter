import 'transport_failure.dart';

sealed class TransportEvent {
  const TransportEvent();
}

class TransportConnecting extends TransportEvent {
  const TransportConnecting();
}

class TransportConnected extends TransportEvent {
  const TransportConnected();
}

class TransportReady extends TransportEvent {
  const TransportReady();
}

class TransportDisconnected extends TransportEvent {
  const TransportDisconnected({this.cause});

  final TransportFailure? cause;
}

class TransportError extends TransportEvent {
  const TransportError(this.failure);

  final TransportFailure failure;
}
