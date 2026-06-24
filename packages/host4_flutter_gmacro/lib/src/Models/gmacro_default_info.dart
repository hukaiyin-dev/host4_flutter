/// 0x77 04 fetchGameMacroDefaultInfo 响应数据模型
///
/// 对应 iOS SDK `analyzeGameMacroDeviceInfo` 解析结果。
/// 枚举字段已在 iOS Plugin 层转为 Int rawValue。
///
/// 使用示例:
/// ```dart
/// final info = await session.fetchGameMacroDefaultInfo(profile: 0);
/// print(info.vibration.left);         // int
/// print(info.leftStickX.reverse);     // int
/// print(info.motion.sensitivity);     // int
/// ```
import 'gmacro_model_parsers.dart';

// ─── 连发 ───

class GmacroRapidFireItem {
  final int key;   // GamepadKey rawValue
  final int mode;  // TurboMode rawValue
  final int speed;
  const GmacroRapidFireItem({required this.key, required this.mode, required this.speed});

  factory GmacroRapidFireItem.fromMap(Map map) => GmacroRapidFireItem(
    key:   gmacroToInt(map['key']),
    mode:  gmacroToInt(map['mode']),
    speed: gmacroToInt(map['speed']),
  );

  Map<String, Object?> toMap() => {'key': key, 'mode': mode, 'speed': speed};

  @override
  String toString() => 'RapidFire(key: $key, mode: $mode, speed: $speed)';
}

// ─── 扳机 ───

class GmacroTriggerDefaultConfig {
  final int start;
  final int end;
  final bool macroOn;
  final int macroThreshold;
  final int pointCount;
  final List<List<int>> points;

  const GmacroTriggerDefaultConfig({
    required this.start,
    required this.end,
    required this.macroOn,
    required this.macroThreshold,
    required this.pointCount,
    required this.points,
  });

  factory GmacroTriggerDefaultConfig.fromMap(Map map) => GmacroTriggerDefaultConfig(
    start:          gmacroToInt(map['start']),
    end:            gmacroToInt(map['end']),
    macroOn:        map['macroOn'] == true,
    macroThreshold: gmacroToInt(map['macroThreshold']),
    pointCount:     gmacroToInt(map['pointCount']),
    points:         _parsePointPairs(map['points']),
  );

  Map<String, Object?> toMap() => {
    'start': start, 'end': end,
    'macroOn': macroOn, 'macroThreshold': macroThreshold,
    'pointCount': pointCount, 'points': points,
  };

  @override
  String toString() =>
      'Trigger(start: $start-$end, macro: $macroOn, points: $pointCount)';
}

// ─── 摇杆轴向 ───

class GmacroStickAxisConfig {
  final int start;
  final int end;
  final int sensitivity;
  final int reverse; // 0/1

  const GmacroStickAxisConfig({
    required this.start, required this.end,
    required this.sensitivity, required this.reverse,
  });

  factory GmacroStickAxisConfig.fromMap(Map map) => GmacroStickAxisConfig(
    start:       gmacroToInt(map['start']),
    end:         gmacroToInt(map['end']),
    sensitivity: gmacroToInt(map['sensitivity']),
    reverse:     gmacroToInt(map['reverse']),
  );

  Map<String, Object?> toMap() =>
      {'start': start, 'end': end, 'sensitivity': sensitivity, 'reverse': reverse};

  @override
  String toString() =>
      'StickAxis(start: $start-$end, sens: $sensitivity, reverse: $reverse)';
}

// ─── 摇杆按键附加 ───

class GmacroStickKeyConfig {
  final int deadZoneShape;
  final int maxOutput;
  final int curveApply;
  final int curveApplyKey;
  final int lineCorrection;
  final int pointCount;
  final List<List<int>> points;

  const GmacroStickKeyConfig({
    required this.deadZoneShape, required this.maxOutput,
    required this.curveApply, required this.curveApplyKey,
    required this.lineCorrection, required this.pointCount,
    required this.points,
  });

  factory GmacroStickKeyConfig.fromMap(Map map) => GmacroStickKeyConfig(
    deadZoneShape:  gmacroToInt(map['deadZoneShape']),
    maxOutput:      gmacroToInt(map['maxOutput']),
    curveApply:     gmacroToInt(map['curveApply']),
    curveApplyKey:  gmacroToInt(map['curveApplyKey']),
    lineCorrection: gmacroToInt(map['lineCorrection']),
    pointCount:     gmacroToInt(map['pointCount']),
    points:         _parsePointPairs(map['points']),
  );

  Map<String, Object?> toMap() => {
    'deadZoneShape': deadZoneShape, 'maxOutput': maxOutput,
    'curveApply': curveApply, 'curveApplyKey': curveApplyKey,
    'lineCorrection': lineCorrection, 'pointCount': pointCount, 'points': points,
  };

  @override
  String toString() =>
      'StickKey(dead: $deadZoneShape, max: $maxOutput, curve: $curveApply)';
}

// ─── 振动 ───

