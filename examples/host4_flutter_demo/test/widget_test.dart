import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:host4_flutter_demo/main.dart';
import 'package:host4_flutter_demo/pages/components_page.dart';
import 'package:host4_flutter_demo/pages/home_page.dart';
import 'package:host4_flutter_demo/shell/demo_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(const {});
  });

  testWidgets('renders AI theme demo shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      Host4DemoBootstrap(
        bundle: _FakeAssetBundle({
          'assets/themes/default/manifest.json': _readThemeFile(
            'default',
            'manifest.json',
          ),
          'assets/themes/default/tokens.json': _readThemeFile(
            'default',
            'tokens.json',
          ),
          'assets/themes/grassland/manifest.json': _readThemeFile(
            'grassland',
            'manifest.json',
          ),
          'assets/themes/grassland/tokens.json': _readThemeFile(
            'grassland',
            'tokens.json',
          ),
        }),
      ),
    );
    for (var i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(Host4DemoShell).evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.byType(Host4DemoShell), findsOneWidget);
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.textContaining('Default Aurora'), findsOneWidget);

    await tester.tap(find.text('Components').first);
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(ComponentsPage), findsOneWidget);
  });
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
  final file = File('assets/themes/$themeId/$fileName');
  return file.readAsStringSync();
}
