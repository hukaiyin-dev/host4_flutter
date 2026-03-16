import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'host4_flutter_bridge_method_channel.dart';

abstract class Host4FlutterBridgePlatform extends PlatformInterface {
  /// Constructs a Host4FlutterBridgePlatform.
  Host4FlutterBridgePlatform() : super(token: _token);

  static final Object _token = Object();

  static Host4FlutterBridgePlatform _instance = MethodChannelHost4FlutterBridge();

  /// The default instance of [Host4FlutterBridgePlatform] to use.
  ///
  /// Defaults to [MethodChannelHost4FlutterBridge].
  static Host4FlutterBridgePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [Host4FlutterBridgePlatform] when
  /// they register themselves.
  static set instance(Host4FlutterBridgePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
