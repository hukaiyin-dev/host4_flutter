import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:host4_flutter_log/host4_flutter_log.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/generated/app_localizations.dart';

const _supportedLanguageCodes = ['en', 'zh'];
const _prefKeyLocale = 'locale';

final _log = Host4Logger('App');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Host4Logger.configure(Host4LoggerConfig(
    minimumLevel: Host4LogLevel.debug,
    fileEnabled: true,
    consoleEnabled: kDebugMode,
  ));
  _log.info('App starting');
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
  // null = follow system; non-null = explicit user choice
  Locale? _localePreference;

  static Locale _resolveSystemLocale() {
    final systemLocales = PlatformDispatcher.instance.locales;
    for (final locale in systemLocales) {
      if (_supportedLanguageCodes.contains(locale.languageCode)) {
        return Locale(locale.languageCode);
      }
    }
    return const Locale('en');
  }

  Locale get _effectiveLocale => _localePreference ?? _resolveSystemLocale();

  @override
  void initState() {
    super.initState();
    _themeManager = Host4ThemeManager(
      catalog: const [
        Host4ThemeCatalogEntry(
          id: 'default',
          name: 'Default',
          tokensAssetPath: 'assets/themes/default/tokens.json',
        ),
        Host4ThemeCatalogEntry(
          id: 'grassland',
          name: 'Grassland',
          tokensAssetPath: 'assets/themes/grassland/tokens.json',
        ),
      ],
      bundle: widget.bundle ?? rootBundle,
    );
    _bootstrapFuture = Future.wait([
      _themeManager.initialize('default'),
      _loadLocalePref(),
    ]);
  }

  Future<void> _loadLocalePref() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKeyLocale);
    if (saved != null && _supportedLanguageCodes.contains(saved)) {
      // Set directly — no setState needed here because this future runs
      // concurrently with theme init inside _bootstrapFuture. The FutureBuilder
      // will rebuild with the correct value when both complete.
      _localePreference = Locale(saved);
    }
  }

  Future<void> _resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _log.info('Reset to defaults');
    if (mounted) setState(() => _localePreference = null);
  }

  @override
  void dispose() {
    _themeManager.dispose();
    super.dispose();
  }

  /// [locale] null means revert to follow-system.
  void _setLocalePreference(Locale? locale) {
    if (_localePreference == locale) return;
    _log.info('Locale preference: ${locale?.languageCode ?? 'system'}');
    setState(() => _localePreference = locale);
    SharedPreferences.getInstance().then((prefs) {
      if (locale == null) {
        prefs.remove(_prefKeyLocale);
      } else {
        prefs.setString(_prefKeyLocale, locale.languageCode);
      }
    });
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

  MaterialApp _buildMaterialApp({
    required Widget home,
    Brightness? brightness,
  }) {
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

class Host4DemoShell extends StatefulWidget {
  const Host4DemoShell({
    required this.localePreference,
    required this.onLocalePreferenceChanged,
    required this.onResetToDefaults,
    super.key,
  });

  final Locale? localePreference;
  final ValueChanged<Locale?> onLocalePreferenceChanged;
  final Future<void> Function() onResetToDefaults;

  @override
  State<Host4DemoShell> createState() => _Host4DemoShellState();
}

class _Host4DemoShellState extends State<Host4DemoShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.host4Theme;
    final manager = context.host4ThemeManager;
    final pages = <_ShellPage>[
      _ShellPage(
        title: l10n.homePageTitle,
        subtitle: l10n.homePageSubtitle,
        child: const HomePage(),
      ),
      _ShellPage(
        title: l10n.listPageTitle,
        subtitle: l10n.listPageSubtitle,
        child: const ComponentsPage(),
      ),
      _ShellPage(
        title: l10n.settingsPageTitle,
        subtitle: l10n.settingsPageSubtitle,
        child: SettingsPage(
          localePreference: widget.localePreference,
          onLocalePreferenceChanged: widget.onLocalePreferenceChanged,
          onResetToDefaults: widget.onResetToDefaults,
        ),
      ),
    ];
    final currentPage = pages[_currentIndex];

    return Stack(
      children: [
        Host4PageScaffold(
          bottomNavigationBar: Host4TabBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              _log.debug('Tab selected: $index');
              setState(() => _currentIndex = index);
            },
            items: [
              Host4TabItem(
                index: 0,
                label: l10n.tabHome,
                fallbackIcon: Icons.home_outlined,
                fallbackSelectedIcon: Icons.home_rounded,
              ),
              Host4TabItem(
                index: 1,
                label: l10n.tabList,
                fallbackIcon: Icons.widgets_outlined,
                fallbackSelectedIcon: Icons.widgets_rounded,
              ),
              Host4TabItem(
                index: 2,
                label: l10n.tabSettings,
                fallbackIcon: Icons.settings_outlined,
                fallbackSelectedIcon: Icons.settings_rounded,
              ),
            ],
          ),
          body: Column(
            children: [
              Host4NavigationBar(
                title: currentPage.title,
                subtitle: currentPage.subtitle,
                trailing: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: theme.spacing.sm,
                    vertical: theme.spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colors.surface.withValues(alpha: 0.84),
                    borderRadius: BorderRadius.circular(theme.radius.pill),
                    border: Border.all(color: theme.colors.borderDefault),
                  ),
                  child: Text(
                    '${theme.meta.name} · ${_localizedModeLabel(l10n, theme.meta.mode)}',
                    style: theme.typography.caption.toTextStyle(
                      theme.colors.textSecondary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: KeyedSubtree(
                    key: ValueKey(_currentIndex),
                    child: currentPage.child,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (manager.isLoading)
          ColoredBox(
            color: theme.colors.pageBackground.withValues(alpha: 0.45),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.host4Theme;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        theme.spacing.page,
        0,
        theme.spacing.page,
        theme.spacing.page,
      ),
      children: [
        Host4Banner(
          badge: l10n.bannerBadgeAiTheme,
          title: l10n.homeHeroTitle,
          subtitle: l10n.homeHeroSubtitle,
          trailing: _IllustrationBadge(
            imagePath: theme.images.spotIllustration,
          ),
        ),
        SizedBox(height: theme.spacing.section),
        Host4SectionHeader(
          title: l10n.featuredModulesTitle,
          subtitle: l10n.featuredModulesSubtitle,
          action: Host4Button(
            label: l10n.compareButton,
            variant: Host4ButtonVariant.secondary,
            onPressed: () {},
          ),
        ),
        SizedBox(height: theme.spacing.md),
        Row(
          children: [
            Expanded(
              child: _FeatureCard(
                title: l10n.featureThemeChainTitle,
                subtitle: l10n.featureThemeChainSubtitle,
                actionLabel: l10n.inspectButton,
              ),
            ),
            SizedBox(width: theme.spacing.md),
            Expanded(
              child: _FeatureCard(
                title: l10n.featureVisualDeltaTitle,
                subtitle: l10n.featureVisualDeltaSubtitle,
                actionLabel: l10n.switchButton,
              ),
            ),
          ],
        ),
        SizedBox(height: theme.spacing.section),
        Host4Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Host4Text(l10n.whyDemoMattersTitle, role: Host4TextRole.heading),
              SizedBox(height: theme.spacing.sm),
              Host4Text(
                l10n.whyDemoMattersBody,
                colorRole: Host4TextColorRole.secondary,
              ),
              SizedBox(height: theme.spacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Host4Button(
                      label: l10n.useCurrentThemeButton,
                      content: Host4ButtonContent.iconLeft,
                      icon: Icons.palette_outlined,
                      expanded: true,
                      onPressed: () {},
                    ),
                  ),
                  SizedBox(width: theme.spacing.md),
                  Expanded(
                    child: Host4Button(
                      label: l10n.previewRemoteFlowButton,
                      variant: Host4ButtonVariant.secondary,
                      content: Host4ButtonContent.iconLeft,
                      icon: Icons.cloud_download_outlined,
                      expanded: true,
                      onPressed: null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ComponentsPage extends StatelessWidget {
  const ComponentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.host4Theme;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        theme.spacing.page,
        0,
        theme.spacing.page,
        theme.spacing.page,
      ),
      children: [
        Host4ListCell(
          title: l10n.componentButtonsTitle,
          subtitle: l10n.componentButtonsSubtitle,
          leading: _ListIcon(
            icon: Icons.smart_button_outlined,
            color: theme.colors.brandPrimary,
          ),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => _ComponentDemoScaffold(
              title: l10n.componentButtonsTitle,
              subtitle: l10n.componentButtonsSubtitle,
              child: const ButtonsPage(),
            ),
          )),
        ),
      ],
    );
  }
}

class ButtonsPage extends StatelessWidget {
  const ButtonsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.host4Theme;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        theme.spacing.page,
        0,
        theme.spacing.page,
        theme.spacing.page,
      ),
      children: [
        // ── Variants ──────────────────────────────────────────
        Host4SectionHeader(
          title: l10n.sectionVariants,
          subtitle: 'primary · secondary · ghost',
        ),
        SizedBox(height: theme.spacing.md),
        Wrap(
          spacing: theme.spacing.sm,
          runSpacing: theme.spacing.sm,
          children: const [
            Host4Button(
              label: 'Primary',
              onPressed: _noOp,
            ),
            Host4Button(
              label: 'Secondary',
              variant: Host4ButtonVariant.secondary,
              onPressed: _noOp,
            ),
            Host4Button(
              label: 'Ghost',
              variant: Host4ButtonVariant.ghost,
              onPressed: _noOp,
            ),
          ],
        ),
        SizedBox(height: theme.spacing.section),

        // ── With icon ─────────────────────────────────────────
        Host4SectionHeader(
          title: l10n.sectionWithIcon,
          subtitle: 'icon + label',
        ),
        SizedBox(height: theme.spacing.md),
        Wrap(
          spacing: theme.spacing.sm,
          runSpacing: theme.spacing.sm,
          children: const [
            Host4Button(
              label: 'Primary',
              content: Host4ButtonContent.iconLeft,
              icon: Icons.palette_outlined,
              onPressed: _noOp,
            ),
            Host4Button(
              label: 'Secondary',
              variant: Host4ButtonVariant.secondary,
              content: Host4ButtonContent.iconLeft,
              icon: Icons.cloud_download_outlined,
              onPressed: _noOp,
            ),
            Host4Button(
              label: 'Ghost',
              variant: Host4ButtonVariant.ghost,
              content: Host4ButtonContent.iconLeft,
              icon: Icons.info_outline_rounded,
              onPressed: _noOp,
            ),
          ],
        ),
        SizedBox(height: theme.spacing.section),

        // ── Icon Top ──────────────────────────────────────────
        Host4SectionHeader(
          title: 'Icon Top',
          subtitle: 'icon above label',
        ),
        SizedBox(height: theme.spacing.md),
        Wrap(
          spacing: theme.spacing.sm,
          runSpacing: theme.spacing.sm,
          children: const [
            Host4Button(
              label: 'Primary',
              content: Host4ButtonContent.iconTop,
              icon: Icons.palette_outlined,
              onPressed: _noOp,
            ),
            Host4Button(
              label: 'Secondary',
              variant: Host4ButtonVariant.secondary,
              content: Host4ButtonContent.iconTop,
              icon: Icons.cloud_download_outlined,
              onPressed: _noOp,
            ),
            Host4Button(
              label: 'Ghost',
              variant: Host4ButtonVariant.ghost,
              content: Host4ButtonContent.iconTop,
              icon: Icons.info_outline_rounded,
              onPressed: _noOp,
            ),
          ],
        ),
        SizedBox(height: theme.spacing.section),

        // ── Icon Only ─────────────────────────────────────────
        Host4SectionHeader(
          title: 'Icon Only',
          subtitle: 'no label · square padding',
        ),
        SizedBox(height: theme.spacing.md),
        Wrap(
          spacing: theme.spacing.sm,
          runSpacing: theme.spacing.sm,
          children: const [
            Host4Button(
              label: 'Primary',
              content: Host4ButtonContent.iconOnly,
              icon: Icons.palette_outlined,
              onPressed: _noOp,
            ),
            Host4Button(
              label: 'Secondary',
              variant: Host4ButtonVariant.secondary,
              content: Host4ButtonContent.iconOnly,
              icon: Icons.cloud_download_outlined,
              onPressed: _noOp,
            ),
            Host4Button(
              label: 'Ghost',
              variant: Host4ButtonVariant.ghost,
              content: Host4ButtonContent.iconOnly,
              icon: Icons.info_outline_rounded,
              onPressed: _noOp,
            ),
          ],
        ),
        SizedBox(height: theme.spacing.section),

        // ── Expanded ──────────────────────────────────────────
        Host4SectionHeader(
          title: l10n.sectionExpanded,
          subtitle: 'expanded: true',
        ),
        SizedBox(height: theme.spacing.md),
        const Host4Button(
          label: 'Primary Expanded',
          expanded: true,
          onPressed: _noOp,
        ),
        SizedBox(height: theme.spacing.sm),
        const Host4Button(
          label: 'Secondary Expanded',
          variant: Host4ButtonVariant.secondary,
          expanded: true,
          onPressed: _noOp,
        ),
        SizedBox(height: theme.spacing.sm),
        const Host4Button(
          label: 'Ghost Expanded',
          variant: Host4ButtonVariant.ghost,
          expanded: true,
          onPressed: _noOp,
        ),
        SizedBox(height: theme.spacing.section),

        // ── Disabled ──────────────────────────────────────────
        Host4SectionHeader(
          title: l10n.sectionDisabled,
          subtitle: 'onPressed: null',
        ),
        SizedBox(height: theme.spacing.md),
        Wrap(
          spacing: theme.spacing.sm,
          runSpacing: theme.spacing.sm,
          children: const [
            Host4Button(
              label: 'Primary',
              onPressed: null,
            ),
            Host4Button(
              label: 'Secondary',
              variant: Host4ButtonVariant.secondary,
              onPressed: null,
            ),
            Host4Button(
              label: 'Ghost',
              variant: Host4ButtonVariant.ghost,
              onPressed: null,
            ),
          ],
        ),
      ],
    );
  }
}

void _noOp() {}

class ThemePlaygroundPage extends StatefulWidget {
  const ThemePlaygroundPage({super.key});

  @override
  State<ThemePlaygroundPage> createState() => _ThemePlaygroundPageState();
}

class _ThemePlaygroundPageState extends State<ThemePlaygroundPage> {
  late final TextEditingController _promptController;
  String? _localizedDefaultPrompt;

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextPrompt = AppLocalizations.of(context).promptExampleText;
    if (_promptController.text.isEmpty ||
        _promptController.text == _localizedDefaultPrompt) {
      _promptController.value = TextEditingValue(
        text: nextPrompt,
        selection: TextSelection.collapsed(offset: nextPrompt.length),
      );
    }
    _localizedDefaultPrompt = nextPrompt;
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.host4Theme;
    final manager = context.host4ThemeManager;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        theme.spacing.page,
        0,
        theme.spacing.page,
        theme.spacing.page,
      ),
      children: [
        Host4Banner(
          badge: l10n.localThemesBadge,
          imagePath: theme.images.promoBanner,
          title: l10n.currentThemeTitle(theme.meta.name),
          subtitle: l10n.currentThemeSubtitle,
        ),
        SizedBox(height: theme.spacing.section),
        Host4SectionHeader(
          title: l10n.switchThemesTitle,
          subtitle: l10n.switchThemesSubtitle,
        ),
        SizedBox(height: theme.spacing.md),
        Wrap(
          spacing: theme.spacing.sm,
          runSpacing: theme.spacing.sm,
          children: manager.catalog
              .map((entry) {
                final selected = entry.id == manager.currentThemeId;
                return Host4Button(
                  label: entry.name,
                  variant: selected
                      ? Host4ButtonVariant.primary
                      : Host4ButtonVariant.secondary,
                  onPressed: () {
                    _log.info('Theme switching to: ${entry.id}');
                    manager.applyTheme(entry.id, mode: manager.currentMode);
                  },
                );
              })
              .toList(growable: false),
        ),
        SizedBox(height: theme.spacing.section),
        Host4SectionHeader(
          title: l10n.switchModeTitle,
          subtitle: l10n.switchModeSubtitle,
        ),
        SizedBox(height: theme.spacing.md),
        Wrap(
          spacing: theme.spacing.sm,
          runSpacing: theme.spacing.sm,
          children: theme.meta.supportedModes
              .map((mode) {
                final selected = mode == manager.currentMode;
                return Host4Button(
                  label: _localizedModeLabel(l10n, mode),
                  variant: selected
                      ? Host4ButtonVariant.primary
                      : Host4ButtonVariant.secondary,
                  onPressed: () {
                    _log.info('Mode switching to: $mode');
                    manager.applyMode(mode);
                  },
                );
              })
              .toList(growable: false),
        ),
        SizedBox(height: theme.spacing.section),
        Host4Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Host4Text(l10n.promptInputTitle, role: Host4TextRole.heading),
              SizedBox(height: theme.spacing.sm),
              Host4Text(
                l10n.promptInputSubtitle,
                colorRole: Host4TextColorRole.secondary,
              ),
              SizedBox(height: theme.spacing.md),
              Host4TextField(
                controller: _promptController,
                hintText: l10n.promptHint,
                maxLines: 4,
              ),
              SizedBox(height: theme.spacing.md),
              Host4Button(
                label: l10n.generateThemeButton,
                content: Host4ButtonContent.iconLeft,
                icon: Icons.auto_awesome_outlined,
                expanded: true,
                onPressed: null,
              ),
            ],
          ),
        ),
        SizedBox(height: theme.spacing.section),
        Host4Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Host4Text(
                l10n.runtimeTokenPreviewTitle,
                role: Host4TextRole.heading,
              ),
              SizedBox(height: theme.spacing.md),
              Host4Text(
                l10n.currentModeLabel(
                  _localizedModeLabel(l10n, theme.meta.mode),
                ),
                colorRole: Host4TextColorRole.secondary,
              ),
              SizedBox(height: theme.spacing.md),
              Wrap(
                spacing: theme.spacing.sm,
                runSpacing: theme.spacing.sm,
                children: [
                  _ColorChip(
                    label: l10n.primaryLabel,
                    color: theme.colors.brandPrimary,
                  ),
                  _ColorChip(
                    label: l10n.secondaryLabel,
                    color: theme.colors.brandSecondary,
                  ),
                  _ColorChip(
                    label: l10n.accentLabel,
                    color: theme.colors.brandAccent,
                  ),
                  _ColorChip(
                    label: l10n.surfaceLabel,
                    color: theme.colors.surface,
                  ),
                  _ColorChip(
                    label: l10n.mutedLabel,
                    color: theme.colors.surfaceMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: theme.spacing.section),
        const _DebugPanel(),
      ],
    );
  }
}

