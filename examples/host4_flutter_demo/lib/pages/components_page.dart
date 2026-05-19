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
    final theme = context.host4Theme;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        theme.spacing.page,
        0,
        theme.spacing.page,
        theme.spacing.page,
      ),
      children: [
        Host4SectionHeader(
          title: 'Figma Matrix',
          subtitle: 'Match the button component sheet in node 147:3176',
        ),
        SizedBox(height: theme.spacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            padding: EdgeInsets.all(theme.spacing.lg),
            decoration: BoxDecoration(
              color: theme.colors.surface,
              borderRadius: BorderRadius.circular(theme.radius.card),
              border: Border.all(color: theme.colors.borderDefault),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < _figmaButtonColumns.length; index++) ...[
                  _FigmaButtonColumnView(column: _figmaButtonColumns[index]),
                  if (index != _figmaButtonColumns.length - 1)
                    SizedBox(width: theme.spacing.lg),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

enum _ButtonPreviewState { defaultState, hover, pressed, focused, selected }

class _FigmaButtonColumn {
  const _FigmaButtonColumn({required this.buttons});

  final List<_FigmaButtonSpec> buttons;
}

class _FigmaButtonSpec {
  const _FigmaButtonSpec({
    required this.variant,
    required this.size,
    required this.content,
    required this.state,
    this.icon,
  });

  final Host4ButtonVariant variant;
  final Host4ButtonSize size;
  final Host4ButtonContent content;
  final _ButtonPreviewState state;
  final IconData? icon;

  bool get showsLabel => content != Host4ButtonContent.iconOnly;
}

class _FigmaButtonMetrics {
  const _FigmaButtonMetrics({
    required this.width,
    required this.height,
    required this.iconSize,
  });

  final double width;
  final double height;
  final double iconSize;
}

const List<_FigmaButtonColumn> _figmaButtonColumns = [
  _FigmaButtonColumn(
    buttons: [
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.defaultState,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.hover,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.pressed,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.focused,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.selected,
      ),
    ],
  ),
  _FigmaButtonColumn(
    buttons: [
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.defaultState,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.hover,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.pressed,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.focused,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.selected,
      ),
    ],
  ),
  _FigmaButtonColumn(
    buttons: [
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.iconLeft,
        state: _ButtonPreviewState.defaultState,
        icon: Icons.refresh_rounded,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.iconLeft,
        state: _ButtonPreviewState.hover,
        icon: Icons.refresh_rounded,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.iconLeft,
        state: _ButtonPreviewState.pressed,
        icon: Icons.refresh_rounded,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.iconLeft,
        state: _ButtonPreviewState.focused,
        icon: Icons.refresh_rounded,
      ),
    ],
  ),
  _FigmaButtonColumn(
    buttons: [
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.iconRight,
        state: _ButtonPreviewState.defaultState,
        icon: Icons.refresh_rounded,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.iconRight,
        state: _ButtonPreviewState.hover,
        icon: Icons.refresh_rounded,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.iconRight,
        state: _ButtonPreviewState.pressed,
        icon: Icons.refresh_rounded,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.iconRight,
        state: _ButtonPreviewState.focused,
        icon: Icons.refresh_rounded,
      ),
    ],
  ),
  _FigmaButtonColumn(
    buttons: [
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.iconOnly,
        state: _ButtonPreviewState.defaultState,
        icon: Icons.delete_outline_rounded,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.iconOnly,
        state: _ButtonPreviewState.hover,
        icon: Icons.delete_outline_rounded,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.iconOnly,
        state: _ButtonPreviewState.pressed,
        icon: Icons.delete_outline_rounded,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.iconOnly,
        state: _ButtonPreviewState.focused,
        icon: Icons.delete_outline_rounded,
      ),
    ],
  ),
  _FigmaButtonColumn(
    buttons: [
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.xs,
        content: Host4ButtonContent.iconOnly,
        state: _ButtonPreviewState.defaultState,
        icon: Icons.delete_outline_rounded,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.xs,
        content: Host4ButtonContent.iconOnly,
        state: _ButtonPreviewState.hover,
        icon: Icons.delete_outline_rounded,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.xs,
        content: Host4ButtonContent.iconOnly,
        state: _ButtonPreviewState.pressed,
        icon: Icons.delete_outline_rounded,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.xs,
        content: Host4ButtonContent.iconOnly,
        state: _ButtonPreviewState.focused,
        icon: Icons.delete_outline_rounded,
      ),
    ],
  ),
  _FigmaButtonColumn(
    buttons: [
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.primary,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.defaultState,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.primary,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.hover,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.primary,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.pressed,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.primary,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.focused,
      ),
    ],
  ),
  _FigmaButtonColumn(
    buttons: [
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.primary,
        size: Host4ButtonSize.xs,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.defaultState,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.primary,
        size: Host4ButtonSize.xs,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.hover,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.primary,
        size: Host4ButtonSize.xs,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.pressed,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.primary,
        size: Host4ButtonSize.xs,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.focused,
      ),
    ],
  ),
  _FigmaButtonColumn(
    buttons: [
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.popoverPrimary,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.defaultState,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.popoverPrimary,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.hover,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.popoverPrimary,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.pressed,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.popoverPrimary,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.focused,
      ),
    ],
  ),
  _FigmaButtonColumn(
    buttons: [
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.popoverSecondary,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.defaultState,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.popoverSecondary,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.hover,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.popoverSecondary,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.pressed,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.popoverSecondary,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.focused,
      ),
    ],
  ),
  _FigmaButtonColumn(
    buttons: [
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.dangerSoft,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.iconLeft,
        state: _ButtonPreviewState.defaultState,
        icon: Icons.refresh_rounded,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.dangerSoft,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.iconLeft,
        state: _ButtonPreviewState.hover,
        icon: Icons.refresh_rounded,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.dangerSoft,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.iconLeft,
        state: _ButtonPreviewState.pressed,
        icon: Icons.refresh_rounded,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.dangerSoft,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.iconLeft,
        state: _ButtonPreviewState.focused,
        icon: Icons.refresh_rounded,
      ),
    ],
  ),
  _FigmaButtonColumn(
    buttons: [
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.dangerHigh,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.defaultState,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.dangerHigh,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.hover,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.dangerHigh,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.pressed,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.dangerHigh,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.focused,
      ),
    ],
  ),
  _FigmaButtonColumn(
    buttons: [
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.secondary,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.iconLeft,
        state: _ButtonPreviewState.defaultState,
        icon: Icons.refresh_rounded,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.secondary,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.iconLeft,
        state: _ButtonPreviewState.hover,
        icon: Icons.refresh_rounded,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.secondary,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.iconLeft,
        state: _ButtonPreviewState.pressed,
        icon: Icons.refresh_rounded,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.secondary,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.iconLeft,
        state: _ButtonPreviewState.focused,
        icon: Icons.refresh_rounded,
      ),
    ],
  ),
  _FigmaButtonColumn(
    buttons: [
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.secondary,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.defaultState,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.secondary,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.hover,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.secondary,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.pressed,
      ),
      _FigmaButtonSpec(
        variant: Host4ButtonVariant.secondary,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.focused,
      ),
    ],
  ),
];

