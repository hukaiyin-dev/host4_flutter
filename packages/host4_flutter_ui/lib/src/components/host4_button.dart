import 'package:flutter/material.dart';

import '../foundation/theme/host4_runtime_theme.dart';
import '../foundation/theme/host4_theme_scope.dart';
import 'host4_text.dart';

enum Host4ButtonVariant { primary, secondary, ghost }

enum Host4ButtonContent { textOnly, iconLeft, iconTop, iconOnly }

class Host4Button extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final tokens = _variantTokens(theme, variant);
    final enabled = onPressed != null;
    final buttonTokens = theme.components.button;
    final radius = BorderRadius.circular(tokens.radius);

    final padding = content == Host4ButtonContent.iconOnly
        ? EdgeInsets.symmetric(
            horizontal: buttonTokens.spacing.iconHorizontal,
            vertical: buttonTokens.spacing.iconVertical,
          )
        : EdgeInsets.symmetric(
            horizontal: buttonTokens.spacing.horizontal,
            vertical: buttonTokens.spacing.vertical,
          );

    final button = Material(
      color: enabled
          ? tokens.background
          : tokens.background.withValues(alpha: 0.4),
      borderRadius: radius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: radius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: enabled
                  ? tokens.border
                  : tokens.border.withValues(alpha: 0.4),
            ),
          ),
          child: _buildContent(theme, tokens),
        ),
      ),
    );

    if (!expanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }

  Widget _buildContent(Host4RuntimeTheme theme, Host4ButtonVariantTokens tokens) {
    switch (content) {
      case Host4ButtonContent.textOnly:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
          children: [_label(theme, tokens)],
        );

      case Host4ButtonContent.iconLeft:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Icon(icon, size: theme.sizes.iconMd, color: tokens.foreground),
            SizedBox(width: theme.spacing.sm),
            _label(theme, tokens),
          ],
        );

      case Host4ButtonContent.iconTop:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: theme.sizes.iconLg, color: tokens.foreground),
            SizedBox(height: theme.spacing.xs),
            _label(theme, tokens),
          ],
        );

      case Host4ButtonContent.iconOnly:
        return Icon(icon, size: theme.sizes.iconLg, color: tokens.foreground);
    }
  }

  Widget _label(Host4RuntimeTheme theme, Host4ButtonVariantTokens tokens) {
    return Flexible(
      child: Host4Text(
        label,
        role: Host4TextRole.label,
        style: theme.typography.label.toTextStyle(tokens.foreground),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
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