class LanguagePage extends StatefulWidget {
  const LanguagePage({
    required this.localePreference,
    required this.onLocalePreferenceChanged,
    super.key,
  });

  final Locale? localePreference;
  final ValueChanged<Locale?> onLocalePreferenceChanged;

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  late Locale? _preference;

  @override
  void initState() {
    super.initState();
    _preference = widget.localePreference;
  }

  void _select(Locale? locale) {
    setState(() => _preference = locale);
    widget.onLocalePreferenceChanged(locale);
  }

  static String _systemLocaleName(AppLocalizations l10n) {
    final systemLocales = PlatformDispatcher.instance.locales;
    for (final locale in systemLocales) {
      if (_supportedLanguageCodes.contains(locale.languageCode)) {
        return switch (locale.languageCode) {
          'zh' => l10n.chineseLanguageName,
          _ => l10n.englishLanguageName,
        };
      }
    }
    return l10n.englishLanguageName;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.host4Theme;
    final isFollowingSystem = _preference == null;

    final languages = [
      (code: 'en', name: l10n.englishLanguageName),
      (code: 'zh', name: l10n.chineseLanguageName),
    ];

    return ListView(
      padding: EdgeInsets.fromLTRB(
        theme.spacing.page,
        0,
        theme.spacing.page,
        theme.spacing.page,
      ),
      children: [
        Host4ListCell(
          title: l10n.languageFollowSystem,
          subtitle: isFollowingSystem
              ? '${l10n.languageFollowSystemSubtitle} · ${_systemLocaleName(l10n)}'
              : l10n.languageFollowSystemSubtitle,
          trailingText: isFollowingSystem ? '✓' : null,
          onTap: () => _select(null),
        ),
        SizedBox(height: theme.spacing.section),
        Host4SectionHeader(title: l10n.languageManualSection, subtitle: ''),
        SizedBox(height: theme.spacing.sm),
        ...languages.map((lang) {
          final isActive = _preference?.languageCode == lang.code;
          return Padding(
            padding: EdgeInsets.only(bottom: theme.spacing.listGap),
            child: Host4ListCell(
              title: lang.name,
              subtitle: '',
              trailingText: isActive ? '✓' : null,
              onTap: () => _select(Locale(lang.code)),
            ),
          );
        }),
      ],
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.localePreference,
    required this.onLocalePreferenceChanged,
    required this.onResetToDefaults,
    super.key,
  });

