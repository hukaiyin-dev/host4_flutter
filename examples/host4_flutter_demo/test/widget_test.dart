import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:host4_flutter_demo/main.dart';
import 'package:host4_flutter_demo/pages/components_page.dart';
import 'package:host4_flutter_demo/pages/home_page.dart';
import 'package:host4_flutter_demo/shell/demo_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(const {});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
          if (call.method == 'getApplicationDocumentsDirectory') {
            return Directory.systemTemp.path;
          }
          return null;
        });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
  });

  testWidgets('renders AI theme demo shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      Host4DemoBootstrap(
        bundle: _FakeAssetBundle({
          'packages/host4_flutter_ui/assets/themes/default/manifest.json':
              _readPackageThemeFile('manifest.json'),
          'packages/host4_flutter_ui/assets/themes/default/tokens.json':
              _readPackageThemeFile('tokens.json'),
          'packages/host4_flutter_ui/assets/themes/default/asset.json':
              _readPackageThemeFile('asset.json'),
          'assets/themes/grassland/manifest.json': _readExampleThemeFile(
            'grassland',
            'manifest.json',
          ),
          'assets/themes/grassland/tokens.json': _readExampleThemeFile(
            'grassland',
            'tokens.json',
          ),
          'assets/themes/grassland/asset.json': _readExampleThemeFile(
            'grassland',
            'asset.json',
          ),
        }),
      ),
    );
    for (var i = 0; i < 100; i++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      if (find.byType(Host4DemoShell).evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.byType(Host4DemoShell), findsOneWidget);
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.textContaining('Default Aurora'), findsOneWidget);
    expect(find.text('硅胶贴片'), findsOneWidget);

    await tester.tap(find.text('硅胶贴片'));
    await tester.pumpAndSettle();

    expect(find.text('编辑'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SingleChildScrollView &&
            widget.scrollDirection == Axis.horizontal,
      ),
      findsNothing,
    );
    expect(find.text('UP'), findsNothing);

    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();

    expect(find.text('整体'), findsOneWidget);
    expect(find.text('模块'), findsOneWidget);
    expect(find.text('按钮'), findsOneWidget);
    expect(find.text('保存'), findsOneWidget);
    expect(find.text('重置'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

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

String _readExampleThemeFile(String themeId, String fileName) {
  final file = File('assets/themes/$themeId/$fileName');
  return file.readAsStringSync();
}

String _readPackageThemeFile(String fileName) {
  final file = File(
    '../../packages/host4_flutter_ui/assets/themes/default/$fileName',
  );
  return file.readAsStringSync();
}
