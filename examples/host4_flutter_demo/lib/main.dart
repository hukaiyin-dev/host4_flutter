import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:host4_flutter_log/host4_flutter_log.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'integration/app_bootstrap.dart';
import 'integration/analytics/app_analytics.dart';
import 'l10n/generated/app_localizations.dart';
import 'shell/demo_shell.dart';
import 'theme_job.dart';
import 'theme_job_poller.dart';

final _log = Host4Logger('App');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureLogger();
  await configureAppAnalytics();
  _log.info('App starting');
  unawaited(
    appAnalytics.track(
      'app_start',
      properties: {'source': 'main'},
    ),
  );
  runApp(const Host4DemoBootstrap());
}

class Host4DemoBootstrap extends StatefulWidget {
  const Host4DemoBootstrap({super.key, this.bundle});

  final AssetBundle? bundle;

  @override
  State<Host4DemoBootstrap> createState() => _Host4DemoBootstrapState();
}

class _Host4DemoBootstrapState extends State<Host4DemoBootstrap> {
  late final Host4ThemeManager _themeManager;
  late final Future<void> _bootstrapFuture;
  Locale? _localePreference;

  Locale get _effectiveLocale =>
      _localePreference ?? resolveSystemLocale();

  @override
  void initState() {
    super.initState();
    _themeManager = Host4ThemeManager(
      catalog: defaultThemeCatalog,
      bundle: widget.bundle ?? rootBundle,
    );
    _bootstrapFuture = Future.wait([
      _themeManager.initialize('default'),
      _loadLocalePref(),
    ]);
    unawaited(ThemeJobStore.instance.load());
    ThemeJobPoller.instance.start();
  }

  Future<void> _loadLocalePref() async {
    final locale = await loadSavedLocale();
    if (locale != null) _localePreference = locale;
  }

  Future<void> _resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _log.info('Reset to defaults');
    unawaited(
      appAnalytics.track(
        'reset_to_defaults',
        properties: {'source': 'bootstrap'},
      ),
    );
    if (mounted) setState(() => _localePreference = null);
  }

  @override
  void dispose() {
    ThemeJobPoller.instance.stop();
    _themeManager.dispose();
    super.dispose();
  }

  void _setLocalePreference(Locale? locale) {
    if (_localePreference == locale) return;
    _log.info('Locale preference: ${locale?.languageCode ?? 'system'}');
    unawaited(
      appAnalytics.track(
        'locale_preference_changed',
        properties: {'locale': locale?.languageCode ?? 'system'},
      ),
    );
    setState(() => _localePreference = locale);
    saveLocalePreference(locale);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildMaterialApp(
            home: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return Scaffold(
                  body: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.themeBootstrapFailed,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text('${snapshot.error}'),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return _buildMaterialApp(
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return Host4ThemeScope(
          manager: _themeManager,
          child: AnimatedBuilder(
            animation: _themeManager,
            builder: (context, _) {
              if (!_themeManager.isReady) {
                return _buildMaterialApp(
                  home: const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              final theme = _themeManager.theme;
              return _buildMaterialApp(
                brightness: theme.meta.brightness,
                home: Host4DemoShell(
                  localePreference: _localePreference,
                  onLocalePreferenceChanged: _setLocalePreference,
                  onResetToDefaults: _resetToDefaults,
                ),
              );
            },
          ),
        );
      },
    );
  }

  MaterialApp _buildMaterialApp({required Widget home, Brightness? brightness}) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: _effectiveLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: ThemeData(
        useMaterial3: true,
        brightness: brightness,
        scaffoldBackgroundColor: Colors.transparent,
        splashFactory: InkRipple.splashFactory,
      ),
      home: home,
    );
  }
}
