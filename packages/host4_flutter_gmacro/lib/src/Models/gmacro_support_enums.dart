/// Native calibration sub-ids from [DeviceAlignRsp] / align commands.
enum DeviceCalibrationSubId {
  gyro(0x01),
  rocker(0x02),
  trigger(0x03);

  const DeviceCalibrationSubId(this.value);

  final int value;

  static DeviceCalibrationSubId? fromValue(int value) {
    for (final item in DeviceCalibrationSubId.values) {
      if (item.value == value) return item;
    }
    return null;
  }
}

enum OutputGraphics {
  circle(0),
  square(1),
  roundedRect(2);

  const OutputGraphics(this.value);

  final int value;

  static OutputGraphics? fromValue(int value) {
    for (final item in OutputGraphics.values) {
      if (item.value == value) return item;
    }
    return null;
  }
}

enum CurveTriggerMode {
  continuous(0),
  click(1),
  hold(2);

  const CurveTriggerMode(this.value);

  final int value;

  static CurveTriggerMode? fromValue(int value) {
    for (final item in CurveTriggerMode.values) {
      if (item.value == value) return item;
    }
    return null;
  }
}

enum GyroMappingType {
  instant(1),
  continuous(2);

  const GyroMappingType(this.value);

  final int value;

  static GyroMappingType? fromValue(int value) {
    for (final item in GyroMappingType.values) {
      if (item.value == value) return item;
    }
    return null;
  }
}

enum VibrationPosition {
  left(0x01),
  right(0x02),
  both(0x03);

  const VibrationPosition(this.value);

  final int value;

  static VibrationPosition? fromValue(int value) {
    for (final item in VibrationPosition.values) {
      if (item.value == value) return item;
    }
    return null;
  }
}

enum MotionTriggerMode {
  continuous(0),
  click(1),
  hold(2);

  const MotionTriggerMode(this.value);

  final int value;

  static MotionTriggerMode? fromValue(int value) {
    for (final item in MotionTriggerMode.values) {
      if (item.value == value) return item;
    }
    return null;
  }
}

enum MotionMappingMode {
  dPad(0),
  leftStick(1),
  rightStick(2),
  mouse(3);

  const MotionMappingMode(this.value);

  final int value;

  static MotionMappingMode? fromValue(int value) {
    for (final item in MotionMappingMode.values) {
      if (item.value == value) return item;
    }
    return null;
  }
}

enum GyroAxis {
  zAxis(1),
  yAxis(2),
  zAndYAxis(3);

  const GyroAxis(this.value);

  final int value;

  static GyroAxis? fromValue(int value) {
    for (final item in GyroAxis.values) {
      if (item.value == value) return item;
    }
    return null;
  }
}

enum MappingType {
  gamepad(1),
  mouse(2),
  keyboard(4),
  multimedia(8);

  const MappingType(this.value);

  final int value;

  static MappingType? fromValue(int value) {
    for (final item in MappingType.values) {
      if (item.value == value) return item;
    }
    return null;
  }
}

enum MacroCycleMode {
  loop(0),
  once(1),
  hold(2);

  const MacroCycleMode(this.value);

  final int value;

  static MacroCycleMode? fromValue(int value) {
    for (final item in MacroCycleMode.values) {
      if (item.value == value) return item;
    }
    return null;
  }
}
