import 'package:flutter/material.dart';

import '../foundation/theme/host4_runtime_theme.dart';
import '../foundation/theme/host4_theme_scope.dart';

enum Host4ButtonVariant { primary, secondary, ghost }

enum Host4ButtonContent { textOnly, iconLeft, iconTop, iconOnly }

class Host4Button extends StatefulWidget {
  const Host4Button({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = Host4ButtonVariant.primary,
    this.content = Host4ButtonContent.textOnly,
    this.icon,
    this.expanded = false,
  }) : assert(
         content == Host4ButtonContent.textOnly || icon != null,
         'icon must be provided when content is not textOnly',
       );

  final String label;
  final VoidCallback? onPressed;
  final Host4ButtonVariant variant;
  final Host4ButtonContent content;
  final IconData? icon;
  final bool expanded;

  @override
  State<Host4Button> createState() => _Host4ButtonState();
}

class _Host4ButtonState extends State<Host4Button> {
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final variantTokens = _variantTokens(theme, widget.variant);
    final enabled = widget.onPressed != null;
    final buttonTokens = theme.components.button;
    final stateTokens = _stateTokens(variantTokens, enabled: enabled);
    final radius = BorderRadius.circular(variantTokens.radius);

    final padding = widget.content == Host4ButtonContent.iconOnly
        ? EdgeInsets.symmetric(
            horizontal: buttonTokens.spacing.iconOnlyHorizontal,
            vertical: buttonTokens.spacing.iconOnlyVertical,
          )
        : EdgeInsets.symmetric(
            horizontal: buttonTokens.spacing.horizontal,
            vertical: buttonTokens.spacing.vertical,
          );

    final buttonChild = ConstrainedBox(
      constraints: BoxConstraints(minHeight: buttonTokens.minHeight),
      child: Material(
        color: stateTokens.background,
        borderRadius: radius,
        child: InkWell(
          onTap: enabled ? widget.onPressed : null,
          onHighlightChanged: (value) => setState(() => _pressed = value),
          borderRadius: radius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: stateTokens.border),
            ),
            child: _buildContent(theme, stateTokens),
          ),
        ),
      ),
    );

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
  ) {
    final buttonTokens = theme.components.button;

    switch (widget.content) {
      case Host4ButtonContent.textOnly:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
          children: [_label(theme, stateTokens)],
        );

      case Host4ButtonContent.iconLeft:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              size: buttonTokens.leadingIconSize,
              color: stateTokens.foreground,
            ),
            SizedBox(width: buttonTokens.spacing.iconGap),
            _label(theme, stateTokens),
          ],
        );

      case Host4ButtonContent.iconTop:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              size: buttonTokens.topIconSize,
              color: stateTokens.foreground,
            ),
            SizedBox(height: buttonTokens.spacing.stackGap),
            _label(theme, stateTokens),
          ],
        );

      case Host4ButtonContent.iconOnly:
        return Icon(
          widget.icon,
          size: buttonTokens.iconOnlySize,
          color: stateTokens.foreground,
        );
    }
  }

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

  Host4ButtonStateTokens _stateTokens(
    Host4ButtonVariantTokens tokens, {
    required bool enabled,
  }) {
    if (!enabled) return tokens.disabledState;
    if (_pressed) return tokens.pressedState;
    if (_focused) return tokens.focusedState;
    return tokens.defaultState;
  }

  Host4ButtonVariantTokens _variantTokens(
    Host4RuntimeTheme theme,
    Host4ButtonVariant variant,
  ) {
    return switch (variant) {
      Host4ButtonVariant.primary => theme.components.button.primary,
      Host4ButtonVariant.secondary => theme.components.button.secondary,
      Host4ButtonVariant.ghost => theme.components.button.ghost,
    };
  }
}
