import 'Models/gmacro_curve_point.dart';
import 'Models/gmacro_gamepad_key.dart';
import 'Models/gmacro_methods.dart';
import 'Models/gmacro_support_enums.dart';
import 'gmacro_session.dart';

extension GmacroSessionRocker on GmacroSession {
  /// 摇杆线性设置
  /// - [leftMin] 左摇杆起始值(0-100)
  /// - [leftMax] 左摇杆终止值(0-100)
  /// - [leftXFlip] 左摇杆反转 X
  /// - [leftYFlip] 左摇杆反转 Y
  /// - [rightMin] 右摇杆起始值
  /// - [rightMax] 右摇杆终止值
  /// - [rightXFlip] 右摇杆反转 X
  /// - [rightYFlip] 右摇杆反转 Y
  Future<Map<String, Object?>> updateRockerLinear({
    required int leftMin,
    required int leftMax,
    required bool leftXFlip,
    required bool leftYFlip,
    required int rightMin,
    required int rightMax,
    required bool rightXFlip,
    required bool rightYFlip,
  }) => invoke(
    GmacroMethods.updateRockerLinear,
    arguments: {
      'leftMin': leftMin,
      'leftMax': leftMax,
      'leftXFlip': leftXFlip,
      'leftYFlip': leftYFlip,
      'rightMin': rightMin,
      'rightMax': rightMax,
      'rightXFlip': rightXFlip,
      'rightYFlip': rightYFlip,
    },
  );

  /// 左摇杆曲线设置
  /// - [cgPoints] 曲线点，X/Y 轴坐标: 实际的摇杆行程百分比（0-100）
  Future<Map<String, Object?>> updateLeftRocker3DCurve({
    required List<GmacroCurvePoint> cgPoints,
  }) => invoke(
    GmacroMethods.updateLeftRocker3DCurve,
    arguments: {'cgPoints': cgPoints.map((e) => e.toMap()).toList()},
  );

  /// 右摇杆曲线设置
  /// - [cgPoints] 曲线点，X/Y 轴坐标: 实际的摇杆行程百分比（0-100）
  Future<Map<String, Object?>> updateRightRocker3DCurve({
    required List<GmacroCurvePoint> cgPoints,
  }) => invoke(
    GmacroMethods.updateRightRocker3DCurve,
    arguments: {'cgPoints': cgPoints.map((e) => e.toMap()).toList()},
  );

  /// 设置摇杆死区补偿
  /// - [left] 左摇杆（0-65535）
  /// - [right] 右摇杆（0-65535）
  Future<Map<String, Object?>> rockerDeadZoneCompensation({
    required int left,
    required int right,
  }) => invoke(
    GmacroMethods.rockerDeadZoneCompensation,
    arguments: {'left': left, 'right': right},
  );

  /// 设置摇杆死区回归补偿
  /// - [left] 左摇杆（0-65535）
  /// - [right] 右摇杆（0-65535）
  Future<Map<String, Object?>> rockerDeadZoneRegressionComp({
    required int left,
    required int right,
  }) => invoke(
    GmacroMethods.rockerDeadZoneRegressionComp,
    arguments: {'left': left, 'right': right},
  );

  /// 设置摇杆曲线触发方式以及触发按键
  /// - [leftTriggerMode] 曲线触发方式
  /// - [leftGamepadKey] 曲线触发按键
  /// - [rightTriggerMode] 曲线触发方式
  /// - [rightGamepadKey] 曲线触发按键
  Future<Map<String, Object?>> rockerTriggerType({
    required CurveTriggerMode leftTriggerMode,
    required GamepadKey leftGamepadKey,
    required CurveTriggerMode rightTriggerMode,
    required GamepadKey rightGamepadKey,
  }) => invoke(
    GmacroMethods.rockerTriggerType,
    arguments: {
      'leftRigger': leftTriggerMode.value,
      'leftGamepadKey': leftGamepadKey.value,
      'rightRigger': rightTriggerMode.value,
      'rightGamepadKey': rightGamepadKey.value,
    },
  );

  /// 设置摇杆输出轨迹
  /// - [left] 左摇杆输出轨迹
  /// - [right] 右摇杆输出轨迹
  Future<Map<String, Object?>> rockerOutputGraphics({
    required OutputGraphics left,
    required OutputGraphics right,
  }) => invoke(
    GmacroMethods.rockerOutputGraphics,
    arguments: {'left': left.value, 'right': right.value},
  );

  /// 开始摇杆校准
  Future<Map<String, Object?>> startRockerCalibration() =>
      invoke(GmacroMethods.startRockerCalibration);

  /// 结束摇杆校准
  Future<Map<String, Object?>> endRockerCalibration() =>
      invoke(GmacroMethods.endRockerCalibration);

  /// 摇杆附加功能设置
  /// - [leftDeadZone] 外形死区
  /// - [leftOutMax] 输出最大值：0-100（0%-100%）
  /// - [leftCurveApply] 曲线应用：0：持续，1：单击，2：按住
  /// - [leftCurveApplyKey] 曲线应用按键
  /// - [leftLineCorrection] 直线修正：0：关，1：开
  /// - [rightDeadZone] 外形死区
  /// - [rightOutMax] 输出最大值：0-100（0%-100%）
  /// - [rightCurveApply] 曲线应用：0：持续，1：单击，2：按住
  /// - [rightCurveApplyKey] 曲线应用按键
  /// - [rightLineCorrection] 直线修正：0：关，1：开
  Future<Map<String, Object?>> updateRockerAdditional({
    required int leftDeadZone,
    required int leftOutMax,
    required int leftCurveApply,
    required GamepadKey leftCurveApplyKey,
    required int leftLineCorrection,
    required int rightDeadZone,
    required int rightOutMax,
    required int rightCurveApply,
    required GamepadKey rightCurveApplyKey,
    required int rightLineCorrection,
  }) => invoke(
    GmacroMethods.updateRockerAdditional,
    arguments: {
      'leftDeadZone': leftDeadZone,
      'leftOutMax': leftOutMax,
      'leftCurveApply': leftCurveApply,
      'leftCurveApplyKey': leftCurveApplyKey.value,
      'leftLineCorrection': leftLineCorrection,
      'rightDeadZone': rightDeadZone,
      'rightOutMax': rightOutMax,
      'rightCurveApply': rightCurveApply,
      'rightCurveApplyKey': rightCurveApplyKey.value,
      'rightLineCorrection': rightLineCorrection,
    },
  );
}
