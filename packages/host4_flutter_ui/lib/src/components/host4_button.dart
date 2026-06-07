import 'package:flutter/material.dart';

import '../foundation/host4_svg_icon.dart';
import '../foundation/theme/host4_runtime_theme.dart';
import '../foundation/theme/host4_theme_scope.dart';

enum Host4ButtonVariant {
  ghost,
  primary,
  secondary,
  popoverPrimary,
  popoverSecondary,
  dangerHigh,
  dangerSoft,
  tertiary,
}

enum Host4ButtonContent { textOnly, iconLeft, iconRight, iconOnly }

enum Host4ButtonSize { xs, sm, md }

class Host4Button extends StatefulWidget {
  const Host4Button({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = Host4ButtonVariant.primary,
    this.size = Host4ButtonSize.md,
    this.content = Host4ButtonContent.textOnly,
    this.icon,
    this.expanded = false,
    this.loading = false,
    this.selected = false,
  }) : assert(
         content == Host4ButtonContent.textOnly || icon != null,
         'icon must be provided when content is not textOnly',
       );

  final String label;
  final VoidCallback? onPressed;
  final Host4ButtonVariant variant;
  final Host4ButtonSize size;
  final Host4ButtonContent content;

  /// SVG asset path for the button icon (e.g. `Host4IconAssets.hamburger`).
  final String? icon;
  final bool expanded;
  final bool loading;
  final bool selected;

  @override
  State<Host4Button> createState() => _Host4ButtonState();
}

