# host4_flutter_ui

Shared UI foundation for Host4 Flutter apps.

This package owns the reusable component set and the JSON-driven theme runtime.
Business apps should keep feature pages and product data in their own
repositories, then consume this package for common UI primitives and theme
loading.

## Responsibilities

- JSON theme loading and mode switching.
- Runtime theme scope and theme manager.
- Base components such as buttons, cards, page scaffold, search field, list
  cell, navigation bar, section header, and tab bar.
- Packaged default theme assets that can be used as a template or fallback.

## Theme Files

The default theme is included under:

```text
assets/themes/default/
  manifest.json
  tokens.json
  asset.json
  images/
```

Apps can load the packaged default theme:

```dart
final manager = Host4ThemeManager(
  catalog: Host4ThemeAssets.defaultCatalog,
  bundle: rootBundle,
);

await manager.initialize(Host4ThemeAssets.defaultThemeId);
```

To customize a product theme, copy the same JSON structure into the app assets
and register a catalog entry pointing at that app-owned `tokens.json`.

## App Wiring

Wrap the app with `Host4ThemeScope` after the manager is initialized:

```dart
Host4ThemeScope(
  manager: manager,
  child: const MaterialApp(home: HomePage()),
);
```

Components read tokens from `context.host4Theme`, so colors, typography,
spacing, radius, images, and component states can be changed by editing JSON.

## Component Boundary

Put stable, reusable UI primitives in this package. Keep launcher-specific
screens, game data, API calls, and native feature flows in the business app.
