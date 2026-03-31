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
      padding: padding ?? EdgeInsets.all(tokens.padding),
      decoration: BoxDecoration(
        color: tokens.background,
        borderRadius: BorderRadius.circular(tokens.radius),
        border: Border.all(color: tokens.border),
        boxShadow: [
          BoxShadow(
            color: tokens.shadowColor.withValues(alpha: tokens.shadowOpacity),
            blurRadius: tokens.shadowBlur,
            offset: Offset(0, tokens.shadowOffsetY),
          ),
        ],
      ),
      child: child,
    );
  }
}