class _Host4ButtonState extends State<Host4Button> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final variantTokens = _variantTokens(theme, widget.variant);
    final enabled = widget.onPressed != null && !widget.loading;
    final buttonTokens = theme.components.button;
    final stateTokens = _stateTokens(
      variantTokens,
      enabled: enabled,
      loading: widget.loading,
      selected: widget.selected,
    );
    final sizeTokens = _sizeTokens(buttonTokens);
    final radius = BorderRadius.circular(variantTokens.radius);

    final padding = widget.content == Host4ButtonContent.iconOnly
        ? EdgeInsets.zero
        : EdgeInsets.symmetric(
            horizontal: _horizontalPadding(buttonTokens),
            vertical: _verticalPadding(buttonTokens),
          );

    final buttonSurface = AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: stateTokens.opacity,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: sizeTokens.minHeight,
          minWidth: widget.content == Host4ButtonContent.iconOnly
              ? sizeTokens.iconOnlyExtent
              : 0,
        ),
        child: Material(
          color: stateTokens.background,
          borderRadius: radius,
          child: InkWell(
            onTap: enabled ? widget.onPressed : null,
            onHover: enabled
                ? (value) => setState(() => _hovered = value)
                : null,
            onHighlightChanged: (value) => setState(() => _pressed = value),
            borderRadius: radius,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: radius,
                border: _buttonBorder(stateTokens),
              ),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 160),
                opacity: widget.loading ? buttonTokens.loading.opacity : 1,
                child: _buildContent(theme, stateTokens, buttonTokens),
              ),
            ),
          ),
        ),
      ),
    );

    final buttonChild = _focused && variantTokens.focusRingVisible
        ? _ButtonFocusRing(
            radius: variantTokens.radius,
            tokens: buttonTokens.focusedRing,
            child: buttonSurface,
          )
        : buttonSurface;

    final focusable = Focus(
      onFocusChange: (value) => setState(() => _focused = value),
      child: buttonChild,
    );

    if (!widget.expanded) return focusable;
    return SizedBox(width: double.infinity, child: focusable);
  }

  Widget _buildContent(
    Host4RuntimeTheme theme,
    Host4ButtonStateTokens stateTokens,
    Host4ButtonComponentTokens buttonTokens,
  ) {
    if (widget.loading) {
      final spinner = SizedBox(
        width: buttonTokens.loading.spinnerSize,
        height: buttonTokens.loading.spinnerSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(stateTokens.foreground),
        ),
      );

      if (widget.content == Host4ButtonContent.iconOnly) {
        return Center(child: spinner);
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          spinner,
          SizedBox(width: buttonTokens.loading.spinnerGap),
          _label(theme, stateTokens),
        ],
      );
    }

    final content = switch (widget.content) {
      Host4ButtonContent.textOnly => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
        children: [_label(theme, stateTokens)],
      ),

      Host4ButtonContent.iconLeft => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (widget.icon != null)
            Host4SvgIcon(
              assetPath: widget.icon!,
              size: buttonTokens.leadingIconSize,
              color: stateTokens.foreground,
            ),
          SizedBox(width: buttonTokens.spacing.iconGap),
          _label(theme, stateTokens),
        ],
      ),

      Host4ButtonContent.iconRight => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          _label(theme, stateTokens),
          SizedBox(width: buttonTokens.spacing.iconGap),
          if (widget.icon != null)
            Host4SvgIcon(
              assetPath: widget.icon!,
              size: buttonTokens.leadingIconSize,
              color: stateTokens.foreground,
            ),
        ],
      ),

      Host4ButtonContent.iconOnly => SizedBox.square(
        dimension: _sizeTokens(buttonTokens).iconOnlyExtent,
        child: Center(
          child: widget.icon != null
              ? Host4SvgIcon(
                  assetPath: widget.icon!,
                  size: buttonTokens.iconOnlySize,
                  color: stateTokens.foreground,
                )
              : const SizedBox.shrink(),
        ),
      ),
    };

    if (!_showsSelectedIndicator) return content;

    final indicator = buttonTokens.selectedIndicator;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        content,
        SizedBox(height: indicator.gap),
        Container(
          width: indicator.width,
          height: indicator.height,
          decoration: BoxDecoration(
            color: indicator.color,
            borderRadius: BorderRadius.circular(indicator.height / 2),
          ),
        ),
      ],
    );
  }

  bool get _showsSelectedIndicator =>
      widget.selected &&
      widget.variant == Host4ButtonVariant.ghost &&
      widget.content != Host4ButtonContent.iconOnly;

  Widget _label(Host4RuntimeTheme theme, Host4ButtonStateTokens stateTokens) {
    return Flexible(
      child: Text(
        widget.label,
        style: theme.components.button.labelStyle.toTextStyle(
          stateTokens.foreground,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  double _horizontalPadding(Host4ButtonComponentTokens buttonTokens) =>
      switch (widget.size) {
        Host4ButtonSize.xs => buttonTokens.spacing.xsHorizontal,
        Host4ButtonSize.sm => buttonTokens.spacing.smHorizontal,
        Host4ButtonSize.md => buttonTokens.spacing.mdHorizontal,
      };

  Border _buttonBorder(Host4ButtonStateTokens stateTokens) {
    if (stateTokens.bottomBorderWidth > 0) {
      return Border(
        bottom: BorderSide(
          color: stateTokens.border,
          width: stateTokens.bottomBorderWidth,
        ),
      );
    }
    return Border.all(color: stateTokens.border);
  }

  double _verticalPadding(Host4ButtonComponentTokens buttonTokens) =>
      switch (widget.size) {
        Host4ButtonSize.xs => buttonTokens.spacing.xsVertical,
        Host4ButtonSize.sm => buttonTokens.spacing.smVertical,
        Host4ButtonSize.md => buttonTokens.spacing.mdVertical,
      };

  Host4ButtonSizeTokens _sizeTokens(Host4ButtonComponentTokens buttonTokens) =>
      switch (widget.size) {
        Host4ButtonSize.xs => buttonTokens.sizes.xs,
        Host4ButtonSize.sm => buttonTokens.sizes.sm,
        Host4ButtonSize.md => buttonTokens.sizes.md,
      };

  Host4ButtonStateTokens _stateTokens(
    Host4ButtonVariantTokens tokens, {
    required bool enabled,
    required bool loading,
    required bool selected,
  }) {
    if (loading) return tokens.defaultState;
    if (!enabled) return tokens.disabledState;
    if (selected && tokens.selectedState != null) return tokens.selectedState!;
    if (_pressed) return tokens.pressedState;
    if (_focused) return tokens.focusedState;
    if (_hovered) return tokens.hoverState;
    return tokens.defaultState;
  }

  Host4ButtonVariantTokens _variantTokens(
    Host4RuntimeTheme theme,
    Host4ButtonVariant variant,
  ) {
    return switch (variant) {
      Host4ButtonVariant.ghost => theme.components.button.ghost,
      Host4ButtonVariant.primary => theme.components.button.primary,
      Host4ButtonVariant.secondary => theme.components.button.secondary,
      Host4ButtonVariant.popoverPrimary =>
        theme.components.button.popoverPrimary,
      Host4ButtonVariant.popoverSecondary =>
        theme.components.button.popoverSecondary,
      Host4ButtonVariant.dangerHigh => theme.components.button.dangerHigh,
      Host4ButtonVariant.dangerSoft => theme.components.button.dangerSoft,
      Host4ButtonVariant.tertiary => theme.components.button.tertiary,
    };
  }
}

class _ButtonFocusRing extends StatelessWidget {
  const _ButtonFocusRing({
    required this.radius,
    required this.tokens,
    required this.child,
  });

  final double radius;
  final Host4ButtonFocusedRingTokens tokens;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(tokens.offsetWidth),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          tokens.radius > 0
              ? tokens.radius
              : radius + tokens.offsetWidth + tokens.width,
        ),
        border: Border.all(color: tokens.color, width: tokens.width),
      ),
      child: child,
    );
  }
}
