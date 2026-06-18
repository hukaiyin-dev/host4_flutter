import 'Models/gmacro_gamepad_key.dart';
import 'Models/gmacro_mapping_models.dart';
import 'Models/gmacro_methods.dart';
import 'gmacro_session.dart';

extension GmacroSessionMapping on GmacroSession {
  /// 查询支持映射的按键
  Future<Map<String, Object?>> queryMappableKeys({required int profile}) =>
      invoke(GmacroMethods.queryMappableKeys, arguments: {'profile': profile});

  /// 查询支持映射为手柄的按键
  Future<Map<String, Object?>> queryMappableGamepadKeys({
    required int profile,
  }) => invoke(
    GmacroMethods.queryMappableGamepadKeys,
    arguments: {'profile': profile},
  );

  /// 设置按键映射为手柄
  /// - [keyMappings] 手柄按键映射数组
  Future<Map<String, Object?>> setKeyMappings({
    required List<GamepadKeyMappingPayload> keyMappings,
  }) => invoke(
    GmacroMethods.setKeyMappings,
    arguments: {'keyMappings': keyMappings.map((e) => e.toMap()).toList()},
  );

  /// 设置手柄按键映射（单映射）6C 0D
  /// - [original] 原始手柄按键
  /// - [mapped] 映射手柄按键
  Future<Map<String, Object?>> setHandleKeyMapping({
    required GamepadKey original,
    required GamepadKey mapped,
  }) => invoke(
    GmacroMethods.setHandleKeyMapping,
    arguments: {'original': original.value, 'mapped': mapped.value},
  );

  /// 设置按键映射为鼠标
  /// - [keyMappings] 鼠标按键映射数组
  Future<Map<String, Object?>> setMouseKeyMappings({
    required List<MouseKeyMappingPayload> keyMappings,
  }) => invoke(
    GmacroMethods.setMouseKeyMappings,
    arguments: {'keyMappings': keyMappings.map((e) => e.toMap()).toList()},
  );

  /// 设置按键映射为键盘
  /// - [keyMappings] 键盘按键映射数组
  Future<Map<String, Object?>> setKeyboardKeyMappings({
    required List<KeyboardKeyMappingPayload> keyMappings,
  }) => invoke(
    GmacroMethods.setKeyboardKeyMappings,
    arguments: {'keyMappings': keyMappings.map((e) => e.toMap()).toList()},
  );

  /// 查询当前按键映射配置
  Future<Map<String, Object?>> queryCurrentMapping({required int profile}) =>
      invoke(
        GmacroMethods.queryCurrentMapping,
        arguments: {'profile': profile},
      );

  /// 设置手柄按键映射（支持同时映射多种类型键值）
  /// - [original] 原始手柄按键
  /// - [mappedKeys] 映射目标数组
  Future<Map<String, Object?>> setMultiKeyMapping({
    required GamepadKey original,
    required List<MappedKeyPayload> mappedKeys,
  }) => invoke(
    GmacroMethods.setMultiKeyMapping,
    arguments: {
      'original': original.value,
      'mappedKeys': mappedKeys.map((e) => e.toMap()).toList(),
    },
  );

  /// 查询所有按键多映射配置
  Future<Map<String, Object?>> queryAllMultiMappings() =>
      invoke(GmacroMethods.queryAllMultiMappings);

  /// 查询某个手柄按键的多映射配置
  Future<Map<String, Object?>> queryMultiMapping({
    required GamepadKey original,
  }) => invoke(
    GmacroMethods.queryMultiMapping,
    arguments: {'original': original.value},
  );
}
