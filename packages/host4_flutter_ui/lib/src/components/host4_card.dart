import 'package:flutter/material.dart';

import '../foundation/theme/host4_theme_scope.dart';

class Host4Card extends StatelessWidget {
  const Host4Card({required this.child, super.key, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final tokens = theme.components.card;

    return Container(
      padding: padding ?? EdgeInsets.all(theme.spacing.card),
      decoration: BoxDecoration(
        color: tokens.background,
        borderRadius: BorderRadius.circular(theme.radius.card),
        border: Border.all(color: tokens.border),
        boxShadow: [
          BoxShadow(
            color: theme.colors.textPrimary.withValues(alpha: 0.06),
            blurRadius: theme.blur.card,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
