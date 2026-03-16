import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'host4_flutter_bridge_platform_interface.dart';

/// An implementation of [Host4FlutterBridgePlatform] that uses method channels.
class MethodChannelHost4FlutterBridge extends Host4FlutterBridgePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('host4_flutter_bridge');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
