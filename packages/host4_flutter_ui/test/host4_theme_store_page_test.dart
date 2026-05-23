import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('theme store switches themes through the shared manager', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final catalog = await Host4ThemeAssets.loadCatalog(rootBundle);
    final manager = Host4ThemeManager(catalog: catalog, bundle: rootBundle);
    addTearDown(manager.dispose);
    await manager.initialize(Host4ThemeAssets.defaultThemeId);

    await tester.pumpWidget(
      MaterialApp(
        home: Host4ThemeStorePage(manager: manager),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const ValueKey<String>('host4_theme_store_page')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('host4_theme_store_title')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('host4_theme_card_default')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('host4_theme_card_obsidian')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('host4_theme_card_mint')),
        findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey<String>('host4_theme_card_mint')));
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();

    expect(manager.currentThemeId, 'mint');
    expect(manager.theme.meta.id, 'mint');
  });
}
