import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';

void main() {
  test(
    'loads runtime theme from manifest plus multi-mode tokens json',
    () async {
      final bundle = _FakeAssetBundle({
        'assets/themes/default/manifest.json': _readThemeFile('manifest.json'),
        'assets/themes/default/tokens.json': _readThemeFile('tokens.json'),
        'assets/themes/default/asset.json': _readThemeFile('asset.json'),
      });

      final theme = await Host4ThemeLoader.loadFromAsset(
        bundle,
        'assets/themes/default/tokens.json',
      );

      expect(theme.meta.id, 'default');
      expect(theme.meta.name, 'Default Aurora');
      expect(theme.meta.mode, 'light');
      expect(theme.meta.supportedModes, ['light', 'dark']);
      expect(theme.colors.brandPrimary, const Color(0xFF2F5BFF));
      expect(theme.spacing.page, 24.0);
      expect(theme.spacing.inputVertical, 12);
      expect(
        theme.images.heroBanner,
        'assets/themes/default/images/hero_banner_light.png',
      );
      expect(
        theme.components.button.labelStyle.fontSize,
        theme.typography.label.fontSize,
      );
      expect(theme.components.card.padding, theme.spacing.card);
      expect(theme.components.pageShell.image, theme.images.pageBackground);
    },
  );

  test(
    'loads dark mode and keeps component tokens aligned with semantic resolution',
    () async {
      final bundle = _FakeAssetBundle({
        'assets/themes/default/manifest.json': _readThemeFile('manifest.json'),
        'assets/themes/default/tokens.json': _readThemeFile('tokens.json'),
        'assets/themes/default/asset.json': _readThemeFile('asset.json'),
      });

      final theme = await Host4ThemeLoader.loadFromAsset(
        bundle,
        'assets/themes/default/tokens.json',
        mode: 'dark',
      );

      expect(theme.meta.mode, 'dark');
      expect(theme.colors.pageBackground, const Color(0xFF121A29));
      expect(theme.colors.textPrimary, const Color(0xFFFFFFFF));
      expect(theme.colors.brandPrimary, const Color(0xFF5C7CFA));
      expect(theme.components.card.background, const Color(0xFF1A2436));
      expect(
        theme.components.button.primary.defaultState.background,
        const Color(0xFF5C7CFA),
      );
      expect(
        theme.components.button.primary.defaultState.foreground,
        const Color(0xFFFFFFFF),
      );
      expect(theme.components.tabBar.items.length, 3);
      expect(
        theme.components.pageShell.image,
        'assets/themes/default/images/page_background_dark.png',
      );
    },
  );

  test('throws a clear error for circular token references', () async {
    final cyclicTheme =
        jsonDecode(_readThemeFile('tokens.json')) as Map<String, dynamic>;
    final brand =
        ((cyclicTheme['semantic'] as Map<String, dynamic>)['color']
                as Map<String, dynamic>)['brand']
            as Map<String, dynamic>;
    brand['primary'] = {
      'light': '{semantic.color.brand.secondary}',
      'dark': '{semantic.color.brand.secondary}',
    };
    brand['secondary'] = {
      'light': '{semantic.color.brand.primary}',
      'dark': '{semantic.color.brand.primary}',
    };

    await expectLater(
      Host4ThemeLoader.loadFromMap(cyclicTheme),
      throwsA(
        isA<FormatException>()
            .having(
              (error) => error.message,
              'message',
              contains('Circular token reference detected:'),
            )
            .having(
              (error) => error.message,
              'message',
              contains('semantic.color.brand.primary'),
            )
            .having(
              (error) => error.message,
              'message',
              contains('semantic.color.brand.secondary'),
            ),
      ),
    );
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

String _readThemeFile(String fileName) {
  final file = File(
    '../../examples/host4_flutter_demo/assets/themes/default/$fileName',
  );
  return file.readAsStringSync();
}
