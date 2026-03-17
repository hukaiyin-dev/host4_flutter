import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'host4_runtime_theme.dart';

class Host4ThemeLoader {
  const Host4ThemeLoader._();

  static Future<Host4RuntimeTheme> loadFromAsset(
    AssetBundle bundle,
    String assetPath, {
    String? mode,
  }) async {
    final jsonString = await bundle.loadString(assetPath);
    final decoded = json.decode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Theme tokens root must be a JSON object.');
    }

    final manifest = await _loadManifest(bundle, assetPath);
    if (manifest is! Map<String, dynamic>) {
      throw const FormatException('Theme manifest root must be a JSON object.');
    }

    final selectedMode = _resolveSelectedMode(manifest, mode);
    final normalized = _normalizeTheme(decoded, manifest, selectedMode);
    final resolved = _TokenResolver(normalized).resolveMap(normalized);
    final assetDirectory = assetPath.substring(
      0,
      assetPath.lastIndexOf('/') + 1,
    );

    return Host4RuntimeTheme(
      meta: Host4ThemeMeta(
        id: _readString(resolved, 'meta.id'),
        name: _readString(resolved, 'meta.name'),
        schema: _readString(resolved, 'schema'),
        mode: _readString(resolved, 'meta.mode'),
        defaultMode: _readString(resolved, 'meta.defaultMode'),
        supportedModes: _readStringList(resolved, 'meta.modes'),
        brightness: _parseBrightness(_readString(resolved, 'meta.mode')),
      ),
      colors: Host4ThemeColors(
        brandPrimary: _readColor(resolved, 'alias.shared.color.brand.primary'),
        brandSecondary: _readColor(
          resolved,
          'alias.shared.color.brand.secondary',
        ),
        brandAccent: _readColor(resolved, 'alias.shared.color.brand.accent'),
        pageBackground: _readColor(
          resolved,
          'alias.modes.$selectedMode.color.bg.page',
        ),
        surface: _readColor(
          resolved,
          'alias.modes.$selectedMode.color.bg.surface',
        ),
        surfaceMuted: _readColor(
          resolved,
          'alias.modes.$selectedMode.color.bg.muted',
        ),
        surfaceElevated: _readColor(
          resolved,
          'alias.modes.$selectedMode.color.bg.elevated',
        ),
        textPrimary: _readColor(
          resolved,
          'alias.modes.$selectedMode.color.text.primary',
        ),
        textSecondary: _readColor(
          resolved,
          'alias.modes.$selectedMode.color.text.secondary',
        ),
        textInverse: _readColor(
          resolved,
          'alias.modes.$selectedMode.color.text.inverse',
        ),
        borderDefault: _readColor(
          resolved,
          'alias.modes.$selectedMode.color.border.default',
        ),
        borderStrong: _readColor(
          resolved,
          'alias.modes.$selectedMode.color.border.strong',
        ),
        focus: _readColor(
          resolved,
          'alias.modes.$selectedMode.color.interactive.focus',
        ),
        success: _readColor(resolved, 'alias.shared.color.status.success'),
        warning: _readColor(resolved, 'alias.shared.color.status.warning'),
      ),
      typography: Host4ThemeTypography(
        display: _readTextToken(resolved, 'primitive.typography.display'),
        title: _readTextToken(resolved, 'primitive.typography.title'),
        heading: _readTextToken(resolved, 'primitive.typography.heading'),
        body: _readTextToken(resolved, 'primitive.typography.body'),
        label: _readTextToken(resolved, 'primitive.typography.label'),
        caption: _readTextToken(resolved, 'primitive.typography.caption'),
      ),
      spacing: Host4ThemeSpacing(
        xs: _readDouble(resolved, 'primitive.spacing.xs'),
        sm: _readDouble(resolved, 'primitive.spacing.sm'),
        md: _readDouble(resolved, 'primitive.spacing.md'),
        lg: _readDouble(resolved, 'primitive.spacing.lg'),
        xl: _readDouble(resolved, 'primitive.spacing.xl'),
        xxl: _readDouble(resolved, 'primitive.spacing.xxl'),
        page: _readDouble(resolved, 'alias.shared.spacing.page'),
        section: _readDouble(resolved, 'alias.shared.spacing.section'),
        card: _readDouble(resolved, 'alias.shared.spacing.card'),
        buttonHorizontal: _readDouble(
          resolved,
          'alias.shared.spacing.button.horizontal',
        ),
        buttonVertical: _readDouble(
          resolved,
          'alias.shared.spacing.button.vertical',
        ),
        inputHorizontal: _readDouble(
          resolved,
          'alias.shared.spacing.input.horizontal',
        ),
        inputVertical: _readDouble(
          resolved,
          'alias.shared.spacing.input.vertical',
        ),
        listGap: _readDouble(resolved, 'alias.shared.spacing.list.gap'),
      ),
      radius: Host4ThemeRadius(
        sm: _readDouble(resolved, 'primitive.radius.sm'),
        md: _readDouble(resolved, 'primitive.radius.md'),
        lg: _readDouble(resolved, 'primitive.radius.lg'),
        pill: _readDouble(resolved, 'primitive.radius.pill'),
        button: _readDouble(resolved, 'alias.shared.radius.button'),
        card: _readDouble(resolved, 'alias.shared.radius.card'),
        input: _readDouble(resolved, 'alias.shared.radius.input'),
        banner: _readDouble(resolved, 'alias.shared.radius.banner'),
      ),
      blur: Host4ThemeBlur(
        card: _readDouble(resolved, 'primitive.blur.card'),
        banner: _readDouble(resolved, 'primitive.blur.banner'),
        chrome: _readDouble(resolved, 'primitive.blur.chrome'),
      ),
      images: Host4ThemeImages(
        pageBackground: _resolveAssetPath(
          assetDirectory,
          _readString(
            resolved,
            'alias.modes.$selectedMode.image.pageBackground',
          ),
        ),
        pageOverlay: _resolveAssetPath(
          assetDirectory,
          _readString(resolved, 'alias.shared.image.pageOverlay'),
        ),
        heroBanner: _resolveAssetPath(
          assetDirectory,
          _readString(resolved, 'alias.modes.$selectedMode.image.heroBanner'),
        ),
        promoBanner: _resolveAssetPath(
          assetDirectory,
          _readString(resolved, 'alias.modes.$selectedMode.image.promoBanner'),
        ),
        spotIllustration: _resolveAssetPath(
          assetDirectory,
          _readString(resolved, 'alias.shared.image.spotIllustration'),
        ),
      ),
      components: Host4ThemeComponents(
        button: Host4ButtonComponentTokens(
          primary: _readButtonVariant(resolved, 'component.button.primary'),
          secondary: _readButtonVariant(resolved, 'component.button.secondary'),
          ghost: _readButtonVariant(resolved, 'component.button.ghost'),
        ),
        card: Host4CardComponentTokens(
          background: _readColor(resolved, 'component.card.background'),
          border: _readColor(resolved, 'component.card.border'),
          title: _readColor(resolved, 'component.card.title'),
          subtitle: _readColor(resolved, 'component.card.subtitle'),
        ),
        navigationBar: Host4NavigationBarComponentTokens(
          background: _readColor(
            resolved,
            'component.navigationBar.background',
          ),
          title: _readColor(resolved, 'component.navigationBar.title'),
          subtitle: _readColor(resolved, 'component.navigationBar.subtitle'),
          icon: _readColor(resolved, 'component.navigationBar.icon'),
        ),
        textField: Host4TextFieldComponentTokens(
          background: _readColor(resolved, 'component.textField.background'),
          border: _readColor(resolved, 'component.textField.border'),
          focusBorder: _readColor(resolved, 'component.textField.focusBorder'),
          text: _readColor(resolved, 'component.textField.text'),
          placeholder: _readColor(resolved, 'component.textField.placeholder'),
          icon: _readColor(resolved, 'component.textField.icon'),
        ),
        banner: Host4BannerComponentTokens(
          background: _readColor(resolved, 'component.banner.background'),
          overlay: _readColor(resolved, 'component.banner.overlay'),
          title: _readColor(resolved, 'component.banner.title'),
          subtitle: _readColor(resolved, 'component.banner.subtitle'),
          badgeBackground: _readColor(
            resolved,
            'component.banner.badgeBackground',
          ),
          badgeForeground: _readColor(
            resolved,
            'component.banner.badgeForeground',
          ),
        ),
        listCell: Host4ListCellComponentTokens(
          background: _readColor(resolved, 'component.listCell.background'),
          title: _readColor(resolved, 'component.listCell.title'),
          subtitle: _readColor(resolved, 'component.listCell.subtitle'),
          trailing: _readColor(resolved, 'component.listCell.trailing'),
          divider: _readColor(resolved, 'component.listCell.divider'),
        ),
      ),
    );
  }

  static Host4ButtonVariantTokens _readButtonVariant(
    Map<String, dynamic> json,
    String path,
  ) {
    return Host4ButtonVariantTokens(
      background: _readColor(json, '$path.background'),
      foreground: _readColor(json, '$path.foreground'),
      border: _readColor(json, '$path.border'),
    );
  }

  static Host4TextToken _readTextToken(Map<String, dynamic> json, String path) {
    return Host4TextToken(
      fontSize: _readDouble(json, '$path.fontSize'),
      lineHeight: _readDouble(json, '$path.lineHeight'),
      fontWeight: _readFontWeight(json, '$path.fontWeight'),
      letterSpacing: _readDouble(json, '$path.letterSpacing', fallback: 0),
    );
  }

  static String _resolveAssetPath(String directory, String assetPath) {
    if (assetPath.startsWith('packages/') || assetPath.startsWith('assets/')) {
      return assetPath;
    }

    return '$directory$assetPath';
  }

  static Future<dynamic> _loadManifest(
    AssetBundle bundle,
    String assetPath,
  ) async {
    final manifestPath = assetPath.replaceFirst(
      RegExp(r'tokens\.json$'),
      'manifest.json',
    );
    final manifestString = await bundle.loadString(manifestPath);
    return json.decode(manifestString);
  }
}

