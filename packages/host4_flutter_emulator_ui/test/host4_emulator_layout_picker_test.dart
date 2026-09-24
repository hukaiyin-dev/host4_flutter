import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_emulator_ui/host4_flutter_emulator_ui.dart';

void main() {
  testWidgets(
    'layout picker takes focus, navigates, confirms with A and returns with B',
    (tester) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Host4EmulatorSiliconeLayoutVariant? selected;
      var backs = 0;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates:
              EmulatorUiLocalizations.localizationsDelegates,
          supportedLocales: EmulatorUiLocalizations.supportedLocales,
          home: Host4EmulatorUiShortcuts(
            onBack: () => backs++,
            child: Host4EmulatorSiliconeLayoutPicker(
              selectedVariant: Host4EmulatorSiliconeLayoutVariant.silicone,
              onSelected: (value) => selected = value,
              onBack: () => backs++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonA);
      await tester.pumpAndSettle();
      expect(selected, Host4EmulatorSiliconeLayoutVariant.retroTraditional);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonA);
      await tester.pumpAndSettle();
      expect(selected, Host4EmulatorSiliconeLayoutVariant.modernAsymmetric);
      await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonB);
      await tester.pump();
      expect(backs, 1);
    },
  );
  testWidgets('shows the four Pantas layout choices and reports selection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Host4EmulatorSiliconeLayoutVariant? selected;
    var backed = false;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: EmulatorUiLocalizations.localizationsDelegates,
        supportedLocales: EmulatorUiLocalizations.supportedLocales,
        home: Host4EmulatorSiliconeLayoutPicker(
          selectedVariant: Host4EmulatorSiliconeLayoutVariant.silicone,
          onSelected: (variant) => selected = variant,
          onBack: () => backed = true,
        ),
      ),
    );

    for (final identifier in <String>[
      'layout.option.retro_traditional',
      'layout.option.silicone',
      'layout.option.modern_symmetric',
      'layout.option.modern_asymmetric',
    ]) {
      expect(find.byKey(ValueKey<String>(identifier)), findsOneWidget);
    }
    expect(find.text('复古传统'), findsOneWidget);
    expect(find.text('硅胶垫'), findsOneWidget);
    expect(find.text('现代对称'), findsOneWidget);
    expect(find.text('现代非对称'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('layout.option.modern_asymmetric')),
    );
    await tester.pump();
    expect(selected, Host4EmulatorSiliconeLayoutVariant.modernAsymmetric);

    await tester.tap(find.byKey(const ValueKey<String>('layout.back')));
    expect(backed, isTrue);
  });
}