class _FigmaButtonColumnView extends StatelessWidget {
  const _FigmaButtonColumnView({required this.column});

  final _FigmaButtonColumn column;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return Column(
      children: [
        for (var index = 0; index < column.buttons.length; index++) ...[
          _FigmaButtonPreview(spec: column.buttons[index]),
          if (index != column.buttons.length - 1)
            SizedBox(height: theme.spacing.md),
        ],
      ],
    );
  }
}

class _FigmaButtonPreview extends StatelessWidget {
  const _FigmaButtonPreview({required this.spec});

  final _FigmaButtonSpec spec;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final buttonTokens = theme.components.button;
    final variantTokens = _variantTokens(buttonTokens, spec.variant);
    final stateTokens = _stateTokens(variantTokens, spec.state);
    final metrics = _metricsFor(spec);
    final ring = buttonTokens.focusedRing;
    final icon = spec.icon;

    Widget child;
    if (spec.content == Host4ButtonContent.iconOnly) {
      child = Icon(icon, size: metrics.iconSize, color: stateTokens.foreground);
    } else if (spec.content == Host4ButtonContent.iconLeft) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: metrics.iconSize, color: stateTokens.foreground),
            SizedBox(width: buttonTokens.spacing.iconGap),
          ],
          Text(
            'Button',
            style: buttonTokens.labelStyle.toTextStyle(stateTokens.foreground),
          ),
        ],
      );
    } else if (spec.content == Host4ButtonContent.iconRight) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Button',
            style: buttonTokens.labelStyle.toTextStyle(stateTokens.foreground),
          ),
          if (icon != null) ...[
            SizedBox(width: buttonTokens.spacing.iconGap),
            Icon(icon, size: metrics.iconSize, color: stateTokens.foreground),
          ],
        ],
      );
    } else {
      child = Text(
        'Button',
        style: buttonTokens.labelStyle.toTextStyle(stateTokens.foreground),
      );
    }

    return Padding(
      padding: EdgeInsets.all(
        spec.state == _ButtonPreviewState.focused ? theme.spacing.xs : 0,
      ),
      child: Container(
        width: metrics.width,
        height: metrics.height,
        decoration: BoxDecoration(
          color: stateTokens.background,
          borderRadius: BorderRadius.circular(variantTokens.radius),
          border: Border.all(color: stateTokens.border),
          boxShadow: spec.state == _ButtonPreviewState.focused
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
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

Host4ButtonVariantTokens _variantTokens(
  Host4ButtonComponentTokens buttonTokens,
  Host4ButtonVariant variant,
) {
  return switch (variant) {
    Host4ButtonVariant.ghost => buttonTokens.ghost,
    Host4ButtonVariant.primary => buttonTokens.primary,
    Host4ButtonVariant.secondary => buttonTokens.secondary,
    Host4ButtonVariant.popoverPrimary => buttonTokens.popoverPrimary,
    Host4ButtonVariant.popoverSecondary => buttonTokens.popoverSecondary,
    Host4ButtonVariant.tertiary => buttonTokens.tertiary,
    Host4ButtonVariant.outline => buttonTokens.outline,
    Host4ButtonVariant.danger => buttonTokens.danger,
    Host4ButtonVariant.dangerHigh => buttonTokens.dangerHigh,
    Host4ButtonVariant.dangerSoft => buttonTokens.dangerSoft,
  };
}

Host4ButtonStateTokens _stateTokens(
  Host4ButtonVariantTokens variantTokens,
  _ButtonPreviewState state,
) {
  return switch (state) {
    _ButtonPreviewState.defaultState => variantTokens.defaultState,
    _ButtonPreviewState.hover => variantTokens.hoverState,
    _ButtonPreviewState.pressed => variantTokens.pressedState,
    _ButtonPreviewState.focused => variantTokens.focusedState,
    _ButtonPreviewState.selected =>
      variantTokens.selectedState ?? variantTokens.defaultState,
  };
}

_FigmaButtonMetrics _metricsFor(_FigmaButtonSpec spec) {
  if (spec.variant == Host4ButtonVariant.ghost &&
      spec.size == Host4ButtonSize.sm &&
      spec.content == Host4ButtonContent.textOnly) {
    return const _FigmaButtonMetrics(width: 70, height: 26, iconSize: 16);
  }
  if (spec.variant == Host4ButtonVariant.ghost &&
      spec.size == Host4ButtonSize.md &&
      spec.content == Host4ButtonContent.textOnly) {
    return const _FigmaButtonMetrics(width: 70, height: 34, iconSize: 16);
  }
  if (spec.variant == Host4ButtonVariant.ghost &&
      spec.size == Host4ButtonSize.sm &&
      (spec.content == Host4ButtonContent.iconLeft ||
          spec.content == Host4ButtonContent.iconRight)) {
    return const _FigmaButtonMetrics(width: 94, height: 32, iconSize: 20);
  }
  if (spec.variant == Host4ButtonVariant.ghost &&
      spec.size == Host4ButtonSize.sm &&
      spec.content == Host4ButtonContent.iconOnly) {
    return const _FigmaButtonMetrics(width: 40, height: 32, iconSize: 20);
  }
  if (spec.variant == Host4ButtonVariant.ghost &&
      spec.size == Host4ButtonSize.xs &&
      spec.content == Host4ButtonContent.iconOnly) {
    return const _FigmaButtonMetrics(width: 24, height: 24, iconSize: 16);
  }
  if (spec.variant == Host4ButtonVariant.primary &&
      spec.size == Host4ButtonSize.sm) {
    return const _FigmaButtonMetrics(width: 94, height: 34, iconSize: 16);
  }
  if (spec.variant == Host4ButtonVariant.primary &&
      spec.size == Host4ButtonSize.xs) {
    return const _FigmaButtonMetrics(width: 62, height: 34, iconSize: 16);
  }
  if (spec.variant == Host4ButtonVariant.popoverPrimary) {
    return const _FigmaButtonMetrics(width: 78, height: 42, iconSize: 16);
  }
  if (spec.variant == Host4ButtonVariant.popoverSecondary) {
    return const _FigmaButtonMetrics(width: 78, height: 42, iconSize: 16);
  }
  if (spec.variant == Host4ButtonVariant.dangerSoft &&
      spec.content == Host4ButtonContent.iconLeft) {
    return const _FigmaButtonMetrics(width: 94, height: 40, iconSize: 20);
  }
  if (spec.variant == Host4ButtonVariant.dangerHigh) {
    return const _FigmaButtonMetrics(width: 94, height: 34, iconSize: 16);
  }
  if (spec.variant == Host4ButtonVariant.secondary &&
      spec.size == Host4ButtonSize.md &&
      spec.content == Host4ButtonContent.iconLeft) {
    return const _FigmaButtonMetrics(width: 94, height: 40, iconSize: 20);
  }
  if (spec.variant == Host4ButtonVariant.secondary &&
      spec.size == Host4ButtonSize.sm &&
      spec.content == Host4ButtonContent.textOnly) {
    return const _FigmaButtonMetrics(width: 62, height: 34, iconSize: 16);
  }

  return const _FigmaButtonMetrics(width: 94, height: 34, iconSize: 16);
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
