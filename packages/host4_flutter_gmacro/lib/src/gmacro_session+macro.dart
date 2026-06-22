import 'Models/gmacro_gamepad_key.dart';
import 'Models/gmacro_macro_models.dart';
import 'Models/gmacro_methods.dart';
import 'gmacro_session.dart';

extension GmacroSessionMacro on GmacroSession {
  /// 查询手柄当前配置页 0x5C
  Future<Map<String, Object?>> fetchCurrentProfile() =>
      invoke(GmacroMethods.fetchCurrentProfile);

  /// 查询当前宏
  Future<Map<String, Object?>> queryCurrentMacro({required int profile}) =>
      invoke(GmacroMethods.queryCurrentMacro, arguments: {'profile': profile});

  /// 查询宏按键
  Future<Map<String, Object?>> queryMacroKeys({required int profile}) =>
      invoke(GmacroMethods.queryMacroKeys, arguments: {'profile': profile});

  /// 查询可录制宏按键
  Future<Map<String, Object?>> queryMacroRecordableKeys({
    required int profile,
  }) => invoke(
    GmacroMethods.queryMacroRecordableKeys,
    arguments: {'profile': profile},
  );

  /// 查询宏时间范围
  Future<Map<String, Object?>> queryMacroTimeRange({required int profile}) =>
      invoke(
        GmacroMethods.queryMacroTimeRange,
        arguments: {'profile': profile},
      );

  /// 查询宏最大组数
  Future<Map<String, Object?>> queryMacroMaxGroups({required int profile}) =>
      invoke(
        GmacroMethods.queryMacroMaxGroups,
        arguments: {'profile': profile},
      );

  /// 设置宏定义循环间隔
  Future<Map<String, Object?>> setMacroInterval({
    required int profile,
    required GamepadKey key,
    required int intervalTime,
  }) => invoke(
    GmacroMethods.setMacroInterval,
    arguments: {
      'profile': profile,
      'key': key.value,
      'intervalTime': intervalTime,
    },
  );

  /// 设置宏定义子按键
  Future<Map<String, Object?>> setMacroKeys({
    required MacroKeyPayload macroKey,
  }) => invoke(
    GmacroMethods.setMacroKeys,
    arguments: {'macroKey': macroKey.toMap()},
  );

  /// 开始录制宏
  Future<Map<String, Object?>> startRecord() =>
      invoke(GmacroMethods.startRecord);

  /// 结束录制宏
  Future<Map<String, Object?>> endRecord() => invoke(GmacroMethods.endRecord);
}