Map<String, dynamic> _normalizeTheme(
  Map<String, dynamic> tokens,
  Map<String, dynamic> manifest,
  String selectedMode,
) {
  final supportedModes = (manifest['modes'] as List<dynamic>? ?? const [])
      .map((item) => item.toString())
      .toList(growable: false);
  if (!supportedModes.contains(selectedMode)) {
    throw FormatException('Unsupported theme mode: $selectedMode');
  }

  return <String, dynamic>{
    'schema': tokens['schema'],
    'meta': <String, dynamic>{
      'id': manifest['id'],
      'name': manifest['name'],
      'defaultMode': manifest['defaultMode'],
      'mode': selectedMode,
      'modes': supportedModes,
    },
    'primitive': tokens['primitive'],
    'alias': tokens['alias'],
    'component': _readMap(_readMap(tokens, 'component.modes'), selectedMode),
  };
}

String _resolveSelectedMode(
  Map<String, dynamic> manifest,
  String? requestedMode,
) {
  if (requestedMode != null) {
    return requestedMode;
  }
  final defaultMode = manifest['defaultMode'];
  if (defaultMode is String && defaultMode.isNotEmpty) {
    return defaultMode;
  }
  throw const FormatException('manifest.defaultMode is required.');
}

class _TokenResolver {
  const _TokenResolver(this.root);

