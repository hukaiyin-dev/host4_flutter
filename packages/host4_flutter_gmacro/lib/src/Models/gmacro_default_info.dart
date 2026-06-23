/// 0x77 04 fetchGameMacroDefaultInfo 响应数据模型
///
/// 对应 iOS SDK `analyzeGameMacroDeviceInfo` 的解析结果。
/// 所有枚举字段已在 iOS Plugin 层转为 Int rawValue，直接使用即可。
///
/// 使用示例:
/// ```dart
/// final info = await session.fetchGameMacroDefaultInfo(profile: 0);
/// print(info.vibration.left);       // int, 0-100
/// print(info.leftStick.reverseX);   // bool
/// print(info.motion.sensitivity);   // int
/// ```
import 'gmacro_model_parsers.dart';

/// 0x77 04 曲线坐标点（int 版，0-100）
class GmacroDefaultCurvePoint {
  final int x;
  final int y;
  const GmacroDefaultCurvePoint({required this.x, required this.y});

  factory GmacroDefaultCurvePoint.fromMap(Map map) => GmacroDefaultCurvePoint(
    x: gmacroToInt(map['x']),
    y: gmacroToInt(map['y']),
  );

  Map<String, Object?> toMap() => {'x': x, 'y': y};

  @override
  String toString() => '($x, $y)';
}

// ─── 连发配置 ───

/// 0x77 04 连发配置
class GmacroRapidFireConfig {
  final int key;      // GamepadKey rawValue
  final int turbo;    // TurboMode rawValue
  final int speed;
  const GmacroRapidFireConfig({required this.key, required this.turbo, required this.speed});

  factory GmacroRapidFireConfig.fromMap(Map map) => GmacroRapidFireConfig(
    key:   gmacroToInt(map['key']),
    turbo: gmacroToInt(map['turbo']),
    speed: gmacroToInt(map['speed']),
  );

  Map<String, Object?> toMap() => {'key': key, 'turbo': turbo, 'speed': speed};

  @override
  String toString() => 'RapidFire(key: $key, turbo: $turbo, speed: $speed)';
}

// ─── 扳机配置 ───

/// 0x77 04 扳机配置
class GmacroTriggerDefaultConfig {
  final int start;
  final int end;
  final int pointCount;
  final List<GmacroDefaultCurvePoint> points;
  final bool fastTrigger;
  const GmacroTriggerDefaultConfig({
    required this.start,
    required this.end,
    required this.pointCount,
    required this.points,
    required this.fastTrigger,
  });

  factory GmacroTriggerDefaultConfig.fromMap(Map map) => GmacroTriggerDefaultConfig(
    start:      gmacroToInt(map['start']),
    end:        gmacroToInt(map['end']),
    pointCount: gmacroToInt(map['pointCount']),
    fastTrigger: map['fastTrigger'] == true,
    points:     _parsePoints(map['points']),
  );

  Map<String, Object?> toMap() => {
    'start': start,
    'end': end,
    'pointCount': pointCount,
    'points': points.map((e) => e.toMap()).toList(),
    'fastTrigger': fastTrigger,
  };

  @override
  String toString() =>
      'Trigger(start: $start, end: $end, points: $pointCount, fast: $fastTrigger)';
}

// ─── 摇杆配置 ───

/// 0x77 04 摇杆默认配置
class GmacroStickDefaultConfig {
  final int deadzoneComp;
  final int returnComp;
  final int start;
  final int end;
  final bool reverseX;
  final bool reverseY;
  final int triggerMode;    // CurveTriggerMode rawValue
  final int triggerKey;     // GamepadKey rawValue
  final int outputGraphic;  // OutputGraphics rawValue
  final int pointCount;
  final List<GmacroDefaultCurvePoint> points;

