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
  });

  final String id;
  final String name;
  final String tokensAssetPath;
}

class Host4ThemeManager extends ChangeNotifier {
  Host4ThemeManager({
    required List<Host4ThemeCatalogEntry> catalog,
    required AssetBundle bundle,
  })  : _catalog = List.unmodifiable(catalog),
        _bundle = bundle;

  final List<Host4ThemeCatalogEntry> _catalog;
  final AssetBundle _bundle;

  Host4RuntimeTheme? _theme;
  String? _currentThemeId;
  String? _currentMode;
  Map<String, dynamic>? _generatedTokensMap;
  Host4ThemeImages? _generatedImages;
  bool _isLoading = false;

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

    _isLoading = true;
    notifyListeners();

    try {
      _theme = await Host4ThemeLoader.loadFromAsset(
        _bundle,
        entry.tokensAssetPath,
        mode: mode,
      );
      _currentThemeId = themeId;
      _currentMode = _theme!.meta.mode;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> applyGeneratedTheme(
    Map<String, dynamic> tokensMap, {
    String? mode,
    Host4ThemeImages? images,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final targetMode = mode ?? _currentMode ?? 'light';
      _theme = await Host4ThemeLoader.loadFromMap(
        tokensMap,
        mode: targetMode,
        fallbackImages: images ?? _generatedImages ?? _theme?.images,
      );
      _generatedTokensMap = tokensMap;
      _generatedImages = images;
      _currentThemeId = null;
      _currentMode = targetMode;
    } finally {
      _isLoading = false;
      notifyListeners();
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
