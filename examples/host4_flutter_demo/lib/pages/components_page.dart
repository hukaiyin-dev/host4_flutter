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
          subtitle: 'primary · secondary · tertiary · outline · ghost · danger · danger-soft',
        ),
        SizedBox(height: theme.spacing.md),
        Wrap(
          spacing: theme.spacing.sm,
          runSpacing: theme.spacing.sm,
          children: _variantButtons(
            content: Host4ButtonContent.textOnly,
            labels: _variantLabels,
          ),
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
          children: _variantButtons(
            content: Host4ButtonContent.iconLeft,
            labels: _variantLabels,
          ),
        ),
        SizedBox(height: theme.spacing.section),

        // ── Icon Top ──────────────────────────────────────────
        Host4SectionHeader(title: 'Icon Top', subtitle: 'icon above label'),
        SizedBox(height: theme.spacing.md),
        Wrap(
          spacing: theme.spacing.sm,
          runSpacing: theme.spacing.sm,
          children: _variantButtons(
            content: Host4ButtonContent.iconTop,
            labels: _variantLabels,
          ),
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
          children: _variantButtons(
            content: Host4ButtonContent.iconOnly,
            labels: _variantLabels,
          ),
        ),
        SizedBox(height: theme.spacing.section),

        // ── Expanded ──────────────────────────────────────────
        Host4SectionHeader(
          title: l10n.sectionExpanded,
          subtitle: 'expanded: true',
        ),
        SizedBox(height: theme.spacing.md),
        ..._expandedButtons(theme),
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
          children: _disabledButtons(),
        ),
        SizedBox(height: theme.spacing.section),

        // ── Loading ───────────────────────────────────────────
        Host4SectionHeader(
          title: 'Loading',
          subtitle: 'component.button.loading + non-interactive',
        ),
        SizedBox(height: theme.spacing.md),
        Wrap(
          spacing: theme.spacing.sm,
          runSpacing: theme.spacing.sm,
          children: _loadingButtons(),
        ),
        SizedBox(height: theme.spacing.section),

        // ── State Preview ─────────────────────────────────────
        Host4SectionHeader(
          title: 'State Preview',
          subtitle: 'default · hover · pressed · focused',
        ),
        SizedBox(height: theme.spacing.md),
        ..._statePreviewGroups(theme),
      ],
    );
  }

  List<Widget> _variantButtons({
    required Host4ButtonContent content,
    required Map<Host4ButtonVariant, String> labels,
  }) {
    return Host4ButtonVariant.values.map((variant) {
      return Host4Button(
        label: labels[variant]!,
        variant: variant,
        content: content,
        icon: content == Host4ButtonContent.textOnly ? null : _variantIcon(variant),
        onPressed: _noOp,
      );
    }).toList();
  }

  List<Widget> _expandedButtons(Host4RuntimeTheme theme) {
    final widgets = <Widget>[];
    for (final variant in Host4ButtonVariant.values) {
      widgets.add(
        Host4Button(
          label: '${_variantLabels[variant]} Expanded',
          variant: variant,
          expanded: true,
          onPressed: _noOp,
        ),
      );
      if (variant != Host4ButtonVariant.values.last) {
        widgets.add(SizedBox(height: theme.spacing.sm));
      }
    }
    return widgets;
  }

  List<Widget> _disabledButtons() {
    return Host4ButtonVariant.values.map((variant) {
      return Host4Button(
        label: _variantLabels[variant]!,
        variant: variant,
        onPressed: null,
      );
    }).toList();
  }

  List<Widget> _loadingButtons() {
    return Host4ButtonVariant.values.map((variant) {
      return Host4Button(
        label: _variantLabels[variant]!,
        variant: variant,
        loading: true,
        onPressed: _noOp,
      );
    }).toList();
  }

  List<Widget> _statePreviewGroups(Host4RuntimeTheme theme) {
    return Host4ButtonVariant.values.map((variant) {
      return Padding(
        padding: EdgeInsets.only(bottom: theme.spacing.section),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _variantLabels[variant]!,
              style: theme.typography.heading.toTextStyle(theme.colors.textPrimary),
            ),
            SizedBox(height: theme.spacing.md),
            Wrap(
              spacing: theme.spacing.sm,
              runSpacing: theme.spacing.sm,
              children: _ButtonPreviewState.values.map((state) {
                return _ButtonStatePreview(
                  label: _previewStateLabel(state),
                  variant: variant,
                  state: state,
                );
              }).toList(),
            ),
          ],
        ),
      );
    }).toList();
  }
}