  final Map<String, dynamic> root;

  Map<String, dynamic> resolveMap(Map<String, dynamic> input) {
    return input.map<String, dynamic>(
      (key, value) => MapEntry(key, _resolve(value)),
    );
  }

  dynamic _resolve(dynamic value) {
    if (value is Map<String, dynamic>) {
      return resolveMap(value);
    }
    if (value is List<dynamic>) {
      return value.map(_resolve).toList(growable: false);
    }
    if (value is String) {
      final match = RegExp(r'^\{(.+)\}$').firstMatch(value);
      if (match == null) {
        return value;
      }

      final reference = match.group(1)!;
      final target = _lookup(reference);
      return _resolve(target);
    }

    return value;
  }

  dynamic _lookup(String path) {
    dynamic current = root;
    for (final segment in path.split('.')) {
      if (current is Map<String, dynamic> && current.containsKey(segment)) {
        current = current[segment];
        continue;
      }
      throw FormatException('Unknown token reference: $path');
    }
    return current;
  }
}

Brightness _parseBrightness(String value) {
  return switch (value) {
    'dark' => Brightness.dark,
    _ => Brightness.light,
  };
}

dynamic _readPath(Map<String, dynamic> json, String path) {
  dynamic current = json;
  for (final segment in path.split('.')) {
    if (current is Map<String, dynamic> && current.containsKey(segment)) {
      current = current[segment];
      continue;
    }
    throw FormatException('Missing token path: $path');
  }
  return current;
}

Map<String, dynamic> _readMap(Map<String, dynamic> json, String path) {
  final value = _readPath(json, path);
  if (value is! Map) {
    throw FormatException('Expected object at $path.');
  }
  return value.cast<String, dynamic>();
}

String _readString(Map<String, dynamic> json, String path) {
  final value = _readPath(json, path);
  if (value is! String) {
    throw FormatException('Expected string at $path.');
  }
  return value;
}

List<String> _readStringList(Map<String, dynamic> json, String path) {
  final value = _readPath(json, path);
  if (value is! List) {
    throw FormatException('Expected string list at $path.');
  }
  return value.map((item) => item.toString()).toList(growable: false);
}

double _readDouble(Map<String, dynamic> json, String path, {double? fallback}) {
  final dynamic value;
  try {
    value = _readPath(json, path);
  } on FormatException {
    if (fallback != null) {
      return fallback;
    }
    rethrow;
  }

  if (value is num) {
    return value.toDouble();
  }
  throw FormatException('Expected number at $path.');
}

Color _readColor(Map<String, dynamic> json, String path) {
  final value = _readString(json, path);
  final normalized = value.replaceFirst('#', '');
  final hex = normalized.length == 6 ? 'FF$normalized' : normalized;
  if (hex.length != 8) {
    throw FormatException('Expected hex color at $path.');
  }
  return Color(int.parse(hex, radix: 16));
}

FontWeight _readFontWeight(Map<String, dynamic> json, String path) {
  final value = _readPath(json, path);
  if (value is! num) {
    throw FormatException('Expected numeric fontWeight at $path.');
  }

  return switch (value.toInt()) {
    100 => FontWeight.w100,
    200 => FontWeight.w200,
    300 => FontWeight.w300,
    400 => FontWeight.w400,
    500 => FontWeight.w500,
    600 => FontWeight.w600,
    700 => FontWeight.w700,
    800 => FontWeight.w800,
    900 => FontWeight.w900,
    _ => FontWeight.w400,
  };
}
