import 'Models/gmacro_gamepad_key.dart';
import 'Models/gmacro_methods.dart';
import 'Models/gmacro_support_enums.dart';
import 'gmacro_session.dart';

extension GmacroSessionGyro on GmacroSession {
  /// 查询支持体感触发的按键
  Future<Map<String, Object?>> queryGyroTriggerKeys({required int profile}) =>
      invoke(
        GmacroMethods.queryGyroTriggerKeys,
        arguments: {'profile': profile},
      );

  /// 查询支持体感映射的模式
  Future<Map<String, Object?>> queryGyroMappingModes({required int profile}) =>
      invoke(
        GmacroMethods.queryGyroMappingModes,
        arguments: {'profile': profile},
      );

  /// 设置体感参数
  /// - [motionEnabled] 是否启用体感
  /// - [mappingEnabled] 是否启用体感映射
  /// - [triggerMode] 体感触发方式
  /// - [triggerKey] 体感触发按键
  /// - [deadZone] 体感死区（0-100）
  /// - [sensitivity] 体感灵敏度（0-1000）
  /// - [mappingMode] 体感映射模式
  Future<Map<String, Object?>> setMotion({
    required bool motionEnabled,
    required bool mappingEnabled,
    required MotionTriggerMode triggerMode,
    required GamepadKey triggerKey,
    required int deadZone,
    required int sensitivity,
    required MotionMappingMode mappingMode,
  }) => invoke(
    GmacroMethods.setMotion,
    arguments: {
      'motionEnabled': motionEnabled,
      'mappingEnabled': mappingEnabled,
      'triggerMode': triggerMode.value,
      'triggerKey': triggerKey.value,
      'deadZone': deadZone,
      'sensitivity': sensitivity,
      'mappingMode': mappingMode.value,
    },
  );

  /// 设置体感二级灵敏度（FPS 模式）
  /// - [isOn] 开关
  /// - [triggerMode] 触发模式
  /// - [triggerKey] 触发按键
  /// - [sensitivity] 灵敏度（0-1000）
  Future<Map<String, Object?>> setMotionSecondary({
    required bool isOn,
    required MotionTriggerMode triggerMode,
    required GamepadKey triggerKey,
    required int sensitivity,
  }) => invoke(
    GmacroMethods.setMotionSecondary,
    arguments: {
      'isOn': isOn,
      'triggerMode': triggerMode.value,
      'triggerKey': triggerKey.value,
      'sensitivity': sensitivity,
    },
  );

  /// 设置体感水平方向使用的轴
  Future<Map<String, Object?>> setMotionHorizontalAxis({
    required GyroAxis axis,
  }) => invoke(
    GmacroMethods.setMotionHorizontalAxis,
    arguments: {'axis': axis.value},
  );

  /// 查询体感水平方向轴向
  Future<Map<String, Object?>> fetchMotionHorizontalAxis() =>
      invoke(GmacroMethods.fetchMotionHorizontalAxis);

  /// 查询陀螺仪死区补偿
  Future<Map<String, Object?>> fetchGyroDeadZoneComp() =>
      invoke(GmacroMethods.fetchGyroDeadZoneComp);

  /// 查询陀螺仪灵敏度曲线
  Future<Map<String, Object?>> fetchGyroSensitivityCurve() =>
      invoke(GmacroMethods.fetchGyroSensitivityCurve);

  /// 查询陀螺仪二级灵敏度
  Future<Map<String, Object?>> fetchGyroSensitivity2() =>
      invoke(GmacroMethods.fetchGyroSensitivity2);

  /// 设置陀螺仪 X/Y 轴反转
  Future<Map<String, Object?>> setGyroXYInvert({
    required bool xOn,
    required bool yOn,
  }) => invoke(
    GmacroMethods.setGyroXYInvert,
    arguments: {'xOn': xOn, 'yOn': yOn},
  );

  /// 查询陀螺仪 XY 轴反转信息
  Future<Map<String, Object?>> fetchGyroXYInvert() =>
      invoke(GmacroMethods.fetchGyroXYInvert);

  /// 设置陀螺仪死区补偿
  /// - [compensate] 补偿值（0-100）
  Future<Map<String, Object?>> setGyroDeadZone({required int compensate}) =>
      invoke(
        GmacroMethods.setGyroDeadZone,
        arguments: {'compensate': compensate},
      );

  /// 设置陀螺仪灵敏度曲线
  Future<Map<String, Object?>> setGyroSensitivityCurve({
    required int x1,
    required int y1,
    required int x2,
    required int y2,
    required int x3,
    required int y3,
  }) => invoke(
    GmacroMethods.setGyroSensitivityCurve,
    arguments: {'x1': x1, 'y1': y1, 'x2': x2, 'y2': y2, 'x3': x3, 'y3': y3},
  );

  /// 设置陀螺仪外圈死区
  /// - [gyroOuterDeadZone] 死区（0-100）
  Future<Map<String, Object?>> updateGyroOuterDeadZone({
    required int gyroOuterDeadZone,
  }) => invoke(
    GmacroMethods.updateGyroOuterDeadZone,
    arguments: {'gyroOuterDeadZone': gyroOuterDeadZone},
  );

  /// 查询陀螺仪外圈死区
  Future<Map<String, Object?>> fetchGyroOuterDeadZone() =>
      invoke(GmacroMethods.fetchGyroOuterDeadZone);

  /// 开始陀螺仪校准
  Future<Map<String, Object?>> startGyroCalibration() =>
      invoke(GmacroMethods.startGyroCalibration);

  /// 结束陀螺仪校准
  Future<Map<String, Object?>> endGyroCalibration() =>
      invoke(GmacroMethods.endGyroCalibration);

  /// 设置陀螺仪 X/Y 轴比例
  /// - [gyroXYRatio] 比例（1-100）
  Future<Map<String, Object?>> updateGyroXYRatio({required int gyroXYRatio}) =>
      invoke(
        GmacroMethods.updateGyroXYRatio,
        arguments: {'gyroXYRatio': gyroXYRatio},
      );

  /// 查询陀螺仪 X/Y 轴比例
  Future<Map<String, Object?>> fetchGyroXYRatio() =>
      invoke(GmacroMethods.fetchGyroXYRatio);

  /// 设置陀螺仪映射类型
  Future<Map<String, Object?>> updateGyroMappingType({
    required GyroMappingType gyroMappingType,
  }) => invoke(
    GmacroMethods.updateGyroMappingType,
    arguments: {'gyroMappingType': gyroMappingType.value},
  );

  /// 查询陀螺仪映射类型
  Future<Map<String, Object?>> fetchGyroMappingType() =>
      invoke(GmacroMethods.fetchGyroMappingType);
}
