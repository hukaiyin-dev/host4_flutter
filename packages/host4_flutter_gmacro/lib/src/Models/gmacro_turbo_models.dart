import 'gmacro_gamepad_key.dart';
import 'gmacro_model_parsers.dart';

enum TurboMode {
  semiAuto(0),
  fullAuto(1),
  disabled(2);

  const TurboMode(this.value);

  final int value;

  static TurboMode? fromValue(int value) {
    for (final item in TurboMode.values) {
      if (item.value == value) return item;
    }
    return null;
  }
}

class KeyTurboPayload {
  const KeyTurboPayload({
    required this.key,
    required this.turbo,
    required this.speed,
  });

  final GamepadKey key;
  final TurboMode turbo;
  final int speed;

  Map<String, Object?> toMap() => {
    'key': key.value,
    'turbo': turbo.value,
    'speed': speed,
  };

  factory KeyTurboPayload.fromMap(Map<dynamic, dynamic> map) {
    final key = GamepadKey.fromValue(gmacroToInt(map['key']));
    final turbo = TurboMode.fromValue(gmacroToInt(map['turbo']));

    if (key == null || turbo == null) {
      throw ArgumentError('Invalid KeyTurboPayload map: $map');
    }

    return KeyTurboPayload(
      key: key,
      turbo: turbo,
      speed: gmacroToInt(map['speed']),
    );
  }

  @override
  String toString() {
    return 'KeyTurboPayload('
        'key: ${key.name}(${key.value}), '
        'turbo: ${turbo.name}, '
        'speed: $speed)';
  }
}
