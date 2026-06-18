import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'host4_runtime_theme.dart';
import 'host4_theme_loader.dart';

@immutable
class Host4ThemeCatalogEntry {
  const Host4ThemeCatalogEntry({
    required this.id,
    required this.name,
    required this.tokensAssetPath,
    this.previewAssetPath,
    this.previewColor,
  });

  final String id;
  final String name;
  final String tokensAssetPath;
  final String? previewAssetPath;
  final String? previewColor;

  factory Host4ThemeCatalogEntry.fromJson(
    Map<String, dynamic> json, {
    required String catalogAssetPath,
  }) {
    final id = _readCatalogString(json, 'id');
    final name = _readCatalogString(json, 'name');
    final tokens = _readCatalogString(json, 'tokens');
    final preview = _readOptionalCatalogString(json, 'preview');

    return Host4ThemeCatalogEntry(
      id: id,
      name: name,
      tokensAssetPath: _resolveCatalogAssetPath(catalogAssetPath, tokens),
      previewAssetPath: preview == null
          ? null
          : _resolveCatalogAssetPath(catalogAssetPath, preview),
      previewColor: _readOptionalCatalogString(json, 'previewColor'),
    );
  }
}

class Host4ThemeCatalog {
  const Host4ThemeCatalog._();

  static Future<List<Host4ThemeCatalogEntry>> loadFromAsset(
    AssetBundle bundle,
    String catalogAssetPath,
  ) async {
    final jsonString = await bundle.loadString(catalogAssetPath);
    final decoded = json.decode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Theme catalog root must be a JSON object.');
    }

    final themes = decoded['themes'];
    if (themes is! List) {
      throw const FormatException('Theme catalog must contain a themes list.');
    }

    return themes
        .map((item) {
          if (item is! Map) {
            throw const FormatException(
              'Theme catalog entries must be objects.',
            );
          }
          return Host4ThemeCatalogEntry.fromJson(
            Map<String, dynamic>.from(item),
            catalogAssetPath: catalogAssetPath,
          );
        })
        .toList(growable: false);
  }
}

class Host4ThemeManager extends ChangeNotifier {
  Host4ThemeManager({
    required List<Host4ThemeCatalogEntry> catalog,
    required AssetBundle bundle,
  }) : _catalog = List.unmodifiable(catalog),
       _bundle = bundle;

  final List<Host4ThemeCatalogEntry> _catalog;
  final AssetBundle _bundle;

  Host4RuntimeTheme? _theme;
  String? _currentThemeId;
  String? _currentMode;
  Map<String, dynamic>? _generatedTokensMap;
  Host4ThemeImages? _generatedImages;
  bool _isLoading = false;
  int _loadGeneration = 0;

  List<Host4ThemeCatalogEntry> get catalog => _catalog;
  Host4RuntimeTheme get theme {
    final value = _theme;
    if (value == null) {
      throw StateError('Theme has not been initialized yet.');
    }
    return value;
  }

  String? get currentThemeId => _currentThemeId;
  String? get currentMode => _currentMode;
  bool get isLoading => _isLoading;
  bool get isReady => _theme != null;

  Future<void> initialize(String themeId, {String? mode}) async {
    if (_theme != null &&
        _currentThemeId == themeId &&
        (mode == null || _currentMode == mode)) {
      return;
    }
    await applyTheme(themeId, mode: mode);
  }

  Future<void> applyTheme(String themeId, {String? mode}) async {
    Host4ThemeCatalogEntry? entry;
    for (final item in _catalog) {
      if (item.id == themeId) {
        entry = item;
        break;
      }
    }
    if (entry == null) {
      throw ArgumentError.value(themeId, 'themeId', 'Unknown theme id.');
    }

    final generation = ++_loadGeneration;
    _isLoading = true;
    notifyListeners();

    try {
      final theme = await Host4ThemeLoader.loadFromAsset(
        _bundle,
        entry.tokensAssetPath,
        mode: mode,
      );
      if (generation != _loadGeneration) {
        return;
      }
      _theme = theme;
      _currentThemeId = themeId;
      _currentMode = _theme!.meta.mode;
    } finally {
      if (generation == _loadGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> applyGeneratedTheme(
    Map<String, dynamic> tokensMap, {
    String? mode,
    Host4ThemeImages? images,
  }) async {
    final generation = ++_loadGeneration;
    _isLoading = true;
    notifyListeners();

    try {
      final targetMode = mode ?? _currentMode ?? 'light';
      final theme = await Host4ThemeLoader.loadFromMap(
        tokensMap,
        mode: targetMode,
        fallbackImages: images ?? _generatedImages ?? _theme?.images,
      );
      if (generation != _loadGeneration) {
        return;
      }
      _theme = theme;
      _generatedTokensMap = tokensMap;
      _generatedImages = images;
      _currentThemeId = null;
      _currentMode = targetMode;
    } finally {
      if (generation == _loadGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> applyMode(String mode) async {
    if (_currentThemeId != null) {
      await applyTheme(_currentThemeId!, mode: mode);
    } else if (_generatedTokensMap != null) {
      await applyGeneratedTheme(
        _generatedTokensMap!,
        mode: mode,
        images: _generatedImages,
      );
    } else {
      throw StateError('Theme has not been initialized yet.');
    }
  }
}

String _readCatalogString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('Theme catalog entry missing "$key".');
}

String? _readOptionalCatalogString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('Theme catalog entry "$key" must be a string.');
}

String _resolveCatalogAssetPath(String catalogAssetPath, String value) {
  if (value.startsWith('packages/') || value.startsWith('assets/')) {
    return value;
  }
  final slashIndex = catalogAssetPath.lastIndexOf('/');
  if (slashIndex == -1) return value;
  return '${catalogAssetPath.substring(0, slashIndex + 1)}$value';
}
