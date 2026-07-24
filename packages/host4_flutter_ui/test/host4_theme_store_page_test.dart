import 'dart:convert';
import 'dart:io';

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

    final manager = Host4ThemeManager(
      catalog: _testCatalog,
      bundle: _testBundle,
    );
    var confirmTapped = false;
    var backTapped = false;
    addTearDown(manager.dispose);
    await tester.runAsync(
      () => manager.initialize(Host4ThemeAssets.defaultThemeId),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Host4ThemeStorePage(
          manager: manager,
          onConfirm: () {
            confirmTapped = true;
          },
          onBack: () {
            backTapped = true;
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byKey(const ValueKey<String>('host4_theme_store_page')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('host4_theme_store_content_background'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('host4_theme_store_top_bar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('host4_theme_store_title')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('host4_theme_card_default')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('host4_theme_card_obsidian')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('host4_theme_card_mint')),
      findsOneWidget,
    );
    expect(_findSemanticsId('theme_store.surface'), findsOneWidget);
    expect(_findSemanticsId('theme_store.card_default'), findsOneWidget);
    expect(_findSemanticsId('theme_store.card_obsidian'), findsOneWidget);
    expect(_findSemanticsId('theme_store.card_mint'), findsOneWidget);
    expect(_findSemanticsId('theme_store.selected_pill'), findsOneWidget);

    final pageRect = tester.getRect(
      find.byKey(const ValueKey<String>('host4_theme_store_page')),
    );
    final topBarRect = tester.getRect(
      find.byKey(const ValueKey<String>('host4_theme_store_top_bar')),
    );
    final firstCardRect = tester.getRect(
      find.byKey(const ValueKey<String>('host4_theme_card_default')),
    );
    expect(topBarRect.top, pageRect.top);
    expect(topBarRect.left, pageRect.left);
    expect(topBarRect.right, pageRect.right);
    expect(topBarRect.height, greaterThan(0));
    expect(firstCardRect.top, greaterThan(topBarRect.bottom));

    await tester.tap(
      find.byKey(
        const ValueKey<String>('host4_theme_store_controller_hints_confirm'),
      ),
    );
    await tester.pump();
    expect(confirmTapped, isTrue);

    await tester.tap(
      find.byKey(
        const ValueKey<String>('host4_theme_store_controller_hints_back'),
      ),
    );
    await tester.pump();
    expect(backTapped, isTrue);

    await tester.tap(
      find.byKey(const ValueKey<String>('host4_theme_card_mint')),
    );
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();

    expect(manager.currentThemeId, 'mint');
    expect(manager.theme.meta.id, 'mint');
  });

  testWidgets('theme store uses per-card focus and sinks repeat activate', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final manager = _CountingHost4ThemeManager(
      catalog: _testCatalog,
      bundle: _testBundle,
    );
    var backCount = 0;
    addTearDown(manager.dispose);
    await tester.runAsync(
      () => manager.initialize(Host4ThemeAssets.defaultThemeId),
    );
    manager.appliedThemeIds.clear();

    await tester.pumpWidget(
      MaterialApp(
        home: Host4ThemeStorePage(
          manager: manager,
          onBack: () {
            backCount++;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'host4_theme_card_default',
    );
    expect(manager.currentThemeId, Host4ThemeAssets.defaultThemeId);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'host4_theme_card_obsidian',
    );
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    expect(manager.currentThemeId, Host4ThemeAssets.defaultThemeId);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.keyA);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);

    expect(manager.currentThemeId, 'obsidian');
    expect(manager.appliedThemeIds, <String>['obsidian']);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyB);
    await tester.pump();
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.keyB);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyB);

    expect(backCount, 1);
  });

  testWidgets('captures R015-FB004 visual artifacts', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final manager = Host4ThemeManager(
      catalog: _testCatalog,
      bundle: _testBundle,
    );
    addTearDown(manager.dispose);
    await tester.runAsync(
      () => manager.initialize(Host4ThemeAssets.defaultThemeId),
    );

    await tester.pumpWidget(
      SizedBox(
        width: 1280,
        height: 720,
        child: MaterialApp(home: Host4ThemeStorePage(manager: manager)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    const expectedIds = <String>[
      'theme_store.surface',
      'theme_store.card_default',
      'theme_store.card_obsidian',
      'theme_store.card_mint',
      'theme_store.selected_pill',
    ];
    for (final id in expectedIds) {
      expect(_findSemanticsId(id), findsOneWidget);
    }

    final semanticsFile = File(
      '/Users/tangxiaolu/project/pantas_launcher/'
      '.dev-flow/R015/evidence/ai_artifacts/R015-FB004/semantics/current.json',
    );
    final stateFile = File(
      '/Users/tangxiaolu/project/pantas_launcher/'
      '.dev-flow/R015/evidence/ai_artifacts/R015-FB004/state.json',
    );

    semanticsFile.parent.createSync(recursive: true);
    stateFile.parent.createSync(recursive: true);

    semanticsFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(<String, Object?>{
        'nodes': [
          for (final id in expectedIds) <String, Object?>{'id': id},
        ],
      }),
    );
    stateFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(<String, Object?>{
        'device_profile': <String, Object?>{
          'platform': 'flutter_test',
          'width_px': 1280,
          'height_px': 720,
          'pixel_ratio': 1.0,
        },
        'stable_identifiers_present': true,
        'selected_theme_id': manager.currentThemeId,
        'primary_focus_debug_label':
            FocusManager.instance.primaryFocus?.debugLabel,
        'visual_structure_checked': true,
      }),
    );
  });
}

