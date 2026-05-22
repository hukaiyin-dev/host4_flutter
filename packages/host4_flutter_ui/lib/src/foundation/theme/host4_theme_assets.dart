import 'package:flutter/services.dart';

import 'host4_theme_manager.dart';

class Host4ThemeAssets {
  const Host4ThemeAssets._();

  static const defaultThemeId = 'default';
  static const defaultThemeName = 'Default Aurora';
  static const catalogAssetPath =
      'packages/host4_flutter_ui/assets/themes/catalog.json';
  static const defaultTokensAssetPath =
      'packages/host4_flutter_ui/assets/themes/default/tokens.json';

  static const defaultCatalog = <Host4ThemeCatalogEntry>[
    Host4ThemeCatalogEntry(
      id: defaultThemeId,
      name: defaultThemeName,
      tokensAssetPath: defaultTokensAssetPath,
      previewAssetPath:
          'packages/host4_flutter_ui/assets/themes/default/images/hero_banner_light.png',
      previewColor: '#EEF3FF',
    ),
    Host4ThemeCatalogEntry(
      id: 'obsidian',
      name: 'Obsidian Pulse',
      tokensAssetPath:
          'packages/host4_flutter_ui/assets/themes/obsidian/tokens.json',
      previewAssetPath:
          'packages/host4_flutter_ui/assets/themes/default/images/hero_banner_dark.png',
      previewColor: '#0A1020',
    ),
    Host4ThemeCatalogEntry(
      id: 'mint',
      name: 'Mint Circuit',
      tokensAssetPath:
          'packages/host4_flutter_ui/assets/themes/mint/tokens.json',
      previewAssetPath:
          'packages/host4_flutter_ui/assets/themes/default/images/spot_illustration_light.png',
      previewColor: '#E9FBF6',
    ),
  ];

  static Future<List<Host4ThemeCatalogEntry>> loadCatalog(
    AssetBundle bundle, {
    String catalogAssetPath = Host4ThemeAssets.catalogAssetPath,
  }) {
    return Host4ThemeCatalog.loadFromAsset(bundle, catalogAssetPath);
  }
}
