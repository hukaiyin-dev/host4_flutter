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
}