  const GmacroStickDefaultConfig({
    required this.deadzoneComp,
    required this.returnComp,
    required this.start,
    required this.end,
    required this.reverseX,
    required this.reverseY,
    required this.triggerMode,
    required this.triggerKey,
    required this.outputGraphic,
    required this.pointCount,
    required this.points,
  });

  factory GmacroStickDefaultConfig.fromMap(Map map) => GmacroStickDefaultConfig(
    deadzoneComp:  gmacroToInt(map['deadzoneComp']),
    returnComp:    gmacroToInt(map['returnComp']),
    start:         gmacroToInt(map['start']),
    end:           gmacroToInt(map['end']),
    reverseX:      map['reverseX'] == true,
    reverseY:      map['reverseY'] == true,
    triggerMode:   gmacroToInt(map['triggerMode']),
    triggerKey:    gmacroToInt(map['triggerKey']),
    outputGraphic: gmacroToInt(map['outputGraphic']),
    pointCount:    gmacroToInt(map['pointCount']),
    points:        _parsePoints(map['points']),
  );

  Map<String, Object?> toMap() => {
    'deadzoneComp': deadzoneComp,
    'returnComp': returnComp,
    'start': start,
    'end': end,
    'reverseX': reverseX,
    'reverseY': reverseY,
    'triggerMode': triggerMode,
    'triggerKey': triggerKey,
    'outputGraphic': outputGraphic,
    'pointCount': pointCount,
    'points': points.map((e) => e.toMap()).toList(),
  };

  @override
  String toString() =>
      'Stick(start: $start-$end, dead: $deadzoneComp, revX: $reverseX, revY: $reverseY)';
}

// ─── 振动配置 ───

/// 0x77 04 振动配置
class GmacroVibrationDefaultConfig {
  final int left;   // 0-100
  final int right;  // 0-100
  const GmacroVibrationDefaultConfig({required this.left, required this.right});

  factory GmacroVibrationDefaultConfig.fromMap(Map map) => GmacroVibrationDefaultConfig(
    left:  gmacroToInt(map['left']),
    right: gmacroToInt(map['right']),
  );

  Map<String, Object?> toMap() => {'left': left, 'right': right};

  @override
  String toString() => 'Vibration(left: $left, right: $right)';
}

// ─── 体感配置 ───

/// 0x77 04 体感默认配置
class GmacroMotionDefaultConfig {
  final bool enabled;
  final bool mappingEnabled;
  final int triggerMode;         // MotionTriggerMode rawValue
  final int triggerKey;          // GamepadKey rawValue
  final int deadzone;
  final int sensitivity;
  final int mappingMode;         // MotionMappingMode rawValue
  final int axis;                // GyroAxis rawValue
  final bool reverseX;
  final bool reverseY;
  final int deadzoneComp;
  final List<GmacroDefaultCurvePoint> curve;
  final bool secondaryEnabled;
  final int secondaryTriggerMode;
  final int secondaryTriggerKey;
  final int secondarySensitivity;

  const GmacroMotionDefaultConfig({
    required this.enabled,
    required this.mappingEnabled,
    required this.triggerMode,
    required this.triggerKey,
    required this.deadzone,
    required this.sensitivity,
    required this.mappingMode,
    required this.axis,
    required this.reverseX,
    required this.reverseY,
    required this.deadzoneComp,
    required this.curve,
    required this.secondaryEnabled,
    required this.secondaryTriggerMode,
    required this.secondaryTriggerKey,
    required this.secondarySensitivity,
  });

