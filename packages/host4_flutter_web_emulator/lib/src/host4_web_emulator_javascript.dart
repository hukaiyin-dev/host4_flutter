import 'dart:convert';

import 'host4_web_emulator_launch_config.dart';

class Host4WebEmulatorJavaScript {
  const Host4WebEmulatorJavaScript._();

  static String launch(Host4WebEmulatorLaunchConfig config) {
    return 'window.Host4WebEmulator.launch(${jsonEncode(config.toJson())});';
  }

  static String pause() => 'window.Host4WebEmulator.pause();';

  static String resume() => 'window.Host4WebEmulator.resume();';

  static String restart() => 'window.Host4WebEmulator.restart();';

  static String exit() => 'window.Host4WebEmulator.exit();';

  static String saveState([String requestId = 'saveState']) {
    return 'window.Host4WebEmulator.saveState(${jsonEncode(requestId)});';
  }

  static String loadState(String stateBase64,
      [String requestId = 'loadState']) {
    return 'window.Host4WebEmulator.loadState(${jsonEncode(requestId)}, ${jsonEncode(stateBase64)});';
  }

  static String screenshot([String requestId = 'screenshot']) {
    return 'window.Host4WebEmulator.screenshot(${jsonEncode(requestId)});';
  }

  static String setRate(double rate) {
    return 'window.Host4WebEmulator.setRate($rate);';
  }

  /// 单个按键事件。
  ///
  /// [button]: up, down, left, right, a, b, x, y, l, r, select, start 等。
  /// [player]: 玩家编号，1-4。
  /// [action]: 'down' 按下, 'up' 松开, 'press' 按下后自动松开。
  static String keyEvent(
    String button, {
    String action = 'down',
    int player = 1,
    int? duration,
  }) {
    final event = <String, Object>{
      'button': button,
      'player': player,
      'action': action,
    };
    if (duration != null) event['duration'] = duration;
    return 'window.Host4WebEmulator.keyEvent(${jsonEncode(event)});';
  }

  /// 批量按键事件。
  static String keyEvents(List<Map<String, Object?>> events) {
    return 'window.Host4WebEmulator.keyEvents(${jsonEncode(events)});';
  }
}
