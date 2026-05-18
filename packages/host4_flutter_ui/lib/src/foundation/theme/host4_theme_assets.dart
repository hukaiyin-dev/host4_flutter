import 'host4_theme_manager.dart';

class Host4ThemeAssets {
  const Host4ThemeAssets._();

  static const defaultThemeId = 'default';
  static const defaultThemeName = 'Default Aurora';
  static const defaultTokensAssetPath =
      'packages/host4_flutter_ui/assets/themes/default/tokens.json';

  static const defaultCatalog = <Host4ThemeCatalogEntry>[
    Host4ThemeCatalogEntry(
      id: defaultThemeId,
      name: defaultThemeName,
      tokensAssetPath: defaultTokensAssetPath,
    ),
  ];
}
