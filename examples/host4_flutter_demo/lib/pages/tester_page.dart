import 'package:flutter/material.dart';
import 'package:host4_flutter_log/host4_flutter_log.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme_job.dart';
import '../theme_job_poller.dart';

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

  Future<void> _confirmClearRecords(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.testerClearRecordsConfirmTitle),
        content: Text(l10n.testerClearRecordsConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.testerClearRecordsConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    ThemeJobPoller.instance.stop();
    await Host4Logger.clearLogFile();
    await ThemeJobStore.instance.clear();
    ThemeJobPoller.instance.reconcile();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.testerClearRecordsDone)),
    );
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
        _TesterGridItem(
          icon: Icons.delete_sweep_outlined,
          label: l10n.testerClearRecordsTitle,
          color: Colors.red,
          onTap: () => _confirmClearRecords(context),
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