  factory GmacroMotionDefaultConfig.fromMap(Map map) => GmacroMotionDefaultConfig(
    enabled:               map['enabled'] == true,
    mappingEnabled:        map['mappingEnabled'] == true,
    triggerMode:           gmacroToInt(map['triggerMode']),
    triggerKey:            gmacroToInt(map['triggerKey']),
    deadzone:              gmacroToInt(map['deadzone']),
    sensitivity:           gmacroToInt(map['sensitivity']),
    mappingMode:           gmacroToInt(map['mappingMode']),
    axis:                  gmacroToInt(map['axis']),
    reverseX:              map['reverseX'] == true,
    reverseY:              map['reverseY'] == true,
    deadzoneComp:          gmacroToInt(map['deadzoneComp']),
    curve:                 _parsePoints(map['curve']),
    secondaryEnabled:      map['secondaryEnabled'] == true,
    secondaryTriggerMode:  gmacroToInt(map['secondaryTriggerMode']),
    secondaryTriggerKey:   gmacroToInt(map['secondaryTriggerKey']),
    secondarySensitivity:  gmacroToInt(map['secondarySensitivity']),
  );

  Map<String, Object?> toMap() => {
    'enabled': enabled,
    'mappingEnabled': mappingEnabled,
    'triggerMode': triggerMode,
    'triggerKey': triggerKey,
    'deadzone': deadzone,
    'sensitivity': sensitivity,
    'mappingMode': mappingMode,
    'axis': axis,
    'reverseX': reverseX,
    'reverseY': reverseY,
    'deadzoneComp': deadzoneComp,
    'curve': curve.map((e) => e.toMap()).toList(),
    'secondaryEnabled': secondaryEnabled,
    'secondaryTriggerMode': secondaryTriggerMode,
    'secondaryTriggerKey': secondaryTriggerKey,
    'secondarySensitivity': secondarySensitivity,
  };

  @override
  String toString() =>
      'Motion(enabled: $enabled, sens: $sensitivity, mode: $mappingMode)';
}

// ─── 总体返回 ───

/// 0x77 04 fetchGameMacroDefaultInfo 完整响应
class GmacroDefaultInfo {
  final List<GmacroRapidFireConfig> rapidList;
  final GmacroTriggerDefaultConfig leftTrigger;
  final GmacroTriggerDefaultConfig rightTrigger;
  final GmacroStickDefaultConfig leftStick;
  final GmacroStickDefaultConfig rightStick;
  final GmacroVibrationDefaultConfig vibration;
  final GmacroMotionDefaultConfig motion;

  const GmacroDefaultInfo({
    required this.rapidList,
    required this.leftTrigger,
    required this.rightTrigger,
    required this.leftStick,
    required this.rightStick,
    required this.vibration,
    required this.motion,
  });

  factory GmacroDefaultInfo.fromMap(Map<dynamic, dynamic> map) {
    final raw = Map<String, dynamic>.from(map);
    return GmacroDefaultInfo(
      rapidList:    _parseList<GmacroRapidFireConfig>(raw['rapidList'], GmacroRapidFireConfig.fromMap),
      leftTrigger:  GmacroTriggerDefaultConfig.fromMap(_safeMap(raw['leftTrigger'])),
      rightTrigger: GmacroTriggerDefaultConfig.fromMap(_safeMap(raw['rightTrigger'])),
      leftStick:    GmacroStickDefaultConfig.fromMap(_safeMap(raw['leftStick'])),
      rightStick:   GmacroStickDefaultConfig.fromMap(_safeMap(raw['rightStick'])),
      vibration:    GmacroVibrationDefaultConfig.fromMap(_safeMap(raw['vibration'])),
      motion:       GmacroMotionDefaultConfig.fromMap(_safeMap(raw['motion'])),
    );
  }

  @override
  String toString() =>
      'GmacroDefaultInfo(rapid: ${rapidList.length}, '
      'vib: $vibration, motion: $motion)';
}

// ─── 内部工具函数 ───

List<GmacroDefaultCurvePoint> _parsePoints(dynamic raw) {
  if (raw is! List) return const [];
  return raw.whereType<Map>().map(GmacroDefaultCurvePoint.fromMap).toList();
}

List<T> _parseList<T>(dynamic raw, T Function(Map) fromMap) {
  if (raw is! List) return const [];
  return raw.whereType<Map>().map(fromMap).toList();
}

Map<String, dynamic> _safeMap(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return {};
}
