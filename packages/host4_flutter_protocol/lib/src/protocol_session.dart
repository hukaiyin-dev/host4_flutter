import 'package:host4_flutter_transport/host4_flutter_transport.dart';

import 'protocol_event.dart';

abstract class ProtocolSession {
  String get id;

  String get protocolName;

  TransportSession get transport;

  Stream<ProtocolEvent> get events;

  Future<void> close();
}