void _noOp() {}

const Map<Host4ButtonVariant, String> _variantLabels = {
  Host4ButtonVariant.primary: 'Primary',
  Host4ButtonVariant.secondary: 'Secondary',
  Host4ButtonVariant.tertiary: 'Tertiary',
  Host4ButtonVariant.outline: 'Outline',
  Host4ButtonVariant.ghost: 'Ghost',
  Host4ButtonVariant.danger: 'Danger',
  Host4ButtonVariant.dangerSoft: 'Danger Soft',
};

enum _ButtonPreviewState { defaultState, hover, pressed, focused }

String _previewStateLabel(_ButtonPreviewState state) {
  return switch (state) {
    _ButtonPreviewState.defaultState => 'Default',
    _ButtonPreviewState.hover => 'Hover',
    _ButtonPreviewState.pressed => 'Pressed',
    _ButtonPreviewState.focused => 'Focused',
  };
}

IconData _variantIcon(Host4ButtonVariant variant) {
  return switch (variant) {
    Host4ButtonVariant.primary => Icons.palette_outlined,
    Host4ButtonVariant.secondary => Icons.cloud_download_outlined,
    Host4ButtonVariant.tertiary => Icons.tune_rounded,
    Host4ButtonVariant.outline => Icons.dashboard_outlined,
    Host4ButtonVariant.ghost => Icons.info_outline_rounded,
    Host4ButtonVariant.danger => Icons.delete_outline_rounded,
    Host4ButtonVariant.dangerSoft => Icons.warning_amber_rounded,
  };
}

class _ButtonStatePreview extends StatelessWidget {
  const _ButtonStatePreview({
    required this.label,
    required this.variant,
    required this.state,
  });

  final String label;
  final Host4ButtonVariant variant;
  final _ButtonPreviewState state;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final buttonTokens = theme.components.button;
    final variantTokens = switch (variant) {
      Host4ButtonVariant.primary => buttonTokens.primary,
      Host4ButtonVariant.secondary => buttonTokens.secondary,
      Host4ButtonVariant.tertiary => buttonTokens.tertiary,
      Host4ButtonVariant.outline => buttonTokens.outline,
      Host4ButtonVariant.ghost => buttonTokens.ghost,
      Host4ButtonVariant.danger => buttonTokens.danger,
      Host4ButtonVariant.dangerSoft => buttonTokens.dangerSoft,
    };
    final stateTokens = switch (state) {
      _ButtonPreviewState.defaultState => variantTokens.defaultState,
      _ButtonPreviewState.hover => variantTokens.hoverState,
      _ButtonPreviewState.pressed => variantTokens.pressedState,
      _ButtonPreviewState.focused => variantTokens.focusedState,
    };
    final ring = buttonTokens.focusedRing;

    return Container(
      constraints: BoxConstraints(minHeight: buttonTokens.minHeight),
      padding: EdgeInsets.symmetric(
        horizontal: buttonTokens.spacing.horizontal,
        vertical: buttonTokens.spacing.vertical,
      ),
      decoration: BoxDecoration(
        color: stateTokens.background,
        borderRadius: BorderRadius.circular(variantTokens.radius),
        border: Border.all(color: stateTokens.border),
        boxShadow: state == _ButtonPreviewState.focused
            ? [
                BoxShadow(
                  color: ring.color,
                  spreadRadius: ring.offsetWidth + ring.width,
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: stateTokens.background,
                  spreadRadius: ring.offsetWidth,
                  blurRadius: 0,
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: buttonTokens.labelStyle.toTextStyle(stateTokens.foreground),
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