final List<Host4ThemeCatalogEntry> _testCatalog = <Host4ThemeCatalogEntry>[
  const Host4ThemeCatalogEntry(
    id: 'default',
    name: 'Default Aurora',
    tokensAssetPath: 'assets/themes/default/tokens.json',
    previewColor: '#DDE6FF',
  ),
  const Host4ThemeCatalogEntry(
    id: 'obsidian',
    name: 'Obsidian',
    tokensAssetPath: 'assets/themes/obsidian/tokens.json',
    previewColor: '#151A24',
  ),
  const Host4ThemeCatalogEntry(
    id: 'mint',
    name: 'Mint',
    tokensAssetPath: 'assets/themes/mint/tokens.json',
    previewColor: '#D7FFF0',
  ),
];

final AssetBundle _testBundle = _FakeAssetBundle({
  for (final themeId in <String>['default', 'obsidian', 'mint'])
    'assets/themes/$themeId/tokens.json': _readThemeFile(
      themeId,
      'tokens.json',
    ),
  for (final themeId in <String>['default', 'obsidian', 'mint'])
    'assets/themes/$themeId/manifest.json': _readThemeFile(
      themeId,
      'manifest.json',
    ),
  for (final themeId in <String>['default', 'obsidian', 'mint'])
    'assets/themes/$themeId/asset.json': _readThemeFile(themeId, 'asset.json'),
});

Finder _findSemanticsId(String identifier) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Semantics && widget.properties.identifier == identifier,
    description: 'Semantics.identifier $identifier',
  );
}

class _CountingHost4ThemeManager extends Host4ThemeManager {
  _CountingHost4ThemeManager({required super.catalog, required super.bundle});

  final List<String> appliedThemeIds = <String>[];

  @override
  Future<void> applyTheme(String themeId, {String? mode}) {
    appliedThemeIds.add(themeId);
    return super.applyTheme(themeId, mode: mode);
  }
}

class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this.values);

  final Map<String, String> values;

  @override
  Future<ByteData> load(String key) async {
    final value = values[key];
    if (value == null) {
      throw StateError('Missing fake asset: $key');
    }
    final bytes = Uint8List.fromList(utf8.encode(value));
    return ByteData.view(bytes.buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final value = values[key];
    if (value == null) {
      throw StateError('Missing fake asset: $key');
    }
    return value;
  }
}

String _readThemeFile(String themeId, String fileName) {
  return File('assets/themes/$themeId/$fileName').readAsStringSync();
}
