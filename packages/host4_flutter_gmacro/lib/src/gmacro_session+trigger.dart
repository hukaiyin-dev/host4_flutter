import 'Models/gmacro_curve_point.dart';
import 'Models/gmacro_methods.dart';
import 'gmacro_session.dart';

extension GmacroSessionTrigger on GmacroSession {
  /// 设置扳机死区和余量
  Future<Map<String, Object?>> trigger({
    required int leftMin,
    required int leftMax,
    required int rightMin,
    required int rightMax,
  }) => invoke(
    GmacroMethods.trigger,
    arguments: {
      'leftMin': leftMin,
      'leftMax': leftMax,
      'rightMin': rightMin,
      'rightMax': rightMax,
    },
  );

  /// 设置左扳机曲线
  Future<Map<String, Object?>> leftTriggerCurve({
    required List<GmacroCurvePoint> cgPoints,
  }) => invoke(
    GmacroMethods.leftTriggerCurve,
    arguments: {'cgPoints': cgPoints.map((e) => e.toMap()).toList()},
  );

  /// 设置右扳机曲线
  Future<Map<String, Object?>> rightTriggerCurve({
    required List<GmacroCurvePoint> cgPoints,
  }) => invoke(
    GmacroMethods.rightTriggerCurve,
    arguments: {'cgPoints': cgPoints.map((e) => e.toMap()).toList()},
  );

  /// 设置快速扳机开关
  Future<Map<String, Object?>> triggerQuickSwitch({
    required bool leftOn,
    required bool rightOn,
  }) => invoke(
    GmacroMethods.triggerQuickSwitch,
    arguments: {'leftOn': leftOn, 'rightOn': rightOn},
  );

  /// 获取快速扳机开关
  Future<Map<String, Object?>> getTriggerQuickSwitch() =>
      invoke(GmacroMethods.getTriggerQuickSwitch);

  /// 开始扳机校准
  Future<Map<String, Object?>> startTriggerCalibration() =>
      invoke(GmacroMethods.startTriggerCalibration);

  /// 结束扳机校准
  Future<Map<String, Object?>> endTriggerCalibration() =>
      invoke(GmacroMethods.endTriggerCalibration);

  /// 设置左右扳机线性输出
  /// leftMode/rightMode:
  /// 1 = 线性输出
  /// 2 = 非线性输出
  Future<Map<String, Object?>> triggerLinearOutput({
    required int leftMode,
    required int leftThreshold,
    required int rightMode,
    required int rightThreshold,
  }) => invoke(
    GmacroMethods.triggerLinearOutput,
    arguments: {
      'leftMode': leftMode,
      'leftThreshold': leftThreshold,
      'rightMode': rightMode,
      'rightThreshold': rightThreshold,
    },
  );

  /// 设置扳机测试震动开关
  Future<Map<String, Object?>> updateTriggerTestVibrationSwitch({
    required bool triggerTestVibration,
  }) => invoke(
    GmacroMethods.updateTriggerTestVibrationSwitch,
    arguments: {'triggerTestVibration': triggerTestVibration},
  );

  /// 查询扳机测试震动开关
  Future<Map<String, Object?>> fetchTriggerTestVibrationSwitch() =>
      invoke(GmacroMethods.fetchTriggerTestVibrationSwitch);

  /// 设置扳机震动开关
  Future<Map<String, Object?>> updateTriggerVibration({
    required bool triggerVibration,
  }) => invoke(
    GmacroMethods.updateTriggerVibration,
    arguments: {'triggerVibration': triggerVibration},
  );

  /// 查询扳机震动开关
  Future<Map<String, Object?>> fetchTriggerVibration() =>
      invoke(GmacroMethods.fetchTriggerVibration);

  /// 查询左右扳机线性输出
  Future<Map<String, Object?>> queryLinerTrigger() =>
      invoke(GmacroMethods.queryLinerTrigger);

  /// 设置左右扳机线性输出 1 线性 2 非线性
  Future<Map<String, Object?>> switchLinerTrigger({required int mode}) =>
      invoke(GmacroMethods.switchLinerTrigger, arguments: {'mode': mode});
}
