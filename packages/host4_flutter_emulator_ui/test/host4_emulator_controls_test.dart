import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_emulator_ui/host4_flutter_emulator_ui.dart';
import 'package:display_metrics/display_metrics.dart';

void main() {
  testWidgets('landscape menu and collapse retain visible circular backgrounds', (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var menus = 0;
    for (final variant in Host4EmulatorSiliconeLayoutVariant.values.where((v) => v != Host4EmulatorSiliconeLayoutVariant.silicone)) {
      await tester.pumpWidget(MaterialApp(home: ColoredBox(color: Colors.black,
        child: Host4EmulatorControlsLayer(
          key: ValueKey(variant), profile: Host4EmulatorControlProfile.nes,
          layoutStyle: Host4EmulatorControlLayoutStyle.silicone,
          siliconeLayoutVariant: variant, onInput: (_) {}, onMenuTap: () => menus++,
        ),
      )));
      final menu = find.byKey(const ValueKey('controls.system_background.logo_group.svg'));
      final hide = find.byKey(const ValueKey('controls.system_background.ic_expand.svg'));
      expect(menu, findsOneWidget);
      expect(hide, findsOneWidget);
      expect((tester.widget<DecoratedBox>(hide).decoration as BoxDecoration).color, const Color(0xA6FFFFFF));
      await tester.tap(menu);
      await tester.tap(hide);
      await tester.pumpAndSettle();
      expect(menu, findsNothing);
      expect(hide, findsOneWidget);
      await tester.tap(hide);
      await tester.pumpAndSettle();
      expect(menu, findsOneWidget);
    }
    expect(menus, 3);
  });
  testWidgets('landscape capsules keep outlines and gain editing backgrounds', (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Future<void> show(bool editing) => tester.pumpWidget(MaterialApp(
      home: Host4EmulatorControlsLayer(
        profile: Host4EmulatorControlProfile.nes,
        layoutStyle: Host4EmulatorControlLayoutStyle.silicone,
        editing: editing,
        onInput: (_) {}, onMenuTap: () {},
      ),
    ));
    await show(false);
    for (final side in ['left', 'right']) {
      final finder = find.byKey(ValueKey<String>('controls.pad_background.landscape.$side'));
      expect(finder, findsOneWidget);
      final decoration = tester.widget<DecoratedBox>(finder).decoration as BoxDecoration;
      expect(decoration.color, isNull);
      expect(decoration.border!.top.color, const Color(0x66FFFFFF));
    }
    final before = tester.getRect(find.byKey(const ValueKey<String>('landscape.controls.btn_a')));
    await show(true);
    for (final side in ['left', 'right']) {
      final finder = find.byKey(ValueKey<String>('controls.pad_background.landscape.$side'));
      final decoration = tester.widget<DecoratedBox>(finder).decoration as BoxDecoration;
      expect(decoration.color, const Color(0x99FFFFFF));
      expect(decoration.border!.top.color, const Color(0xCCFFFFFF));
    }
    expect(tester.getRect(find.byKey(const ValueKey<String>('landscape.controls.btn_a'))), before);
  });
  testWidgets('editing adds capsule fill without moving controls or sending input', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final events = <Host4EmulatorInputEvent>[];
    Future<void> show(bool editing) => tester.pumpWidget(MaterialApp(
      home: Host4EmulatorControlsLayer(
        profile: Host4EmulatorControlProfile.gba,
        layoutStyle: Host4EmulatorControlLayoutStyle.silicone,
        editing: editing,
        onInput: events.add,
        onMenuTap: () {},
      ),
    ));
    final pad = find.byKey(const ValueKey<String>('game.controls.dpad'));
    final background = find.byKey(const ValueKey<String>('controls.pad_background.portrait.single'));
    await show(false);
    final before = tester.getRect(pad);
    expect((tester.widget<DecoratedBox>(background).decoration as BoxDecoration).color, isNull);
    await show(true);
    final decoration = tester.widget<DecoratedBox>(background).decoration as BoxDecoration;
    expect(decoration.color, const Color(0x99FFFFFF));
    expect(decoration.border!.top.color, const Color(0xCCFFFFFF));
    expect(decoration.border!.top.width, 2);
    expect(tester.getRect(pad), before);
    await tester.tapAt(before.topCenter + const Offset(0, 10));
    expect(events, isEmpty);
    await show(false);
    expect((tester.widget<DecoratedBox>(background).decoration as BoxDecoration).color, isNull);
  });

  for (final profile in Host4EmulatorControlProfile.values) {
    for (final landscape in [true, false]) {
      testWidgets(
        '${profile.name} silicone D-pad follows screen directions in ${landscape ? "landscape" : "portrait"}',
        (tester) async {
          tester.view.physicalSize = landscape
              ? const Size(844, 390)
              : const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final events = <Host4EmulatorInputEvent>[];
          await tester.pumpWidget(
            MaterialApp(
              home: Host4EmulatorControlsLayer(
                profile: profile,
                layoutStyle: Host4EmulatorControlLayoutStyle.silicone,
                onInput: events.add,
                onMenuTap: () {},
              ),
            ),
          );
          final rect = tester.getRect(
            find.byKey(
              ValueKey<String>(
                landscape
                    ? 'landscape.controls.dpad_left'
                    : 'game.controls.dpad',
              ),
            ),
          );
          const points = <String, Offset>{
            'up': Offset(0.5, 0.15),
            'down': Offset(0.5, 0.85),
            'left': Offset(0.15, 0.5),
            'right': Offset(0.85, 0.5),
          };
          for (final point in points.entries) {
            events.clear();
            final gesture = await tester.startGesture(
              rect.topLeft +
                  Offset(
                    rect.width * point.value.dx,
                    rect.height * point.value.dy,
                  ),
            );
            await gesture.up();
            expect(events.map((event) => '${event.input}:${event.phase}'), [
              '${point.key}:down',
              '${point.key}:up',
            ]);
          }
        },
      );
    }
  }

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

  testWidgets('portrait always keeps the single Pantas silicone pad', (
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
          siliconeLayoutVariant:
              Host4EmulatorSiliconeLayoutVariant.modernAsymmetric,
          onInput: (_) {},
          onMenuTap: () {},
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('game.controls.dpad')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('controls.dpad')), findsNothing);
  });

  testWidgets('landscape SNES silicone exposes all four face buttons', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Host4EmulatorControlsLayer(
          profile: Host4EmulatorControlProfile.snes,
          layoutStyle: Host4EmulatorControlLayoutStyle.silicone,
          onInput: (_) {},
          onMenuTap: () {},
        ),
      ),
    );

    for (final input in <String>['a', 'b', 'x', 'y']) {
      expect(
        find.byKey(ValueKey<String>('landscape.controls.btn_$input')),
        findsOneWidget,
      );
    }
  });

  testWidgets('landscape styles use the Pantas control positions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> pumpVariant(Host4EmulatorSiliconeLayoutVariant variant) {
      return tester.pumpWidget(
        MaterialApp(
          home: Host4EmulatorControlsLayer(
            profile: Host4EmulatorControlProfile.gba,
            layoutStyle: Host4EmulatorControlLayoutStyle.silicone,
            siliconeLayoutVariant: variant,
            onInput: (_) {},
            onMenuTap: () {},
          ),
        ),
      );
    }

    await pumpVariant(Host4EmulatorSiliconeLayoutVariant.modernSymmetric);
    expect(
      tester.getTopLeft(
        find.byKey(const ValueKey<String>('landscape.controls.dpad_left')),
      ),
      const Offset(66, 132),
    );
    expect(
      tester.getTopLeft(
        find.byKey(const ValueKey<String>('landscape.controls.stick_left')),
      ),
      const Offset(231, 215),
    );

    await pumpVariant(Host4EmulatorSiliconeLayoutVariant.modernAsymmetric);
    expect(
      tester.getTopLeft(
        find.byKey(const ValueKey<String>('landscape.controls.stick_left')),
      ),
      const Offset(66, 132),
    );
    expect(
      tester.getTopLeft(
        find.byKey(const ValueKey<String>('landscape.controls.dpad_left')),
      ),
      const Offset(231, 215),
    );

    await pumpVariant(Host4EmulatorSiliconeLayoutVariant.retroTraditional);
    expect(
      tester.getTopLeft(
        find.byKey(const ValueKey<String>('landscape.controls.stick_left')),
      ),
      const Offset(112, 157),
    );
    expect(
      find.byKey(
        const ValueKey<String>('landscape.controls.retro_mode_toggle'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('switched landscape controls show press and stick feedback', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Host4EmulatorControlsLayer(
          profile: Host4EmulatorControlProfile.gba,
          layoutStyle: Host4EmulatorControlLayoutStyle.silicone,
          siliconeLayoutVariant:
              Host4EmulatorSiliconeLayoutVariant.modernSymmetric,
          onInput: (_) {},
          onMenuTap: () {},
        ),
      ),
    );

    final action = find.byKey(const ValueKey<String>('controls.a'));
    final actionOpacity = find.descendant(
      of: action,
      matching: find.byType(AnimatedOpacity),
    );
    final actionGesture = await tester.startGesture(tester.getCenter(action));
    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.widget<AnimatedOpacity>(actionOpacity).opacity, 0.85);
    await actionGesture.up();

    final stick = find.byKey(
      const ValueKey<String>('landscape.controls.stick_left'),
    );
    final thumb = find.byKey(
      const ValueKey<String>('landscape.controls.stick_left.thumb'),
    );
    expect(tester.widget<Transform>(thumb).transform.getTranslation().x, 0);
    final stickGesture = await tester.startGesture(tester.getCenter(stick));
    await stickGesture.moveBy(const Offset(45, 0));
    await tester.pump();
    expect(
      tester.widget<Transform>(thumb).transform.getTranslation().x,
      greaterThan(0),
    );
    await stickGesture.up();
    await tester.pump();
    expect(tester.widget<Transform>(thumb).transform.getTranslation().x, 0);
  });

  testWidgets('retro mode toggle shows pressed feedback', (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Host4EmulatorControlsLayer(
          profile: Host4EmulatorControlProfile.gba,
          layoutStyle: Host4EmulatorControlLayoutStyle.silicone,
          siliconeLayoutVariant:
              Host4EmulatorSiliconeLayoutVariant.retroTraditional,
          onInput: (_) {},
          onMenuTap: () {},
        ),
      ),
    );

    final toggle = find.byKey(
      const ValueKey<String>('landscape.controls.retro_mode_toggle'),
    );
    final opacity = find.descendant(
      of: toggle,
      matching: find.byType(AnimatedOpacity),
    );
    final gesture = await tester.startGesture(tester.getCenter(toggle));
    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.widget<AnimatedOpacity>(opacity).opacity, 0.85);
    await gesture.up();
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

  testWidgets('Gamepatch keeps full buttons independently of core profile', (
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
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('landscape.controls.btn_r1')),
      findsOneWidget,
    );
    for (final profile in Host4EmulatorControlProfile.values) {
      await pumpProfile(profile);
      for (final button in ['a', 'b', 'x', 'y', 'l1', 'r1', 'l2', 'r2', 'start', 'select']) {
        expect(find.byKey(ValueKey<String>('landscape.controls.btn_$button')), findsOneWidget,
          reason: '${profile.name}: $button must not be hidden');
      }
    }

    await pumpProfile(Host4EmulatorControlProfile.gba);
    expect(
      find.byKey(const ValueKey<String>('landscape.controls.btn_l1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('landscape.controls.btn_r1')),
      findsOneWidget,
    );

    await pumpProfile(Host4EmulatorControlProfile.snes);
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

  testWidgets('active silicone variant SET keeps its Pantas position', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Host4EmulatorActiveMenuButton(
          layoutStyle: Host4EmulatorControlLayoutStyle.silicone,
          siliconeLayoutVariant:
              Host4EmulatorSiliconeLayoutVariant.modernAsymmetric,
          onTap: () {},
        ),
      ),
    );

    expect(
      tester.getTopLeft(
        find.byKey(const ValueKey<String>('controls.active_menu')),
      ),
      const Offset(401, 336),
    );
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
