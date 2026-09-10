import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_emulator_ui/host4_flutter_emulator_ui.dart';

void main() {
  const metrics = Host4EmulatorSiliconeMetrics(logicalPixelsPerMillimeter: 4);
  test(
    'portrait pad can cross above LR and LR returns above when dragged down',
    () {
      Host4EmulatorSiliconeResolvedLayout resolve(double? position) =>
          Host4EmulatorSiliconeLayoutResolver.portrait(
            screenSize: const Size(390, 844),
            metrics: metrics,
            topInset: 47,
            bottomInset: 34,
            padPosition: position,
          );
      final initial = resolve(null);
      final upper = resolve(0);
      final lower = resolve(1);
      final upperPad = upper.padBounds[Host4EmulatorSiliconePadSide.single]!;
      expect(upperPad.top, 464);
      for (final id in ['game.controls.btn_l', 'game.controls.btn_r']) {
        expect(
          upper.controls[id]!.visualRect.top,
          greaterThanOrEqualTo(upperPad.bottom),
        );
        expect(upper.controls[id]!.visualRect.bottom, lessThanOrEqualTo(810));
        expect(
          lower.controls[id]!.visualRect.bottom,
          lessThanOrEqualTo(
            lower.padBounds[Host4EmulatorSiliconePadSide.single]!.top,
          ),
        );
        expect(
          lower.controls[id]!.visualRect.top - initial.controls[id]!.visualRect.top,
          closeTo(lower.padBounds[Host4EmulatorSiliconePadSide.single]!.top -
              initial.padBounds[Host4EmulatorSiliconePadSide.single]!.top, 0.001),
        );
        expect(lower.padBounds[Host4EmulatorSiliconePadSide.single]!.top -
            lower.controls[id]!.visualRect.bottom, closeTo(12, 0.001));
      }
      expect(
        upper.controls['game.controls.btn_set']!.visualRect,
        lower.controls['game.controls.btn_set']!.visualRect,
      );
    },
  );
  test('game viewport reserves the toolbar only in portrait', () {
    expect(
      Host4EmulatorSiliconeLayoutResolver.gameViewport(
        screenSize: const Size(390, 844),
        topInset: 47,
        bottomInset: 34,
      ),
      const Rect.fromLTWH(0, 113, 390, 351),
    );
    expect(
      Host4EmulatorSiliconeLayoutResolver.gameViewport(
        screenSize: const Size(844, 390),
        topInset: 47,
        bottomInset: 34,
      ),
      const Rect.fromLTWH(0, 0, 844, 390),
    );
  });
  testWidgets('portrait dragging clamps below game and never moves toolbar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final positions = <String, double>{};
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              padding: EdgeInsets.only(top: 47, bottom: 34),
            ),
            child: Host4EmulatorControlsLayer(
              profile: Host4EmulatorControlProfile.nes,
              layoutStyle: Host4EmulatorControlLayoutStyle.silicone,
              editing: true,
              padPositions: positions,
              onPadPositionChanged: (key, value) =>
                  setState(() => positions[key] = value),
              onLocateTap: () {},
              onMenuTap: () {},
              onInput: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final pad = find.byKey(
      const ValueKey('controls.pad_background.portrait.single'),
    );
    final buttons = [
      'btn_set',
      'btn_locate_placeholder',
      'btn_hide_toggle',
    ].map((id) => find.byKey(ValueKey('game.controls.$id'))).toList();
    final before = buttons.map(tester.getRect).toList();
    for (final delta in [-1000.0, 1000.0]) {
      final gesture = await tester.startGesture(tester.getCenter(pad));
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.moveBy(Offset(0, delta));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(positions, contains('portrait.single'));
      expect(tester.getRect(pad).top, greaterThanOrEqualTo(464));
      expect(tester.getRect(pad).bottom, lessThanOrEqualTo(810));
      expect(buttons.map(tester.getRect).toList(), before);
    }
  });
  test(
    'portrait toolbar stays above the game for every saved pad position',
    () {
      for (final position in [-1.0, 0.5, 1.0]) {
        final layout = Host4EmulatorSiliconeLayoutResolver.portrait(
          screenSize: const Size(390, 844),
          metrics: metrics,
          topInset: 47,
          bottomInset: 34,
          padPosition: position,
        );
        for (final id in [
          'btn_set',
          'btn_locate_placeholder',
          'btn_hide_toggle',
        ]) {
          final button = layout.controls['game.controls.$id']!;
          expect(button.visualRect.top, 59);
          expect(button.visualRect.bottom, lessThan(layout.gameViewportTop));
        }
        expect(layout.gameViewportTop, 113);
      }
    },
  );
  test(
    'saved portrait pads cannot enter the Delta game area or bottom inset',
    () {
      for (final position in [-1.0, 0.5, 1.0]) {
        final layout = Host4EmulatorSiliconeLayoutResolver.portrait(
          screenSize: const Size(390, 844),
          metrics: metrics,
          topInset: 47,
          bottomInset: 34,
          padPosition: position,
        );
        // 47 safe inset + 66 toolbar + 351 (390 / (10 / 9)) game area.
        final pad = layout.padBounds[Host4EmulatorSiliconePadSide.single]!;
        expect(pad.top, greaterThanOrEqualTo(464));
        expect(pad.bottom, lessThanOrEqualTo(810));
        expect(
          layout.controls['game.controls.btn_l']!.visualRect.top,
          greaterThanOrEqualTo(464),
        );
      }
    },
  );
}
