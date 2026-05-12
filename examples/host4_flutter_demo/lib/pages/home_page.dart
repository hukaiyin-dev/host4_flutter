import 'package:flutter/material.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';

import '../l10n/generated/app_localizations.dart';
import '../widgets/sub_page_scaffold.dart';
import 'debug_inspector_page.dart';
import 'gmacro/gmacro_entry_page.dart';
import 'logs_page.dart';
import 'tester_page.dart';
import 'theme_playground_page.dart';
import 'usb_drive_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({required this.onResetToDefaults, super.key});

  final Future<void> Function() onResetToDefaults;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.host4Theme;
    final entries = <_LabEntry>[
      _LabEntry(
        title: l10n.labThemePlaygroundTitle,
        subtitle: l10n.labThemePlaygroundSubtitle,
        icon: Icons.palette_outlined,
        color: theme.colors.brandPrimary,
        minHeight: 250,
        builder: (_) => SubPageScaffold(
          title: l10n.themePlaygroundPageTitle,
          subtitle: l10n.themePlaygroundPageSubtitle,
          child: const ThemePlaygroundPage(),
        ),
      ),
      _LabEntry(
        title: l10n.labLogsTitle,
        subtitle: l10n.labLogsSubtitle,
        icon: Icons.ios_share_rounded,
        color: theme.colors.success,
        minHeight: 220,
        builder: (_) => const LogsPage(),
      ),
      _LabEntry(
        title: l10n.labDebugTitle,
        subtitle: l10n.labDebugSubtitle,
        icon: Icons.analytics_outlined,
        color: theme.colors.brandAccent,
        minHeight: 280,
        builder: (_) => SubPageScaffold(
          title: l10n.labDebugTitle,
          subtitle: l10n.labDebugSubtitle,
          child: const DebugInspectorPage(),
        ),
      ),
      _LabEntry(
        title: l10n.labUsbDriveTitle,
        subtitle: l10n.labUsbDriveSubtitle,
        icon: Icons.usb_rounded,
        color: theme.colors.brandSecondary,
        minHeight: 260,
        builder: (_) => SubPageScaffold(
          title: l10n.usbDrivePageTitle,
          subtitle: l10n.usbDrivePageSubtitle,
          child: const UsbDrivePage(),
        ),
      ),
      _LabEntry(
        title: l10n.labTesterTitle,
        subtitle: l10n.labTesterSubtitle,
        icon: Icons.science_outlined,
        color: theme.colors.warning,
        minHeight: 210,
        builder: (_) => SubPageScaffold(
          title: l10n.testerPageTitle,
          subtitle: l10n.testerPageSubtitle,
          child: TesterPage(onResetToDefaults: onResetToDefaults),
        ),
      ),
      _LabEntry(
        title: 'GMacro 调试',
        subtitle: 'BLE / MFi 主链路 + OTA 测试',
        icon: Icons.gamepad_outlined,
        color: theme.colors.brandPrimary,
        minHeight: 220,
        builder: (_) => const GmacroEntryPage(),
      ),
    ];

    final leftColumn = <Widget>[];
    final rightColumn = <Widget>[];
    for (var index = 0; index < entries.length; index++) {
      final card = _LabCard(entry: entries[index]);
      if (index.isEven) {
        leftColumn.add(card);
      } else {
        rightColumn.add(card);
      }
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        theme.spacing.page,
        0,
        theme.spacing.page,
        theme.spacing.page,
      ),
      children: [
        Host4SectionHeader(
          title: l10n.homePageTitle,
          subtitle: l10n.homePageSubtitle,
        ),
        SizedBox(height: theme.spacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  for (var i = 0; i < leftColumn.length; i++) ...[
                    if (i > 0) SizedBox(height: theme.spacing.md),
                    leftColumn[i],
                  ],
                ],
              ),
            ),
            SizedBox(width: theme.spacing.md),
            Expanded(
              child: Column(
                children: [
                  for (var i = 0; i < rightColumn.length; i++) ...[
                    if (i > 0) SizedBox(height: theme.spacing.md),
                    rightColumn[i],
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LabEntry {
  const _LabEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.minHeight,
    required this.builder,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double minHeight;
  final WidgetBuilder builder;
}

class _LabCard extends StatelessWidget {
  const _LabCard({required this.entry});

  final _LabEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.host4Theme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(theme.radius.card),
        onTap: () =>
            Navigator.of(context).push(MaterialPageRoute(builder: entry.builder)),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colors.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(theme.radius.card),
            border: Border.all(color: theme.colors.borderDefault),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 22,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: entry.minHeight),
            child: Padding(
              padding: EdgeInsets.all(theme.spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: entry.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(theme.radius.lg),
                    ),
                    child: Icon(entry.icon, color: entry.color, size: 28),
                  ),
                  SizedBox(height: theme.spacing.lg),
                  Host4Text(entry.title, role: Host4TextRole.heading),
                  SizedBox(height: theme.spacing.sm),
                  Host4Text(
                    entry.subtitle,
                    colorRole: Host4TextColorRole.secondary,
                  ),
                  SizedBox(height: theme.spacing.xxl),
                  SizedBox(height: theme.spacing.lg),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: theme.spacing.sm,
                          vertical: theme.spacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colors.surfaceMuted,
                          borderRadius: BorderRadius.circular(theme.radius.pill),
                        ),
                        child: Text(
                          l10n.inspectButton,
                          style: theme.typography.caption.toTextStyle(
                            theme.colors.textSecondary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_outward_rounded,
                        color: theme.colors.textSecondary,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
