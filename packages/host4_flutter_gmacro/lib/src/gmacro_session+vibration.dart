import 'Models/gmacro_methods.dart';
import 'Models/gmacro_support_enums.dart';
import 'gmacro_session.dart';

extension GmacroSessionVibration on GmacroSession {
  /// 设置振动级别
  /// - [left] 左侧振动力（0-100）
  /// - [right] 右侧振动力（0-100）
  Future<Map<String, Object?>> setVibrationLevel({
    required int left,
    required int right,
  }) => invoke(
    GmacroMethods.setVibrationLevel,
    arguments: {'left': left, 'right': right},
  );

  /// 测试振动力
  /// - [left] 左侧振动力（0-255）
  /// - [right] 右侧振动力（0-255）
  /// - [position] 振动位置
  Future<Map<String, Object?>> testVibration({
    required int left,
    required int right,
    required VibrationPosition position,
  }) => invoke(
    GmacroMethods.testVibration,
    arguments: {'left': left, 'right': right, 'position': position.value},
  );
}
