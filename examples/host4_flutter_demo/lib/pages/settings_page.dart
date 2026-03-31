import 'package:flutter/material.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';

import '../integration/app_bootstrap.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/list_icon.dart';
import '../widgets/sub_page_scaffold.dart';
import 'logs_page.dart';
import 'onboarding_demo_page.dart';
import 'tester_page.dart';
import 'theme_playground_page.dart';

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

    return Column(
      children: [
        _SettingsHero(
          title: l10n.settingsBannerTitle,
          subtitle: l10n.settingsBannerSubtitle,
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              theme.spacing.page,
              theme.spacing.section,
              theme.spacing.page,
              theme.spacing.page,
            ),
            children: [
              Host4ListCell(
                title: l10n.themePlaygroundPageTitle,
                subtitle: l10n.themePlaygroundPageSubtitle,
                leading: ListIcon(
                  icon: Icons.palette_outlined,
                  color: theme.colors.brandPrimary,
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SubPageScaffold(
                      title: l10n.themePlaygroundPageTitle,
                      subtitle: l10n.themePlaygroundPageSubtitle,
                      child: const ThemePlaygroundPage(),
                    ),
                  ),
                ),
              ),
              SizedBox(height: theme.spacing.listGap),
              Host4ListCell(
                title: l10n.languagePageTitle,
                subtitle: l10n.languagePageSubtitle,
                leading: ListIcon(
                  icon: Icons.language_outlined,
                  color: theme.colors.brandAccent,
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SubPageScaffold(
                      title: l10n.languagePageTitle,
                      subtitle: l10n.languagePageSubtitle,
                      child: LanguagePage(
                        localePreference: localePreference,
                        onLocalePreferenceChanged: onLocalePreferenceChanged,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: theme.spacing.listGap),
              Host4ListCell(
                title: l10n.logsPageTitle,
                subtitle: l10n.logsPageSubtitle,
                leading: ListIcon(
                  icon: Icons.article_outlined,
                  color: theme.colors.success,
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const LogsPage()),
                ),
              ),
              SizedBox(height: theme.spacing.listGap),
              Host4ListCell(
                title: l10n.onboardingDemoSettingsTitle,
                subtitle: l10n.onboardingDemoSettingsSubtitle,
                leading: ListIcon(
                  icon: Icons.rocket_launch_outlined,
                  color: theme.colors.brandAccent,
                ),
                onTap: () => pushOnboardingDemo(context),
              ),
              SizedBox(height: theme.spacing.listGap),
              Host4ListCell(
                title: l10n.testerPageTitle,
                subtitle: l10n.testerPageSubtitle,
                leading: ListIcon(
                  icon: Icons.developer_mode_outlined,
                  color: theme.colors.brandSecondary,
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SubPageScaffold(
                      title: l10n.testerPageTitle,
                      subtitle: l10n.testerPageSubtitle,
                      child: TesterPage(onResetToDefaults: onResetToDefaults),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsHero extends StatelessWidget {
  const _SettingsHero({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.host4Theme;
    final topInset = MediaQuery.paddingOf(context).top;
    const heroHeight = 280.0;
    const spotSize = 132.0;

    return SizedBox(
      height: heroHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: heroHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  theme.images.heroBanner,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => DecoratedBox(
                    decoration: BoxDecoration(color: theme.colors.brandPrimary),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.10),
                        Colors.black.withValues(alpha: 0.44),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    theme.spacing.page,
                    topInset + theme.spacing.sm,
                    theme.spacing.page,
                    0,
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: theme.spacing.sm,
                        vertical: theme.spacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.24),
                        borderRadius: BorderRadius.circular(theme.radius.pill),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Text(
                        '${theme.meta.name} · ${_localizedModeLabel(l10n, theme.meta.mode)}',
                        style: theme.typography.caption.toTextStyle(
                          theme.colors.textInverse.withValues(alpha: 0.92),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    theme.spacing.page,
                    topInset + theme.spacing.xl,
                    spotSize + (theme.spacing.page * 2),
                    theme.spacing.page,
                  ),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.typography.title.toTextStyle(
                            theme.colors.textInverse,
                          ),
                        ),
                        SizedBox(height: theme.spacing.xs),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.typography.body.toTextStyle(
                            theme.colors.textInverse.withValues(alpha: 0.88),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: theme.spacing.page,
            bottom: theme.spacing.page,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: spotSize,
                maxHeight: spotSize,
              ),
              child: Image.asset(
                theme.images.spotIllustration,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: theme.colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(theme.radius.lg),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Language page ─────────────────────────────────────────────────────────────

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
    final systemLocales =
        WidgetsBinding.instance.platformDispatcher.locales;
    for (final locale in systemLocales) {
      if (supportedLanguageCodes.contains(locale.languageCode)) {
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

String _localizedModeLabel(AppLocalizations l10n, String mode) {
  return switch (mode) {
    'dark' => l10n.modeDark,
    _ => l10n.modeLight,
  };
}
