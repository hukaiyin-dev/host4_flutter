import 'package:host4_flutter_webview/host4_flutter_webview.dart';

import 'host4_web_emulator_javascript.dart';
import 'host4_web_emulator_launch_config.dart';

class Host4WebEmulatorController {
  Host4WebEmulatorController(this._webController);

  final Host4WebController _webController;

  Future<void> launch(Host4WebEmulatorLaunchConfig config) {
    return _webController.runJavaScript(
      Host4WebEmulatorJavaScript.launch(config),
    );
  }

  Future<void> pause() {
    return _webController.runJavaScript(Host4WebEmulatorJavaScript.pause());
  }

  Future<void> resume() {
    return _webController.runJavaScript(Host4WebEmulatorJavaScript.resume());
  }

  Future<void> restart() {
    return _webController.runJavaScript(Host4WebEmulatorJavaScript.restart());
  }

  Future<void> exit() {
    return _webController.runJavaScript(Host4WebEmulatorJavaScript.exit());
  }

  Future<void> saveState([String requestId = 'saveState']) {
    return _webController.runJavaScript(
      Host4WebEmulatorJavaScript.saveState(requestId),
    );
  }

  Future<void> loadState(String stateBase64,
      [String requestId = 'loadState']) {
    return _webController.runJavaScript(
      Host4WebEmulatorJavaScript.loadState(stateBase64, requestId),
    );
  }

  Future<void> screenshot([String requestId = 'screenshot']) {
    return _webController.runJavaScript(
      Host4WebEmulatorJavaScript.screenshot(requestId),
    );
  }

  Future<void> setRate(double rate) {
    return _webController.runJavaScript(
      Host4WebEmulatorJavaScript.setRate(rate),
    );
  }

  /// [button]: up, down, left, right, a, b, x, y, l, r, select, start 等。
  /// [action]: 'down' 按下, 'up' 松开, 'press' 按下后自动松开。
  Future<void> keyEvent(
    String button, {
    String action = 'down',
    int player = 1,
    int? duration,
  }) {
    return _webController.runJavaScript(
      Host4WebEmulatorJavaScript.keyEvent(
        button,
        action: action,
        player: player,
        duration: duration,
      ),
    );
  }
}
