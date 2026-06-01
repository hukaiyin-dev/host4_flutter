import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:host4_flutter_log/host4_flutter_log.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics/app_analytics.dart';

// ── Supported locales ─────────────────────────────────────────────────────────

const supportedLanguageCodes = ['en', 'zh'];

const _prefKeyLocale = 'locale';

/// Returns the first system locale that the app supports, falling back to 'en'.
Locale resolveSystemLocale() {
  final systemLocales = WidgetsBinding.instance.platformDispatcher.locales;
  for (final locale in systemLocales) {
    if (supportedLanguageCodes.contains(locale.languageCode)) {
      return Locale(locale.languageCode);
    }
  }
  return const Locale('en');
}

// ── Locale persistence ────────────────────────────────────────────────────────

Future<Locale?> loadSavedLocale() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(_prefKeyLocale);
  if (saved != null && supportedLanguageCodes.contains(saved)) {
    return Locale(saved);
  }
  return null;
}

Future<void> saveLocalePreference(Locale? locale) async {
  final prefs = await SharedPreferences.getInstance();
  if (locale == null) {
    await prefs.remove(_prefKeyLocale);
  } else {
    await prefs.setString(_prefKeyLocale, locale.languageCode);
  }
}

// ── Logger setup ──────────────────────────────────────────────────────────────

Future<void> configureLogger() async {
  await Host4Logger.configure(
    Host4LoggerConfig(
      minimumLevel: Host4LogLevel.debug,
      consoleEnabled: true,
      fileEnabled: true,
    ),
  );
}

Future<void> configureAppAnalytics() async {
  final bootstrapLog = Host4Logger('AnalyticsBootstrap');
  FirebaseAnalytics? firebaseAnalytics;

  if (!kIsWeb && _supportsNativeFirebase(defaultTargetPlatform)) {
    bootstrapLog.info(
      'Initializing Firebase Analytics for ${defaultTargetPlatform.name}.',
    );
    try {
      await Firebase.initializeApp();
      firebaseAnalytics = FirebaseAnalytics.instance;
      bootstrapLog.info('Firebase Analytics initialized successfully.');
    } catch (error, stackTrace) {
      bootstrapLog.warn(
        'Firebase initializeApp failed, fallback to logger sink only.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  } else {
    bootstrapLog.info(
      'Firebase Analytics skipped on unsupported platform.',
    );
  }

  configureAnalytics(firebaseAnalytics: firebaseAnalytics);
  bootstrapLog.info(
    firebaseAnalytics == null
        ? 'Analytics configured with logger sink only.'
        : 'Analytics configured with logger and Firebase sinks.',
  );
}

bool _supportsNativeFirebase(TargetPlatform platform) {
  return platform == TargetPlatform.android || platform == TargetPlatform.iOS;
}

// ── Theme catalog ─────────────────────────────────────────────────────────────

const defaultThemeCatalog = [
  Host4ThemeCatalogEntry(
    id: Host4ThemeAssets.defaultThemeId,
    name: Host4ThemeAssets.defaultThemeName,
    tokensAssetPath: Host4ThemeAssets.defaultTokensAssetPath,
  ),
  Host4ThemeCatalogEntry(
    id: 'grassland',
    name: 'Grassland',
    tokensAssetPath: 'assets/themes/grassland/tokens.json',
  ),
];