  final Locale? localePreference;
  final ValueChanged<Locale?> onLocalePreferenceChanged;
  final Future<void> Function() onResetToDefaults;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.host4Theme;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        theme.spacing.page,
        0,
        theme.spacing.page,
        theme.spacing.page,
      ),
      children: [
        Host4Banner(
          badge: l10n.localThemesBadge,
          imagePath: theme.images.promoBanner,
          title: l10n.settingsBannerTitle,
          subtitle: l10n.settingsBannerSubtitle,
        ),
        SizedBox(height: theme.spacing.section),
        Host4ListCell(
          title: l10n.themePlaygroundPageTitle,
          subtitle: l10n.themePlaygroundPageSubtitle,
          leading: _ListIcon(
            icon: Icons.palette_outlined,
            color: theme.colors.brandPrimary,
          ),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => _SubPageScaffold(
              title: l10n.themePlaygroundPageTitle,
              subtitle: l10n.themePlaygroundPageSubtitle,
              child: const ThemePlaygroundPage(),
            ),
          )),
        ),
        SizedBox(height: theme.spacing.listGap),
        Host4ListCell(
          title: l10n.languagePageTitle,
          subtitle: l10n.languagePageSubtitle,
          leading: _ListIcon(
            icon: Icons.language_outlined,
            color: theme.colors.brandAccent,
          ),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => _SubPageScaffold(
              title: l10n.languagePageTitle,
              subtitle: l10n.languagePageSubtitle,
              child: LanguagePage(
                localePreference: localePreference,
                onLocalePreferenceChanged: onLocalePreferenceChanged,
              ),
            ),
          )),
        ),
        SizedBox(height: theme.spacing.listGap),
        Host4ListCell(
          title: l10n.logsPageTitle,
          subtitle: l10n.logsPageSubtitle,
          leading: _ListIcon(
            icon: Icons.article_outlined,
            color: theme.colors.success,
          ),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const LogsPage(),
          )),
        ),
        SizedBox(height: theme.spacing.listGap),
        Host4ListCell(
          title: l10n.testerPageTitle,
          subtitle: l10n.testerPageSubtitle,
          leading: _ListIcon(
            icon: Icons.developer_mode_outlined,
            color: theme.colors.brandSecondary,
          ),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => _SubPageScaffold(
              title: l10n.testerPageTitle,
              subtitle: l10n.testerPageSubtitle,
              child: TesterPage(onResetToDefaults: onResetToDefaults),
            ),
          )),
        ),
      ],
    );
  }
}

