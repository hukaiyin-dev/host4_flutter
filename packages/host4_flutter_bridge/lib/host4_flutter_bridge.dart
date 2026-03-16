
import 'host4_flutter_bridge_platform_interface.dart';

class Host4FlutterBridge {
  Future<String?> getPlatformVersion() {
    return Host4FlutterBridgePlatform.instance.getPlatformVersion();
  }
}
