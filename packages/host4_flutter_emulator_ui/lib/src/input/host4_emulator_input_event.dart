import 'package:flutter/foundation.dart';

@immutable
class Host4EmulatorInputEvent {
  const Host4EmulatorInputEvent({
    required this.input,
    required this.phase,
    this.value = 1,
    required this.timestamp,
    this.source,
  });

  static const String phaseDown = 'down';
  static const String phaseUp = 'up';

  static const Set<String> validInputs = <String>{
    'up',
    'down',
    'left',
    'right',
    'a',
    'b',
    'x',
    'y',
    'l',
    'r',
    'start',
    'select',
  };

  final String input;
  final String phase;
  final double value;
  final int timestamp;
  final String? source;

  bool get isValid =>
      validInputs.contains(input) && (phase == phaseDown || phase == phaseUp);

  Map<String, Object?> toMap() => <String, Object?>{
    'input': input,
    'phase': phase,
    'value': value,
    'ts': timestamp,
  };

  static List<Host4EmulatorInputEvent> coalesce(
    List<Host4EmulatorInputEvent> events,
  ) {
    final order = <String>[];
    final latest = <String, Host4EmulatorInputEvent>{};
    for (final event in events) {
      if (!latest.containsKey(event.input)) order.add(event.input);
      latest[event.input] = event;
    }
    return order.map((input) => latest[input]!).toList(growable: false);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Host4EmulatorInputEvent &&
          input == other.input &&
          phase == other.phase &&
          value == other.value &&
          timestamp == other.timestamp &&
          source == other.source;

  @override
  int get hashCode => Object.hash(input, phase, value, timestamp, source);
}
