import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_emulator_ui/host4_flutter_emulator_ui.dart';

void main() {
  test('D-pad hit model supports diagonal directions', () {
    expect(host4EmulatorDPadInputsAt(const Offset(5, 5), 120, 120), <String>{
      'up',
      'left',
    });
    expect(
      host4EmulatorDPadInputsAt(const Offset(115, 115), 120, 120),
      <String>{'down', 'right'},
    );
    expect(host4EmulatorDPadInputsAt(const Offset(60, 60), 120, 120), isEmpty);
  });

  testWidgets('D-pad sends matching down and up events', (tester) async {
    final events = <Host4EmulatorInputEvent>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Center(child: Host4EmulatorDPad(size: 120, onEvent: events.add)),
      ),
    );

    final center = tester.getCenter(find.byType(Host4EmulatorDPad));
    final gesture = await tester.startGesture(
      center + const Offset(-55, -55),
      pointer: 1,
    );
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(events.map((event) => '${event.input}:${event.phase}'), <String>[
      'up:down',
      'left:down',
      'up:up',
      'left:up',
    ]);
  });

  testWidgets('controls expose common buttons and GBA shoulders', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 844,
          height: 390,
          child: Host4EmulatorControlsLayer(
            profile: Host4EmulatorControlProfile.gba,
            onInput: (_) {},
            onMenuTap: () {},
          ),
        ),
      ),
    );

    for (final input in <String>['a', 'b', 'start', 'select', 'l', 'r']) {
      expect(find.byKey(ValueKey<String>('controls.$input')), findsOneWidget);
    }

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 844,
          height: 390,
          child: Host4EmulatorControlsLayer(
            profile: Host4EmulatorControlProfile.gbc,
            onInput: (_) {},
            onMenuTap: () {},
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey<String>('controls.l')), findsNothing);
    expect(find.byKey(const ValueKey<String>('controls.r')), findsNothing);
  });

  testWidgets('action buttons send down up and cancel-safe events', (
    tester,
  ) async {
    final events = <Host4EmulatorInputEvent>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Host4EmulatorActionButton(
          input: 'a',
          label: 'A',
          diameter: 48,
          onEvent: events.add,
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(Host4EmulatorActionButton)),
    );
    await tester.pump();
    await gesture.cancel();
    await tester.pump();

    expect(events.map((event) => event.phase), <String>[
      Host4EmulatorInputEvent.phaseDown,
      Host4EmulatorInputEvent.phaseUp,
    ]);
  });
}
