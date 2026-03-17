import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';

import 'l10n/generated/app_localizations.dart';

void main() {
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
  Locale _locale = const Locale('en');

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
    _bootstrapFuture = _themeManager.initialize('default');
  }

  @override
  void dispose() {
    _themeManager.dispose();
    super.dispose();
  }

  void _setLocale(Locale locale) {
    if (_locale == locale) {
      return;
    }
    setState(() => _locale = locale);
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
                home: Host4DemoShell(onLocaleChanged: _setLocale),
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
      locale: _locale,
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
  const Host4DemoShell({required this.onLocaleChanged, super.key});

  final ValueChanged<Locale> onLocaleChanged;

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
        child: const ListPage(),
      ),
      _ShellPage(
        title: l10n.themePlaygroundPageTitle,
        subtitle: l10n.themePlaygroundPageSubtitle,
        child: const ThemePlaygroundPage(),
      ),
      _ShellPage(
        title: l10n.languagePageTitle,
        subtitle: l10n.languagePageSubtitle,
        child: LanguagePage(onLocaleChanged: widget.onLocaleChanged),
      ),
    ];
    final currentPage = pages[_currentIndex];

    return Stack(
      children: [
        Host4PageScaffold(
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
              Padding(
                padding: EdgeInsets.fromLTRB(
                  theme.spacing.page,
                  0,
                  theme.spacing.page,
                  theme.spacing.page,
                ),
                child: Host4Card(
                  padding: EdgeInsets.all(theme.spacing.sm),
                  child: Wrap(
                    spacing: theme.spacing.xs,
                    runSpacing: theme.spacing.xs,
                    children: List.generate(pages.length, (index) {
                      final page = pages[index];
                      final selected = index == _currentIndex;
                      return SizedBox(
                        width: 156,
                        child: Host4Button(
                          label: page.title,
                          variant: selected
                              ? Host4ButtonVariant.primary
                              : Host4ButtonVariant.ghost,
                          expanded: true,
                          onPressed: () =>
                              setState(() => _currentIndex = index),
                        ),
                      );
                    }),
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

class ListPage extends StatelessWidget {
  const ListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.host4Theme;
    final listItems = _buildListItems(l10n);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        theme.spacing.page,
        0,
        theme.spacing.page,
        theme.spacing.page,
      ),
      children: [
        Host4SearchBar(hintText: l10n.searchHint),
        SizedBox(height: theme.spacing.section),
        Host4SectionHeader(
          title: l10n.componentInventoryTitle,
          subtitle: l10n.componentInventorySubtitle,
        ),
        SizedBox(height: theme.spacing.md),
        ...List.generate(
          listItems.length,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: theme.spacing.listGap),
            child: Host4ListCell(
              title: listItems[index].title,
              subtitle: listItems[index].subtitle,
              trailingText: listItems[index].badge,
              leading: _ListIcon(
                icon: listItems[index].icon,
                color: index.isEven
                    ? theme.colors.brandPrimary
                    : theme.colors.brandAccent,
              ),
            ),
          ),
        ),
        SizedBox(height: theme.spacing.section),
        Host4Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Host4Text(l10n.listDiagnosticsTitle, role: Host4TextRole.heading),
              SizedBox(height: theme.spacing.sm),
              Host4Text(
                l10n.listDiagnosticsBody,
                colorRole: Host4TextColorRole.secondary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

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
                  onPressed: () =>
                      manager.applyTheme(entry.id, mode: manager.currentMode),
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
                  onPressed: () => manager.applyMode(mode),
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

class LanguagePage extends StatelessWidget {
  const LanguagePage({required this.onLocaleChanged, super.key});

  final ValueChanged<Locale> onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.host4Theme;
    final locale = Localizations.localeOf(context);
    final currentLanguage = switch (locale.languageCode) {
      'zh' => l10n.chineseLanguageName,
      _ => l10n.englishLanguageName,
    };

    return ListView(
      padding: EdgeInsets.fromLTRB(
        theme.spacing.page,
        0,
        theme.spacing.page,
        theme.spacing.page,
      ),
      children: [
        Host4Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Host4Text(
                l10n.languageSettingsTitle,
                role: Host4TextRole.heading,
              ),
              SizedBox(height: theme.spacing.sm),
              Host4Text(
                l10n.languageSettingsSubtitle,
                colorRole: Host4TextColorRole.secondary,
              ),
              SizedBox(height: theme.spacing.lg),
              Host4Text(
                l10n.currentLanguageLabel(currentLanguage),
                colorRole: Host4TextColorRole.secondary,
              ),
              SizedBox(height: theme.spacing.md),
              Wrap(
                spacing: theme.spacing.sm,
                runSpacing: theme.spacing.sm,
                children: [
                  Host4Button(
                    label: l10n.switchToEnglishButton,
                    variant: locale.languageCode == 'en'
                        ? Host4ButtonVariant.primary
                        : Host4ButtonVariant.secondary,
                    onPressed: () => onLocaleChanged(const Locale('en')),
                  ),
                  Host4Button(
                    label: l10n.switchToChineseButton,
                    variant: locale.languageCode == 'zh'
                        ? Host4ButtonVariant.primary
                        : Host4ButtonVariant.secondary,
                    onPressed: () => onLocaleChanged(const Locale('zh')),
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

class _ListItemData {
  const _ListItemData({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
}

List<_ListItemData> _buildListItems(AppLocalizations l10n) {
  return [
    _ListItemData(
      title: l10n.themeRegistryTitle,
      subtitle: l10n.themeRegistrySubtitle,
      badge: l10n.badgeP0,
      icon: Icons.folder_outlined,
    ),
    _ListItemData(
      title: l10n.tokenParserTitle,
      subtitle: l10n.tokenParserSubtitle,
      badge: l10n.badgeReady,
      icon: Icons.data_object_rounded,
    ),
    _ListItemData(
      title: l10n.themeScopeTitle,
      subtitle: l10n.themeScopeSubtitle,
      badge: l10n.badgeLive,
      icon: Icons.refresh_rounded,
    ),
    _ListItemData(
      title: l10n.playgroundTitle,
      subtitle: l10n.playgroundSubtitle,
      badge: l10n.badgeStub,
      icon: Icons.auto_awesome_outlined,
    ),
  ];
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
