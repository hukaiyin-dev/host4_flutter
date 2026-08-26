import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_demo/pages/web_emulator/web_emulator_layout_preference_store.dart';
import 'package:host4_flutter_emulator_ui/host4_flutter_emulator_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('layout preference defaults to silicone', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final store = WebEmulatorLayoutPreferenceStore(preferences);

    expect(await store.load(), Host4EmulatorControlLayoutStyle.silicone);
  });

  test('layout preference persists the upper-layer selection', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final store = WebEmulatorLayoutPreferenceStore(preferences);

    await store.save(Host4EmulatorControlLayoutStyle.modern);

    expect(await store.load(), Host4EmulatorControlLayoutStyle.modern);
  });

  test('silicone variant persists independently from the ROM layout', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      WebEmulatorLayoutPreferenceStore.preferenceKey: 'modern',
    });
    final preferences = await SharedPreferences.getInstance();
    final layoutStore = WebEmulatorLayoutPreferenceStore(preferences);
    final variantStore = WebEmulatorSiliconeLayoutPreferenceStore(preferences);

    await variantStore.save(
      Host4EmulatorSiliconeLayoutVariant.modernAsymmetric,
    );

    expect(await layoutStore.load(), Host4EmulatorControlLayoutStyle.modern);
    expect(
      await variantStore.load(),
      Host4EmulatorSiliconeLayoutVariant.modernAsymmetric,
    );
  });

  testWidgets('ROM selector only exposes traditional and silicone choices', (
    tester,
  ) async {
    Host4EmulatorControlLayoutStyle? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WebEmulatorLayoutSelector(
            value: Host4EmulatorControlLayoutStyle.silicone,
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );

    expect(find.text('通用布局'), findsOneWidget);
    expect(find.text('硅胶布局'), findsOneWidget);
    expect(find.text('现代非对称'), findsNothing);

    await tester.tap(find.text('通用布局'));
    await tester.pump();

    expect(selected, Host4EmulatorControlLayoutStyle.modern);
  });

  test('late stored layout does not override a newer user selection', () async {
    final persistence = _ControlledLayoutPreferencePersistence();
    final coordinator = WebEmulatorLayoutPreferenceCoordinator(
      Future<WebEmulatorLayoutPreferencePersistence>.value(persistence),
    );

    final loading = coordinator.load();
    await persistence.loadStarted.future;

    final saving = coordinator.select(Host4EmulatorControlLayoutStyle.silicone);
    persistence.completeLoad(Host4EmulatorControlLayoutStyle.modern);

    expect(await loading, isNull);
    await saving;
    expect(coordinator.currentStyle, Host4EmulatorControlLayoutStyle.silicone);
    expect(persistence.savedStyle, Host4EmulatorControlLayoutStyle.silicone);
  });
}

class _ControlledLayoutPreferencePersistence
    implements WebEmulatorLayoutPreferencePersistence {
  final Completer<void> loadStarted = Completer<void>();
  final Completer<Host4EmulatorControlLayoutStyle> _loadedStyle =
      Completer<Host4EmulatorControlLayoutStyle>();

  Host4EmulatorControlLayoutStyle? savedStyle;

  @override
  Future<Host4EmulatorControlLayoutStyle> load() {
    loadStarted.complete();
    return _loadedStyle.future;
  }

  void completeLoad(Host4EmulatorControlLayoutStyle style) {
    _loadedStyle.complete(style);
  }

  @override
  Future<void> save(Host4EmulatorControlLayoutStyle style) async {
    savedStyle = style;
  }
}
