import 'package:flutter/material.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';

import '../l10n/generated/app_localizations.dart';
import '../widgets/list_icon.dart';

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
          leading: ListIcon(
            icon: Icons.smart_button_outlined,
            color: theme.colors.brandPrimary,
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => _ComponentDemoScaffold(
                title: l10n.componentButtonsTitle,
                subtitle: l10n.componentButtonsSubtitle,
                child: const ButtonsPage(),
              ),
            ),
          ),
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
            Host4Button(label: 'Primary', onPressed: _noOp),
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
        Host4SectionHeader(title: 'Icon Top', subtitle: 'icon above label'),
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
            Host4Button(label: 'Primary', onPressed: null),
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
