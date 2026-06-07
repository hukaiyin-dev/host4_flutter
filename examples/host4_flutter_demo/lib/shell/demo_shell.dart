import 'package:flutter/material.dart';
import 'package:host4_flutter_log/host4_flutter_log.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';

import '../integration/analytics/app_analytics.dart';
import '../l10n/generated/app_localizations.dart';
import '../pages/components_page.dart';
import '../pages/home_page.dart';
import '../pages/settings_page.dart';

final _log = Host4Logger('Shell');

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
        child: HomePage(onResetToDefaults: widget.onResetToDefaults),
      ),
      _ShellPage(
        title: l10n.listPageTitle,
        subtitle: l10n.listPageSubtitle,
        child: const ComponentsPage(),
      ),
      _ShellPage(
        title: l10n.settingsPageTitle,
        subtitle: l10n.settingsPageSubtitle,
        handlesOwnTopChrome: true,
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
          useSafeArea: !currentPage.handlesOwnTopChrome,
          bottomNavigationBar: Host4TabBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              _log.debug('Tab selected: $index');
              appAnalytics.track(
                'tab_selected',
                properties: {'index': index},
              );
              setState(() => _currentIndex = index);
            },
            items: [
              // TODO: add fallbackIcon/fallbackSelectedIcon SVG paths once Figma icons are exported
              Host4TabItem(index: 0, label: l10n.tabHome),
              Host4TabItem(index: 1, label: l10n.tabList),
              Host4TabItem(index: 2, label: l10n.tabSettings),
            ],
          ),
          body: Column(
            children: [
              if (!currentPage.handlesOwnTopChrome)
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

class _ShellPage {
  const _ShellPage({
    required this.title,
    required this.subtitle,
    required this.child,
    this.handlesOwnTopChrome = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool handlesOwnTopChrome;
}

String _localizedModeLabel(AppLocalizations l10n, String mode) {
  return switch (mode) {
    'dark' => l10n.modeDark,
    _ => l10n.modeLight,
  };
}
