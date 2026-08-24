import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_emulator_ui/host4_flutter_emulator_ui.dart';

void main() {
  group('Host4EmulatorInputEvent', () {
    test('accepts the GB GBC and GBA input contract', () {
      const event = Host4EmulatorInputEvent(
        input: 'a',
        phase: Host4EmulatorInputEvent.phaseDown,
        value: 1,
        timestamp: 123,
        source: 'controls.a',
      );

      expect(event.isValid, isTrue);
      expect(event.toMap(), <String, Object?>{
        'input': 'a',
        'phase': 'down',
        'value': 1.0,
        'ts': 123,
      });
    });

    test('rejects unsupported inputs and phases', () {
      const unsupportedInput = Host4EmulatorInputEvent(
        input: 'x',
        phase: Host4EmulatorInputEvent.phaseDown,
        timestamp: 1,
      );
      const unsupportedPhase = Host4EmulatorInputEvent(
        input: 'a',
        phase: 'press',
        timestamp: 1,
      );

      expect(unsupportedInput.isValid, isFalse);
      expect(unsupportedPhase.isValid, isFalse);
    });

    test('coalesces repeated inputs while preserving first-seen order', () {
      const events = <Host4EmulatorInputEvent>[
        Host4EmulatorInputEvent(
          input: 'up',
          phase: Host4EmulatorInputEvent.phaseDown,
          timestamp: 1,
        ),
        Host4EmulatorInputEvent(
          input: 'a',
          phase: Host4EmulatorInputEvent.phaseDown,
          timestamp: 2,
        ),
        Host4EmulatorInputEvent(
          input: 'up',
          phase: Host4EmulatorInputEvent.phaseUp,
          value: 0,
          timestamp: 3,
        ),
      ];

      expect(
        Host4EmulatorInputEvent.coalesce(events),
        <Host4EmulatorInputEvent>[events[2], events[1]],
      );
    });
  });

  group('Host4EmulatorControlProfile', () {
    test('only GBA exposes shoulder buttons', () {
      expect(Host4EmulatorControlProfile.gb.hasShoulderButtons, isFalse);
      expect(Host4EmulatorControlProfile.gbc.hasShoulderButtons, isFalse);
      expect(Host4EmulatorControlProfile.gba.hasShoulderButtons, isTrue);
    });

    test('all three profiles expose the common buttons', () {
      for (final profile in Host4EmulatorControlProfile.values) {
        expect(
          profile.inputs,
          containsAll(<String>[
            'up',
            'down',
            'left',
            'right',
            'a',
            'b',
            'start',
            'select',
          ]),
        );
      }
    });
  });
}
