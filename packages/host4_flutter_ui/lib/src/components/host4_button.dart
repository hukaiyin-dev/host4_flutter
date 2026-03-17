import 'package:flutter/material.dart';

import '../foundation/theme/host4_runtime_theme.dart';
import '../foundation/theme/host4_theme_scope.dart';
import 'host4_text.dart';

enum Host4ButtonVariant { primary, secondary, ghost }

class Host4Button extends StatelessWidget {
  const Host4Button({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = Host4ButtonVariant.primary,
    this.icon,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Host4ButtonVariant variant;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final tokens = _variantTokens(theme, variant);
    final enabled = onPressed != null;

    final button = Material(
      color: enabled
          ? tokens.background
          : tokens.background.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(theme.radius.button),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(theme.radius.button),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.buttonHorizontal,
            vertical: theme.spacing.buttonVertical,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(theme.radius.button),
            border: Border.all(
              color: enabled
                  ? tokens.border
                  : tokens.border.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: tokens.foreground),
                SizedBox(width: theme.spacing.sm),
              ],
              Flexible(
                child: Host4Text(
                  label,
                  role: Host4TextRole.label,
                  style: theme.typography.label.toTextStyle(tokens.foreground),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!expanded) {
      return button;
    }
    return SizedBox(width: double.infinity, child: button);
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
