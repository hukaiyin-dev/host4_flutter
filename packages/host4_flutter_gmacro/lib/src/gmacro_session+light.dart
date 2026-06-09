import 'Models/gmacro_light_models.dart';
import 'Models/gmacro_methods.dart';
import 'gmacro_session.dart';

extension GmacroSessionLight on GmacroSession {
  /// 查询当前灯光状态
  Future<Map<String, Object?>> fetchLight() => invoke(GmacroMethods.fetchLight);

  /// 查询灯光位置及组数
  Future<Map<String, Object?>> fetchLightPosition() =>
      invoke(GmacroMethods.fetchLightPosition);

  /// 查询支持的灯光特效
  Future<Map<String, Object?>> fetchSupportedLightEffects() =>
      invoke(GmacroMethods.fetchSupportedLightEffects);

  /// 查询当前灯光特效
  Future<Map<String, Object?>> fetchCurrentLightEffect() =>
      invoke(GmacroMethods.fetchCurrentLightEffect);

  /// 查询当前灯效配置 0x71
  Future<Map<String, Object?>> fetchCurrentLightConfig() =>
      invoke(GmacroMethods.fetchCurrentLightConfig);

  /// 设置灯效配置 0x72
  /// - [effect] 1=单色, 2=呼吸, 3=色谱循环
  /// - [colorR/G/B] RGB 值 0-255
  /// - [light] 亮度 0-100
  /// - [speed] 速度 0-100  //G910106 掌机和pantas 的2个拉升手柄用：灯效开关 1：开；2：关
  /// - [profile] 配置文件索引
  Future<Map<String, Object?>> setLightConfig({
    required int effect,
    required int colorR,
    required int colorG,
    required int colorB,
    required int light,
    required int speed,
    required int profile,
  }) => invoke(
    GmacroMethods.setLightConfig,
    arguments: <String, Object?>{
      'effect': effect,
      'colorR': colorR,
      'colorG': colorG,
      'colorB': colorB,
      'light': light,
      'speed': speed,
      'profile': profile,
    },
  );

  /// 设置灯组颜色
  /// - [position] 灯光位置
  /// - [groupCount] 组数
  /// - [colors] 颜色列表
  Future<Map<String, Object?>> setLightColor({
    required LightPosition position,
    required int groupCount,
    required List<LightColorPayload> colors,
  }) => invoke(
    GmacroMethods.setLightColor,
    arguments: <String, Object?>{
      'position': position.value,
      'groupCount': groupCount,
      'colors': colors.map((e) => e.toMap()).toList(),
    },
  );

  /// 设置灯光特效
  /// - [position] 灯光位置
  /// - [groupCount] 组数
  /// - [isOn] 是否开启
  /// - [light] 亮度 0-100
  /// - [speed] 速度 0-100
  /// - [mode] 灯光主模式
  /// - [subMode] LightSubMode rawValue (Int)
  /// - [colors] 颜色列表
  Future<Map<String, Object?>> setLightEffect({
    required LightPosition position,
    required int groupCount,
    required bool isOn,
    required int light,
    required int speed,
    required LightMajorMode mode,
    required int subMode,
    required List<LightColorPayload> colors,
  }) => invoke(
    GmacroMethods.setLightEffect,
    arguments: <String, Object?>{
      'position': position.value,
      'groupCount': groupCount,
      'isOn': isOn,
      'light': light,
      'speed': speed,
      'mode': mode.value,
      'subMode': subMode,
      'colors': colors.map((e) => e.toMap()).toList(),
    },
  );
}
