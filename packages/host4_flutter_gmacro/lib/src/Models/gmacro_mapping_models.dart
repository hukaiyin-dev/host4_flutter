import 'gmacro_gamepad_key.dart';
import 'gmacro_model_parsers.dart';

class GamepadKeyMappingPayload {
  const GamepadKeyMappingPayload({
    required this.original,
    required this.mapped,
  });

  final GamepadKey original;
  final GamepadKey mapped;

  Map<String, Object?> toMap() => {
    'original': original.value,
    'mapped': mapped.value,
  };

  factory GamepadKeyMappingPayload.fromMap(Map<dynamic, dynamic> map) {
    final originalRaw = map['original'];
    final mappedRaw = map['mapped'];

    final original = GamepadKey.fromValue(gmacroToInt(originalRaw));
    final mapped = GamepadKey.fromValue(gmacroToInt(mappedRaw));

    if (original == null || mapped == null) {
      throw ArgumentError('Invalid GamepadKeyMappingPayload map: $map');
    }

    return GamepadKeyMappingPayload(original: original, mapped: mapped);
  }

  @override
  String toString() {
    return 'GamepadKeyMappingPayload('
        'original: ${original.name}(${original.value}), '
        'mapped: ${mapped.name}(${mapped.value}))';
  }
}

class MouseKeyMappingPayload {
  const MouseKeyMappingPayload({required this.original, required this.mapped});

  final GamepadKey original;

  /// MouseKey rawValue
  final int mapped;

  Map<String, Object?> toMap() => {
    'original': original.value,
    'mapped': mapped,
  };

  factory MouseKeyMappingPayload.fromMap(Map<dynamic, dynamic> map) {
    final original = GamepadKey.fromValue(gmacroToInt(map['original']));
    if (original == null) {
      throw ArgumentError('Invalid MouseKeyMappingPayload map: $map');
    }

    return MouseKeyMappingPayload(
      original: original,
      mapped: gmacroToInt(map['mapped']),
    );
  }

  @override
  String toString() {
    return 'MouseKeyMappingPayload('
        'original: ${original.name}(${original.value}), '
        'mapped: $mapped)';
  }
}

class KeyboardKeyMappingPayload {
  const KeyboardKeyMappingPayload({
    required this.original,
    required this.mapped,
  });

  final GamepadKey original;

  /// KeyboardKey rawValue
  final int mapped;

  Map<String, Object?> toMap() => {
    'original': original.value,
    'mapped': mapped,
  };

  factory KeyboardKeyMappingPayload.fromMap(Map<dynamic, dynamic> map) {
    final original = GamepadKey.fromValue(gmacroToInt(map['original']));
    if (original == null) {
      throw ArgumentError('Invalid KeyboardKeyMappingPayload map: $map');
    }

    return KeyboardKeyMappingPayload(
      original: original,
      mapped: gmacroToInt(map['mapped']),
    );
  }

  @override
  String toString() {
    return 'KeyboardKeyMappingPayload('
        'original: ${original.name}(${original.value}), '
        'mapped: $mapped)';
  }
}

enum MappedKeyType {
  gamepad(0),
  mouse(1),
  keyboard(2);

  const MappedKeyType(this.value);

  final int value;

  static MappedKeyType? fromValue(int value) {
    for (final item in MappedKeyType.values) {
      if (item.value == value) return item;
    }
    return null;
  }
}

class MappedKeyPayload {
  MappedKeyPayload.gamepad({required List<GamepadKey> values})
    : this(
        type: MappedKeyType.gamepad,
        values: values.map((e) => e.value).toList(),
      );

  const MappedKeyPayload.mouse({required List<int> values})
    : this(type: MappedKeyType.mouse, values: values);

  const MappedKeyPayload.keyboard({required List<int> values})
    : this(type: MappedKeyType.keyboard, values: values);

  const MappedKeyPayload({required this.type, required this.values});

  final MappedKeyType type;

  /// Raw key values.
  /// - gamepad: GamepadKey one-byte key codes
  /// - mouse: MouseKey rawValue list
  /// - keyboard: KeyboardKey rawValue list
  final List<int> values;

  Map<String, Object?> toMap() => {'type': type.value, 'values': values};

  factory MappedKeyPayload.fromMap(Map<dynamic, dynamic> map) {
    final type = MappedKeyType.fromValue(gmacroToInt(map['type']));
    final rawValues = (map['values'] as List?)?.map(gmacroToInt).toList();

    if (type == null || rawValues == null) {
      throw ArgumentError('Invalid MappedKeyPayload map: $map');
    }

    return MappedKeyPayload(type: type, values: rawValues);
  }

  @override
  String toString() {
    return 'MappedKeyPayload(type: ${type.name}, values: $values)';
  }
}
