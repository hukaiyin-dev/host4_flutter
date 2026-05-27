import 'gmacro_gamepad_key.dart';
import 'gmacro_mapping_models.dart';
import 'gmacro_model_parsers.dart';
import 'gmacro_support_enums.dart';
import 'gmacro_turbo_models.dart';

class TurboSupportKeyPayload {
  const TurboSupportKeyPayload({
    required this.mode,
    required this.maxSpeed,
    required this.minSpeed,
    required this.keys,
  });

  final TurboMode mode;
  final int maxSpeed;
  final int minSpeed;
  final List<GamepadKey> keys;

  factory TurboSupportKeyPayload.fromMap(Map<dynamic, dynamic> map) {
    final mode = _turboModeFromAny(map['mode']);
    final rawKeys = map['keys'] as List?;

    if (mode == null || rawKeys == null) {
      throw ArgumentError('Invalid TurboSupportKeyPayload map: $map');
    }

    final keys = rawKeys
        .map((e) => _gamepadKeyFromAny(e))
        .whereType<GamepadKey>()
        .toList();

    return TurboSupportKeyPayload(
      mode: mode,
      maxSpeed: gmacroToInt(map['maxSpeed']),
      minSpeed: gmacroToInt(map['minSpeed']),
      keys: keys,
    );
  }

  @override
  String toString() {
    return 'TurboSupportKeyPayload('
        'mode: ${mode.name}, '
        'maxSpeed: $maxSpeed, '
        'minSpeed: $minSpeed, '
        'keys: ${keys.map((e) => e.name).toList()})';
  }
}

class MappableKeysPayload {
  const MappableKeysPayload({required this.types, required this.keys});

  final List<MappingType> types;
  final List<GamepadKey> keys;

  factory MappableKeysPayload.fromMap(Map<dynamic, dynamic> map) {
    final rawTypes = map['types'] as List?;
    final rawKeys = map['keys'] as List?;

    final types = (rawTypes ?? const [])
        .map((e) => _mappingTypeFromAny(e))
        .whereType<MappingType>()
        .toList();

    final keys = (rawKeys ?? const [])
        .map((e) => _gamepadKeyFromAny(e))
        .whereType<GamepadKey>()
        .toList();

    return MappableKeysPayload(types: types, keys: keys);
  }

  @override
  String toString() {
    return 'MappableKeysPayload('
        'types: ${types.map((e) => e.name).toList()}, '
        'keys: ${keys.map((e) => e.name).toList()})';
  }
}

class GamepadKeysPayload {
  const GamepadKeysPayload({required this.keys});

  final List<GamepadKey> keys;

  factory GamepadKeysPayload.fromMap(Map<dynamic, dynamic> map) {
    final rawKeys = map['keys'] as List?;

    final keys = (rawKeys ?? const [])
        .map((e) => _gamepadKeyFromAny(e))
        .whereType<GamepadKey>()
        .toList();

    return GamepadKeysPayload(keys: keys);
  }

  @override
  String toString() {
    return 'GamepadKeysPayload(keys: ${keys.map((e) => e.name).toList()})';
  }
}

class MacroKeysPayload {
  const MacroKeysPayload({required this.supported, required this.keys});

  final bool supported;
  final List<GamepadKey> keys;

  factory MacroKeysPayload.fromMap(Map<dynamic, dynamic> map) {
    final rawKeys = map['keys'] as List?;

    final keys = (rawKeys ?? const [])
        .map((e) => _gamepadKeyFromAny(e))
        .whereType<GamepadKey>()
        .toList();

    return MacroKeysPayload(supported: map['supported'] == true, keys: keys);
  }

  @override
  String toString() {
    return 'MacroKeysPayload('
        'supported: $supported, '
        'keys: ${keys.map((e) => e.name).toList()})';
  }
}

class MacroTimeRangePayload {
  const MacroTimeRangePayload({
    required this.keepTime,
    required this.intervalTime,
    required this.cycleInterval,
  });

  final int keepTime;
  final int intervalTime;
  final int cycleInterval;

  factory MacroTimeRangePayload.fromMap(Map<dynamic, dynamic> map) {
    return MacroTimeRangePayload(
      keepTime: gmacroToInt(map['keepTime']),
      intervalTime: gmacroToInt(map['intervalTime']),
      cycleInterval: gmacroToInt(map['cycleInterval']),
    );
  }

  @override
  String toString() {
    return 'MacroTimeRangePayload('
        'keepTime: $keepTime, '
        'intervalTime: $intervalTime, '
        'cycleInterval: $cycleInterval)';
  }
}

class GyroMappingModesPayload {
  const GyroMappingModesPayload({required this.raw, required this.modes});

  final int raw;
  final List<MotionMappingMode> modes;

  factory GyroMappingModesPayload.fromMap(Map<dynamic, dynamic> map) {
    final rawModes = map['modes'] as List?;

    final modes = (rawModes ?? const [])
        .map((e) => _motionMappingModeFromAny(e))
        .whereType<MotionMappingMode>()
        .toList();

    return GyroMappingModesPayload(raw: gmacroToInt(map['raw']), modes: modes);
  }

  @override
  String toString() {
    return 'GyroMappingModesPayload('
        'raw: $raw, '
        'modes: ${modes.map((e) => e.name).toList()})';
  }
}

class CurrentMappingPayload {
  const CurrentMappingPayload({
    required this.gamepadMappings,
    required this.mouseMappings,
    required this.keyboardMappings,
  });

  final List<GamepadKeyMappingPayload> gamepadMappings;
  final List<MouseKeyMappingPayload> mouseMappings;
  final List<KeyboardKeyMappingPayload> keyboardMappings;

  factory CurrentMappingPayload.fromMap(Map<dynamic, dynamic> map) {
    final rawGamepadMappings = map['gamepadMappings'] as List?;
    final rawMouseMappings = map['mouseMappings'] as List?;
    final rawKeyboardMappings = map['keyboardMappings'] as List?;

    return CurrentMappingPayload(
      gamepadMappings: (rawGamepadMappings ?? const [])
          .whereType<Map>()
          .map((e) => GamepadKeyMappingPayload.fromMap(e))
          .toList(),
      mouseMappings: (rawMouseMappings ?? const [])
          .whereType<Map>()
          .map((e) => MouseKeyMappingPayload.fromMap(e))
          .toList(),
      keyboardMappings: (rawKeyboardMappings ?? const [])
          .whereType<Map>()
          .map((e) => KeyboardKeyMappingPayload.fromMap(e))
          .toList(),
    );
  }

  @override
  String toString() {
    return 'CurrentMappingPayload('
        'gamepadMappings: $gamepadMappings, '
        'mouseMappings: $mouseMappings, '
        'keyboardMappings: $keyboardMappings)';
  }
}

GamepadKey? _gamepadKeyFromAny(dynamic value) {
  if (value is GamepadKey) return value;
  return GamepadKey.fromValue(gmacroToInt(value));
}

MappingType? _mappingTypeFromAny(dynamic value) {
  if (value is MappingType) return value;
  return MappingType.fromValue(gmacroToInt(value));
}

MotionMappingMode? _motionMappingModeFromAny(dynamic value) {
  if (value is MotionMappingMode) return value;
  return MotionMappingMode.fromValue(gmacroToInt(value));
}

TurboMode? _turboModeFromAny(dynamic value) {
  if (value is TurboMode) return value;
  return TurboMode.fromValue(gmacroToInt(value));
}
