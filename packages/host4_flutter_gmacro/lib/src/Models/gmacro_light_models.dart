import 'gmacro_model_parsers.dart';

class LightColorPayload {
  const LightColorPayload({
    required this.red,
    required this.green,
    required this.blue,
  });

  final int red;
  final int green;
  final int blue;

  Map<String, Object?> toMap() => {'red': red, 'green': green, 'blue': blue};

  factory LightColorPayload.fromMap(Map<dynamic, dynamic> map) {
    return LightColorPayload(
      red: gmacroToInt(map['red']),
      green: gmacroToInt(map['green']),
      blue: gmacroToInt(map['blue']),
    );
  }

  @override
  String toString() {
    return 'LightColorPayload(red: $red, green: $green, blue: $blue)';
  }
}

/// 灯效配置（对应 0x71 fetch / 0x72 set）
///
/// [effect]: 1=单色, 2=呼吸, 3=色谱循环
/// [colorR/G/B]: RGB 值 0-255
/// [light]: 亮度 0-100
/// [speed]: 速度 0-100
/// [profile]: 配置文件索引
class LightConfigPayload {
  const LightConfigPayload({
    required this.effect,
    required this.colorR,
    required this.colorG,
    required this.colorB,
    required this.light,
    required this.speed,
    required this.profile,
  });

  final int effect;
  final int colorR;
  final int colorG;
  final int colorB;
  final int light;
  final int speed;
  final int profile;

  Map<String, Object?> toMap() => {
        'effect': effect,
        'colorR': colorR,
        'colorG': colorG,
        'colorB': colorB,
        'light': light,
        'speed': speed,
        'profile': profile,
      };

  factory LightConfigPayload.fromMap(Map<dynamic, dynamic> map) {
    return LightConfigPayload(
      effect: gmacroToInt(map['effect']),
      colorR: gmacroToInt(map['colorR']),
      colorG: gmacroToInt(map['colorG']),
      colorB: gmacroToInt(map['colorB']),
      light: gmacroToInt(map['light']),
      speed: gmacroToInt(map['speed']),
      profile: gmacroToInt(map['profile']),
    );
  }

  @override
  String toString() {
    return 'LightConfigPayload(effect: $effect, '
        'colorR: $colorR, colorG: $colorG, colorB: $colorB, '
        'light: $light, speed: $speed, profile: $profile)';
  }
}

enum LightPosition {
  leftStickRing(0),
  rightStickRing(1),
  leftAmbient(2),
  rightAmbient(3),
  home(4),
  backlight(5),
  chargingDock(6);

  const LightPosition(this.value);

  final int value;

  static LightPosition? fromValue(int value) {
    for (final item in LightPosition.values) {
      if (item.value == value) return item;
    }
    return null;
  }
}

enum LightMajorMode {
  steady(0),
  breath(1),
  rainbowGradient(2),
  rainbowMarquee(3),
  monoMarquee(4);

  const LightMajorMode(this.value);

  final int value;

  static LightMajorMode? fromValue(int value) {
    for (final item in LightMajorMode.values) {
      if (item.value == value) return item;
    }
    return null;
  }
}