class GmacroVibrationDefaultConfig {
  final int left;
  final int right;
  const GmacroVibrationDefaultConfig({required this.left, required this.right});

  factory GmacroVibrationDefaultConfig.fromMap(Map map) => GmacroVibrationDefaultConfig(
    left:  gmacroToInt(map['left']),
    right: gmacroToInt(map['right']),
  );

  Map<String, Object?> toMap() => {'left': left, 'right': right};

  @override
  String toString() => 'Vibration(left: $left, right: $right)';
}

// ─── 体感 ───

class GmacroMotionDefaultConfig {
  final int sensitivity;
  final int yReverse;
  final int motionSwitch;
  final int mappingSwitch;
  final int triggerMode;
  final int triggerKey;
  final int deadZone;
  final int mapping;

  const GmacroMotionDefaultConfig({
    required this.sensitivity, required this.yReverse,
    required this.motionSwitch, required this.mappingSwitch,
    required this.triggerMode, required this.triggerKey,
    required this.deadZone, required this.mapping,
  });

  factory GmacroMotionDefaultConfig.fromMap(Map map) => GmacroMotionDefaultConfig(
    sensitivity:   gmacroToInt(map['sensitivity']),
    yReverse:      gmacroToInt(map['yReverse']),
    motionSwitch:  gmacroToInt(map['switch']),
    mappingSwitch: gmacroToInt(map['mappingSwitch']),
    triggerMode:   gmacroToInt(map['triggerMode']),
    triggerKey:    gmacroToInt(map['triggerKey']),
    deadZone:      gmacroToInt(map['deadZone']),
    mapping:       gmacroToInt(map['mapping']),
  );

  @override
  String toString() =>
      'Motion(sens: $sensitivity, switch: $motionSwitch, mode: $triggerMode)';
}

// ─── 总体返回 ───

class GmacroDefaultInfo {
  final List<GmacroRapidFireItem> rapidList;
  final GmacroTriggerDefaultConfig leftTrigger;
  final GmacroTriggerDefaultConfig rightTrigger;
  final int stickSwap;
  final GmacroStickAxisConfig leftStickX;
  final GmacroStickAxisConfig leftStickY;
  final GmacroStickAxisConfig rightStickX;
  final GmacroStickAxisConfig rightStickY;
  final GmacroStickKeyConfig leftStickKey;
  final GmacroStickKeyConfig rightStickKey;
  final GmacroVibrationDefaultConfig vibration;
  final GmacroMotionDefaultConfig motion;

  const GmacroDefaultInfo({
    required this.rapidList,
    required this.leftTrigger, required this.rightTrigger,
    required this.stickSwap,
    required this.leftStickX, required this.leftStickY,
    required this.rightStickX, required this.rightStickY,
    required this.leftStickKey, required this.rightStickKey,
    required this.vibration,
    required this.motion,
  });

  factory GmacroDefaultInfo.fromMap(Map<dynamic, dynamic> map) {
    final raw = Map<String, dynamic>.from(map);
    return GmacroDefaultInfo(
      rapidList:    _parseRapidList(raw['rapidList']),
      leftTrigger:  GmacroTriggerDefaultConfig.fromMap(_m(raw['leftTrigger'])),
      rightTrigger: GmacroTriggerDefaultConfig.fromMap(_m(raw['rightTrigger'])),
      stickSwap:    gmacroToInt(raw['stickSwap']),
      leftStickX:   GmacroStickAxisConfig.fromMap(_m(raw['leftStickX'])),
      leftStickY:   GmacroStickAxisConfig.fromMap(_m(raw['leftStickY'])),
      rightStickX:  GmacroStickAxisConfig.fromMap(_m(raw['rightStickX'])),
      rightStickY:  GmacroStickAxisConfig.fromMap(_m(raw['rightStickY'])),
      leftStickKey: GmacroStickKeyConfig.fromMap(_m(raw['leftStickKey'])),
      rightStickKey:GmacroStickKeyConfig.fromMap(_m(raw['rightStickKey'])),
      vibration:    GmacroVibrationDefaultConfig.fromMap(_m(raw['vibration'])),
      motion:       GmacroMotionDefaultConfig.fromMap(_m(raw['motion'])),
    );
  }

  @override
  String toString() =>
      'GmacroDefaultInfo(rapid: ${rapidList.length}, vib: $vibration, motion: $motion)';
}

// ─── 工具函数 ───

Map<String, dynamic> _m(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return {};
}

List<GmacroRapidFireItem> _parseRapidList(dynamic raw) {
  if (raw is! List) return const [];
  return raw.whereType<Map>().map(GmacroRapidFireItem.fromMap).toList();
}

/// points 格式: [[x1,y1], [x2,y2], ...]
List<List<int>> _parsePointPairs(dynamic raw) {
  if (raw is! List) return const [];
  return raw.whereType<List>().map((p) {
    return [gmacroToInt(p.elementAtOrNull(0)),
            gmacroToInt(p.elementAtOrNull(1))];
  }).toList();
}
