import 'Models/gmacro_methods.dart';
import 'gmacro_session.dart';

extension GmacroSessionDevice on GmacroSession {
  /// 查询设备版本
  Future<Map<String, Object?>> fetchDeviceVersion() =>
      invoke(GmacroMethods.fetchDeviceVersion);

  /// 查询设备信息
  Future<Map<String, Object?>> fetchMobapadDeviceInfo({required int profile}) =>
      invoke(
        GmacroMethods.fetchMobapadDeviceInfo,
        arguments: {'profile': profile},
      );

  /// 恢复默认设置
  Future<Map<String, Object?>> resetDevice() =>
      invoke(GmacroMethods.resetDevice);

  /// 切换普通模式
  Future<Map<String, Object?>> switchToNormalMode() =>
      invoke(GmacroMethods.switchToNormalMode);

  /// 切换测试模式
  Future<Map<String, Object?>> switchToTestMode() =>
      invoke(GmacroMethods.switchToTestMode);

  /// 切换配置模式
  Future<Map<String, Object?>> switchToConfigMode() =>
      invoke(GmacroMethods.switchToConfigMode);

  /// 查询上报率
  Future<Map<String, Object?>> fetchReportRate() =>
      invoke(GmacroMethods.fetchReportRate);

  /// 设置上报率
  Future<Map<String, Object?>> updateReportRate({required int rate}) =>
      invoke(GmacroMethods.updateReportRate, arguments: {'rate': rate});

  /// 设置充电底座启停开关
  Future<Map<String, Object?>> updateChargingDock({required bool isOn}) =>
      invoke(GmacroMethods.updateChargingDock, arguments: {'isOn': isOn});

  /// 查询充电底座启停开关
  Future<Map<String, Object?>> fetchChargingDock() =>
      invoke(GmacroMethods.fetchChargingDock);

  /// 设置手柄按键风格（xbox 和 ns 风格）0.关闭手柄模式；1.XBOX 模式（默认）；2.Nintendo 模式；3、XBOX ONE 模式
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
}
