import 'Models/gmacro_methods.dart';
import 'gmacro_session.dart';

extension GmacroSessionOther on GmacroSession {
  /// 设置马达开关状态 马达开关状态：1 为开启，2 为关闭
  Future<Map<String, Object?>> switchVibrateOpen({required int status}) =>
      invoke(GmacroMethods.switchVibrateOpen, arguments: {'status': status});

  /// 查询马达开关状态
  Future<Map<String, Object?>> queryVibrateOpen() =>
      invoke(GmacroMethods.queryVibrateOpen);

  /// 设置手柄按键风格（xbox 和 ns 风格） 0.关闭手柄模式；1.XBOX 模式（默认）；2.Nintendo 模式；3、XBOX ONE 模式
  Future<Map<String, Object?>> switchWorkStyle({required int mode}) =>
      invoke(GmacroMethods.switchWorkStyle, arguments: {'mode': mode});

  /// 查询手柄按键风格
  Future<Map<String, Object?>> queryWorkStyle() =>
      invoke(GmacroMethods.queryWorkStyle);

  /// 设置当前手柄模式 1.XINPUT；2.DINPUT； 3.Switch
  Future<Map<String, Object?>> switchOutputMode({required int mode}) =>
      invoke(GmacroMethods.switchOutputMode, arguments: {'mode': mode});

  /// 查询当前手柄模式
  Future<Map<String, Object?>> queryOutputMode() =>
      invoke(GmacroMethods.queryOutputMode);

  /// 测试模式切换配置页（1-5）
  Future<Map<String, Object?>> sendHandleBeta({required int profile}) =>
      invoke(GmacroMethods.sendHandleBeta, arguments: {'profile': profile});

  /// 切换手柄配置页（1-5）
  Future<Map<String, Object?>> switchHandleConfig({required int profile}) =>
      invoke(GmacroMethods.switchHandleConfig, arguments: {'profile': profile});

  /// 开关手柄功能以及回调 0:关闭手柄 1关闭私有协议 2关闭手柄共有协议
  Future<Map<String, Object?>> switchHandleCallbacks({required int method}) =>
      invoke(GmacroMethods.switchHandleCallbacks, arguments: {'method': method});

  /// 查询左右扳机线性输出
  Future<Map<String, Object?>> queryLinerTrigger() =>
      invoke(GmacroMethods.queryLinerTrigger);

  /// 设置左右扳机线性输出 1 线性 2 非线性
  Future<Map<String, Object?>> switchLinerTrigger({required int mode}) =>
      invoke(GmacroMethods.switchLinerTrigger, arguments: {'mode': mode});

  /// 查询当前灯效（pantas 使用）
  Future<Map<String, Object?>> queryLightingEffectPantas() =>
      invoke(GmacroMethods.queryLightingEffectPantas);

  /// 设置灯组灯效（pantas 使用）
  Future<Map<String, Object?>> setLightGroupEffectPantas({
    required bool open,
    required int mode,
    required int brightness,
    required int colorR,
    required int colorG,
    required int colorB,
  }) => invoke(
    GmacroMethods.setLightGroupEffectPantas,
    arguments: {
      'open': open,
      'mode': mode,
      'brightness': brightness,
      'colorR': colorR,
      'colorG': colorG,
      'colorB': colorB,
    },
  );
}
