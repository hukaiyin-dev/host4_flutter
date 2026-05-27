import 'gmacro_gamepad_key.dart';
import 'gmacro_model_parsers.dart';
import 'gmacro_support_enums.dart';

class MacroComKeyPayload {
  const MacroComKeyPayload({
    required this.keys,
    this.keepTime = 100,
    this.intervalTime = 0,
  });

  final List<GamepadKey> keys;
  final int keepTime;
  final int intervalTime;

  Map<String, Object?> toMap() => {
    'keys': keys.map((e) => e.value).toList(),
    'keepTime': keepTime,
    'intervalTime': intervalTime,
  };

  factory MacroComKeyPayload.fromMap(Map<dynamic, dynamic> map) {
    final rawKeys = map['keys'] as List?;
    if (rawKeys == null) {
      throw ArgumentError('Invalid MacroComKeyPayload map: $map');
    }

    final keys = rawKeys
        .map((e) => GamepadKey.fromValue(gmacroToInt(e)))
        .whereType<GamepadKey>()
        .toList();

    return MacroComKeyPayload(
      keys: keys,
      keepTime: gmacroToInt(map['keepTime'], fallback: 100),
      intervalTime: gmacroToInt(map['intervalTime'], fallback: 0),
    );
  }

  @override
  String toString() {
    return 'MacroComKeyPayload('
        'keys: ${keys.map((e) => e.name).toList()}, '
        'keepTime: $keepTime, '
        'intervalTime: $intervalTime)';
  }
}

class MacroKeyPayload {
  const MacroKeyPayload({
    required this.value,
    this.cycle = MacroCycleMode.loop,
    this.intervalTime = 0,
    required this.comKeys,
  });

  final GamepadKey value;
  final MacroCycleMode cycle;
  final int intervalTime;
  final List<MacroComKeyPayload> comKeys;

  Map<String, Object?> toMap() => {
    'value': value.value,
    'cycle': cycle.value,
    'intervalTime': intervalTime,
    'comKeys': comKeys.map((e) => e.toMap()).toList(),
  };

  factory MacroKeyPayload.fromMap(Map<dynamic, dynamic> map) {
    final value = GamepadKey.fromValue(gmacroToInt(map['value']));
    final cycle = MacroCycleMode.fromValue(gmacroToInt(map['cycle']));
    final rawComKeys = map['comKeys'] as List?;

    if (value == null || cycle == null || rawComKeys == null) {
      throw ArgumentError('Invalid MacroKeyPayload map: $map');
    }

    final comKeys = rawComKeys
        .whereType<Map>()
        .map((e) => MacroComKeyPayload.fromMap(e))
        .toList();

    return MacroKeyPayload(
      value: value,
      cycle: cycle,
      intervalTime: gmacroToInt(map['intervalTime'], fallback: 0),
      comKeys: comKeys,
    );
  }

  @override
  String toString() {
    return 'MacroKeyPayload('
        'value: ${value.name}(${value.value}), '
        'cycle: ${cycle.name}, '
        'intervalTime: $intervalTime, '
        'comKeys: $comKeys)';
  }
}
