import 'package:flutter/material.dart';

import '../foundation/theme/host4_theme_scope.dart';

class Host4EmptyState extends StatelessWidget {
  const Host4EmptyState({
    required this.title,
    super.key,
    this.icon,
    this.subtitle,
    this.action,
  });

  final IconData? icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final tokens = context.host4Theme.components.emptyState;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: tokens.iconSize, color: tokens.iconColor),
            SizedBox(height: tokens.iconGap),
          ],
          Text(
            title,
            style: tokens.titleStyle.toTextStyle(tokens.titleColor),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            SizedBox(height: tokens.textGap),
            Text(
              subtitle!,
              style: tokens.subtitleStyle.toTextStyle(tokens.subtitleColor),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[
            SizedBox(height: tokens.actionGap),
            action!,
          ],
        ],
      ),
    );
  }
}
