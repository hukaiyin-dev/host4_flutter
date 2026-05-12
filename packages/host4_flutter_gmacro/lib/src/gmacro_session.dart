import 'package:host4_flutter_device_native/host4_flutter_device_native.dart';
import 'package:host4_flutter_protocol/host4_flutter_protocol.dart';
import 'package:host4_flutter_transport/host4_flutter_transport.dart';

class GmacroSession implements ProtocolSession {
  GmacroSession({
    required this.id,
    required this.transport,
    required Host4FlutterDeviceNative native,
  }) : _native = native;

  final Host4FlutterDeviceNative _native;

  @override
  final String id;

  @override
  String get protocolName => 'gmacro';

  @override
  final TransportSession transport;

  @override
  Stream<ProtocolEvent> get events {
    return _native.protocolEvents(id).map(_mapProtocolEvent);
  }

  @override
  Future<void> close() {
    return _native.closeProtocol(id);
  }

  Future<Map<String, Object?>> invoke(
    String method, {
    Map<String, Object?> arguments = const <String, Object?>{},
  }) {
    return _native.invokeGmacroMethod(
      protocolSessionId: id,
      method: method,
      arguments: arguments,
    );
  }

  ProtocolEvent _mapProtocolEvent(NativeProtocolEvent event) {
    switch (event.type) {
      case NativeProtocolEventType.ready:
        return const ProtocolReady();
      case NativeProtocolEventType.busy:
        return ProtocolBusy(event.reason ?? 'busy');
      case NativeProtocolEventType.error:
        final failure = event.failure;
        return ProtocolError(
          ProtocolFailure(
            code: failure?.code ?? 'native-protocol-error',
            message:
                failure?.message ??
                'Native protocol reported an unspecified error.',
            details: failure?.details ?? const <String, Object?>{},
          ),
        );
    }
  }
}
