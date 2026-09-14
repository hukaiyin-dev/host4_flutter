import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_emulator_ui/host4_flutter_emulator_ui.dart';

void main() {
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    for (final landscape in [false, true]) {
      testWidgets(
        'single-finger eight directions $platform landscape=$landscape',
        (tester) async {
          final events = <String>[];
          final rect = await mountPad(tester, events, platform, landscape);
          final directions = <Offset, List<String>>{
            Offset(0, -0.3): ['up'],
            Offset(0.3, 0): ['right'],
            Offset(0, 0.3): ['down'],
            Offset(-0.3, 0): ['left'],
            Offset(-0.15, -0.15): ['up', 'left'],
            Offset(0.15, -0.15): ['up', 'right'],
            Offset(-0.15, 0.15): ['down', 'left'],
            Offset(0.15, 0.15): ['down', 'right'],
            Offset(-0.2, -0.12): ['up', 'left'],
            Offset(-0.12, -0.2): ['up', 'left'],
          };
          for (final entry in directions.entries) {
            events.clear();
            final finger = await tester.startGesture(
              rect.center +
                  Offset(rect.width * entry.key.dx, rect.height * entry.key.dy),
            );
            await tester.pump(const Duration(seconds: 2));
            expect(events, entry.value.map((d) => '$d:down').toList());
            await finger.up();
            expect(events, [
              ...entry.value.map((d) => '$d:down'),
              ...entry.value.map((d) => '$d:up'),
            ]);
          }
          events.clear();
          await tester.tapAt(rect.center + Offset(rect.width * 0.02, 0));
          expect(events, isEmpty);
        },
      );
    }
  }

  testWidgets('diagonal slide and cancel preserve another finger holding up', (
    tester,
  ) async {
    final events = <String>[];
    final rect = await mountPad(tester, events, TargetPlatform.iOS, false);
    final up = await tester.startGesture(
      rect.center - Offset(0, rect.height * 0.3),
      pointer: 1,
    );
    final diagonal = await tester.startGesture(
      rect.center - Offset(rect.width * 0.15, rect.height * 0.15),
      pointer: 2,
    );
    expect(events, ['up:down', 'left:down']);
    await diagonal.moveTo(
      rect.center + Offset(rect.width * 0.2, -rect.height * 0.2),
    );
    expect(events, ['up:down', 'left:down', 'right:down', 'left:up']);
    await diagonal.cancel();
    expect(events.last, 'right:up');
    expect(events.where((e) => e == 'up:up'), isEmpty);
    await up.moveTo(rect.center);
    expect(events.last, 'up:up');
    await up.moveTo(rect.center - Offset(rect.width, rect.height));
    await up.up();
    expect(events, [
      'up:down',
      'left:down',
      'right:down',
      'left:up',
      'right:up',
      'up:up',
    ]);
  });
}

Future<Rect> mountPad(
  WidgetTester tester,
  List<String> events,
  TargetPlatform platform,
  bool landscape,
) async {
  tester.view.physicalSize = landscape
      ? const Size(844, 390)
      : const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(platform: platform),
      home: Host4EmulatorControlsLayer(
        profile: Host4EmulatorControlProfile.nes,
        layoutStyle: Host4EmulatorControlLayoutStyle.silicone,
        onInput: (e) => events.add('${e.input}:${e.phase}'),
        onMenuTap: () {},
      ),
    ),
  );
  return tester.getRect(
    find.byKey(
      ValueKey<String>(
        landscape ? 'landscape.controls.dpad_left' : 'game.controls.dpad',
      ),
    ),
  );
}