/// Sub-page scaffold that keeps the theme background image.
/// Used for Settings sub-pages (Theme Playground, Language, etc.).
class _SubPageScaffold extends StatelessWidget {
  const _SubPageScaffold({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return Host4PageScaffold(
      useSafeArea: false,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Host4NavigationBar(
              title: title,
              subtitle: subtitle,
              leading: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: theme.components.navigationBar.icon,
                  size: 20,
                ),
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Sub-page scaffold for component demo pages.
/// Uses a plain surface color (no background image) so components
/// are always shown against a neutral, predictable canvas.
class _ComponentDemoScaffold extends StatelessWidget {
  const _ComponentDemoScaffold({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return Scaffold(
      backgroundColor: theme.colors.pageBackground,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Host4NavigationBar(
              title: title,
              subtitle: subtitle,
              leading: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: theme.components.navigationBar.icon,
                  size: 20,
                ),
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class TesterPage extends StatelessWidget {
  const TesterPage({required this.onResetToDefaults, super.key});

  final Future<void> Function() onResetToDefaults;

  Future<void> _confirmReset(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.testerResetConfirmTitle),
        content: Text(l10n.testerResetConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.testerResetConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await onResetToDefaults();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.host4Theme;

    return GridView.count(
      crossAxisCount: 3,
      padding: EdgeInsets.all(theme.spacing.page),
      crossAxisSpacing: theme.spacing.md,
      mainAxisSpacing: theme.spacing.md,
      children: [
        _TesterGridItem(
          icon: Icons.restore_rounded,
          label: l10n.testerResetTitle,
          color: theme.colors.warning,
          onTap: () => _confirmReset(context),
        ),
      ],
    );
  }
}

class _TesterGridItem extends StatelessWidget {
  const _TesterGridItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return Material(
      color: theme.colors.surface,
      borderRadius: BorderRadius.circular(theme.radius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(theme.radius.md),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(theme.radius.md),
            border: Border.all(color: theme.colors.borderDefault),
          ),
          padding: EdgeInsets.all(theme.spacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(theme.radius.md),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              SizedBox(height: theme.spacing.sm),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.caption.toTextStyle(
                    theme.colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  String? _content;
  File? _file;
  bool _loading = true;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    final file = await Host4Logger.exportLogFile();
    final content = file != null && file.existsSync()
        ? file.readAsStringSync()
        : null;
    if (!mounted) return;
    setState(() {
      _file = file;
      _content = (content?.isEmpty ?? true) ? null : content;
      _loading = false;
    });
    if (_content != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  Future<void> _export() async {
    final file = _file;
    if (file == null || !file.existsSync()) return;
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'host4_flutter.log',
    );
  }

  Future<void> _confirmClear() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logsClearConfirmTitle),
        content: Text(l10n.logsClearConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.logsClearConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await Host4Logger.clearLogFile();
    setState(() => _content = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.host4Theme;

    return Host4PageScaffold(
      useSafeArea: false,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Host4NavigationBar(
              title: l10n.logsPageTitle,
              leading: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: theme.components.navigationBar.icon,
                  size: 20,
                ),
              ),
              trailing: GestureDetector(
                onTap: _confirmClear,
                child: Text(
                  l10n.logsClearButton,
                  style: theme.typography.label
                      .toTextStyle(theme.colors.warning),
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody(context)),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                theme.spacing.page,
                theme.spacing.sm,
                theme.spacing.page,
                theme.spacing.md,
              ),
              child: Host4Button(
                label: l10n.logsExportButton,
                content: Host4ButtonContent.iconLeft,
                icon: Icons.ios_share_rounded,
                expanded: true,
                onPressed: _content != null ? _export : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.host4Theme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_content == null) {
      return Center(
        child: Host4Text(
          l10n.logsEmptyMessage,
          colorRole: Host4TextColorRole.secondary,
        ),
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.all(theme.spacing.page),
      child: SizedBox(
        width: double.infinity,
        child: SelectableText(
          _content!,
          style: theme.typography.caption
              .toTextStyle(theme.colors.textPrimary)
              .copyWith(
                fontFamily: 'Courier New',
                fontFamilyFallback: const ['Courier', 'monospace'],
                fontSize: 13,
                height: 1.6,
              ),
        ),
      ),
    );
  }
}

class _ShellPage {
  const _ShellPage({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
  });

  final String title;
  final String subtitle;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return Host4Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Host4Text(title, role: Host4TextRole.heading),
          SizedBox(height: theme.spacing.sm),
          Host4Text(subtitle, colorRole: Host4TextColorRole.secondary),
          SizedBox(height: theme.spacing.lg),
          Host4Button(
            label: actionLabel,
            variant: Host4ButtonVariant.secondary,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _IllustrationBadge extends StatelessWidget {
  const _IllustrationBadge({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: theme.colors.surface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(theme.radius.card),
        border: Border.all(
          color: theme.colors.textInverse.withValues(alpha: 0.22),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(theme.radius.card - 2),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.landscape_rounded,
            color: theme.colors.textInverse,
            size: 34,
          ),
        ),
      ),
    );
  }
}

class _ListIcon extends StatelessWidget {
  const _ListIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(theme.radius.md),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return Container(
      padding: EdgeInsets.all(theme.spacing.sm),
      decoration: BoxDecoration(
        color: theme.colors.surfaceElevated,
        borderRadius: BorderRadius.circular(theme.radius.md),
        border: Border.all(color: theme.colors.borderDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(theme.radius.sm),
            ),
          ),
          SizedBox(width: theme.spacing.sm),
          Host4Text(label, role: Host4TextRole.caption),
        ],
      ),
    );
  }
}


String _localizedModeLabel(AppLocalizations l10n, String mode) {
  return switch (mode) {
    'dark' => l10n.modeDark,
    _ => l10n.modeLight,
  };
}

// ─── Debug Panel ────────────────────────────────────────────────────────────

class _DebugPanel extends StatelessWidget {
  const _DebugPanel();

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final manager = context.host4ThemeManager;

    final entry = manager.catalog.firstWhere(
      (e) => e.id == manager.currentThemeId,
      orElse: () => manager.catalog.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Host4SectionHeader(
          title: 'Debug Info',
          subtitle: 'Runtime state · tap values to copy',
        ),
        SizedBox(height: theme.spacing.md),

        // ── Theme state ──
        Host4Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Host4Text('Theme State', role: Host4TextRole.heading),
              SizedBox(height: theme.spacing.md),
              _DebugRow(
                label: 'id  (manifest.json)',
                value: theme.meta.id,
              ),
              _DebugRow(label: 'name', value: theme.meta.name),
              _DebugRow(label: 'schema', value: theme.meta.schema),
              _DebugRow(label: 'mode', value: theme.meta.mode),
              _DebugRow(label: 'defaultMode', value: theme.meta.defaultMode),
              _DebugRow(
                label: 'supportedModes',
                value: theme.meta.supportedModes.join(', '),
              ),
              _DebugRow(label: 'tokens file', value: entry.tokensAssetPath),
            ],
          ),
        ),
        SizedBox(height: theme.spacing.md),

        // ── Image paths ──
        Host4Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Host4Text('Image Paths', role: Host4TextRole.heading),
              SizedBox(height: theme.spacing.md),
              _DebugRow(
                label: 'pageBackground',
                value: theme.images.pageBackground,
              ),
              _DebugRow(
                label: 'pageOverlay',
                value: theme.images.pageOverlay,
              ),
              _DebugRow(label: 'heroBanner', value: theme.images.heroBanner),
              _DebugRow(label: 'promoBanner', value: theme.images.promoBanner),
              _DebugRow(
                label: 'spotIllustration',
                value: theme.images.spotIllustration,
              ),
            ],
          ),
        ),
        SizedBox(height: theme.spacing.md),

        // ── All color tokens ──
        Host4Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Host4Text('Color Tokens', role: Host4TextRole.heading),
              SizedBox(height: theme.spacing.md),
              Wrap(
                spacing: theme.spacing.sm,
                runSpacing: theme.spacing.sm,
                children: [
                  _ColorChip(
                    label: 'brandPrimary',
                    color: theme.colors.brandPrimary,
                  ),
                  _ColorChip(
                    label: 'brandSecondary',
                    color: theme.colors.brandSecondary,
                  ),
                  _ColorChip(
                    label: 'brandAccent',
                    color: theme.colors.brandAccent,
                  ),
                  _ColorChip(
                    label: 'pageBackground',
                    color: theme.colors.pageBackground,
                  ),
                  _ColorChip(label: 'surface', color: theme.colors.surface),
                  _ColorChip(
                    label: 'surfaceMuted',
                    color: theme.colors.surfaceMuted,
                  ),
                  _ColorChip(
                    label: 'surfaceElevated',
                    color: theme.colors.surfaceElevated,
                  ),
                  _ColorChip(
                    label: 'textPrimary',
                    color: theme.colors.textPrimary,
                  ),
                  _ColorChip(
                    label: 'textSecondary',
                    color: theme.colors.textSecondary,
                  ),
                  _ColorChip(
                    label: 'textInverse',
                    color: theme.colors.textInverse,
                  ),
                  _ColorChip(
                    label: 'borderDefault',
                    color: theme.colors.borderDefault,
                  ),
                  _ColorChip(
                    label: 'borderStrong',
                    color: theme.colors.borderStrong,
                  ),
                  _ColorChip(label: 'focus', color: theme.colors.focus),
                  _ColorChip(label: 'success', color: theme.colors.success),
                  _ColorChip(label: 'warning', color: theme.colors.warning),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DebugRow extends StatelessWidget {
  const _DebugRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return Padding(
      padding: EdgeInsets.only(bottom: theme.spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 148,
            child: Host4Text(
              label,
              role: Host4TextRole.caption,
              colorRole: Host4TextColorRole.secondary,
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.typography.caption.toTextStyle(
                theme.colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
