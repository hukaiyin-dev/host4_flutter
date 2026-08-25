import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_emulator_ui/host4_flutter_emulator_ui.dart';
import 'package:display_metrics/display_metrics.dart';

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

  testWidgets('silicone layout owns its display metrics provider', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 390,
          height: 844,
          child: Host4EmulatorControlsLayer(
            profile: Host4EmulatorControlProfile.gba,
            layoutStyle: Host4EmulatorControlLayoutStyle.silicone,
            onInput: (_) {},
            onMenuTap: () {},
          ),
        ),
      ),
    );

    expect(find.byType(DisplayMetricsWidget), findsOneWidget);
  });

  testWidgets('portrait silicone keeps the full Pantas pad for GB', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Host4EmulatorControlsLayer(
          profile: Host4EmulatorControlProfile.gb,
          layoutStyle: Host4EmulatorControlLayoutStyle.silicone,
          onInput: (_) {},
          onMenuTap: () {},
        ),
      ),
    );

    for (final input in <String>['x', 'y', 'a', 'b']) {
      expect(
        find.byKey(ValueKey<String>('game.controls.btn_$input')),
        findsOneWidget,
      );
    }
    for (final input in <String>['l', 'r']) {
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Host4EmulatorSiliconeSmallButton &&
              widget.inputName == input,
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('portrait silicone exposes menu and hide system buttons', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var menuTapCount = 0;
    var locateTapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Host4EmulatorControlsLayer(
          profile: Host4EmulatorControlProfile.gb,
          layoutStyle: Host4EmulatorControlLayoutStyle.silicone,
          onInput: (_) {},
          onMenuTap: () => menuTapCount += 1,
          onLocateTap: () => locateTapCount += 1,
        ),
      ),
    );

    final menu = find.byKey(const ValueKey<String>('game.controls.btn_set'));
    final hide = find.byKey(
      const ValueKey<String>('game.controls.btn_hide_toggle'),
    );
    final locate = find.byKey(
      const ValueKey<String>('game.controls.btn_locate_placeholder'),
    );
    expect(menu, findsOneWidget);
    expect(hide, findsOneWidget);
    expect(locate, findsOneWidget);

    await tester.tap(menu);
    await tester.pump();
    expect(menuTapCount, 1);

    await tester.tap(locate);
    await tester.pump();
    expect(locateTapCount, 1);

    await tester.tap(hide);
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('game.controls.btn_a')),
      findsNothing,
    );
    expect(menu, findsNothing);
    expect(hide, findsOneWidget);

    await tester.tap(hide);
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('game.controls.btn_a')),
      findsOneWidget,
    );
    expect(menu, findsOneWidget);
  });

  testWidgets('silicone layout only exposes shoulder inputs for GBA', (
    tester,
  ) async {
    Future<void> pumpProfile(Host4EmulatorControlProfile profile) {
      return tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 844,
            height: 390,
            child: Host4EmulatorControlsLayer(
              profile: profile,
              layoutStyle: Host4EmulatorControlLayoutStyle.silicone,
              onInput: (_) {},
              onMenuTap: () {},
            ),
          ),
        ),
      );
    }

    await pumpProfile(Host4EmulatorControlProfile.gbc);
    expect(
      find.byKey(const ValueKey<String>('landscape.controls.btn_l1')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('landscape.controls.btn_r1')),
      findsNothing,
    );

    await pumpProfile(Host4EmulatorControlProfile.gba);
    expect(
      find.byKey(const ValueKey<String>('landscape.controls.btn_l1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('landscape.controls.btn_r1')),
      findsOneWidget,
    );
  });

  testWidgets('active silicone SET button is independently tappable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: <Widget>[
            const ColoredBox(color: Color(0xCC121A29)),
            Host4EmulatorActiveMenuButton(
              layoutStyle: Host4EmulatorControlLayoutStyle.silicone,
              onTap: () => tapCount += 1,
            ),
          ],
        ),
      ),
    );

    final activeSet = find.byKey(
      const ValueKey<String>('controls.active_menu'),
    );
    expect(activeSet, findsOneWidget);
    await tester.tap(activeSet);
    await tester.pump();
    expect(tapCount, 1);
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
