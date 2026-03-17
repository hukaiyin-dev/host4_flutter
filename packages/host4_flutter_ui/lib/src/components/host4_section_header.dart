import 'package:flutter/material.dart';

import '../foundation/theme/host4_theme_scope.dart';
import 'host4_text.dart';

class Host4SectionHeader extends StatelessWidget {
  const Host4SectionHeader({
    required this.title,
    required this.subtitle,
    super.key,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Host4Text(title, role: Host4TextRole.heading),
              SizedBox(height: theme.spacing.xs),
              Text(
                subtitle,
                style: theme.typography.body.toTextStyle(
                  theme.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (action != null) ...[SizedBox(width: theme.spacing.md), action!],
      ],
    );
  }
}
