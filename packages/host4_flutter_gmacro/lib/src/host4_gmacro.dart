import 'package:host4_flutter_device_native/host4_flutter_device_native.dart';
import 'package:host4_flutter_transport/host4_flutter_transport.dart';

import 'Models/gmacro_config.dart';
import 'gmacro_session.dart';

class Host4Gmacro {
  Host4Gmacro({GmacroConfig? config, Host4FlutterDeviceNative? native})
    : config = config ?? const GmacroConfig(),
      _native = native ?? Host4FlutterDeviceNative();

  final GmacroConfig config;
  final Host4FlutterDeviceNative _native;

  Future<GmacroSession> attach(TransportSession transport) async {
    final sessionId = await _native.attachGmacroProtocol(
      transport.id,
      options: config.toMap(),
    );
    return GmacroSession(id: sessionId, transport: transport, native: _native);
  }
}
