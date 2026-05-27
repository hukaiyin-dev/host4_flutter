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
