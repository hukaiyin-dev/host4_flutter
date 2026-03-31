import 'package:flutter/material.dart';

import '../foundation/theme/host4_theme_scope.dart';

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
    final tokens = theme.components.sectionHeader;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: tokens.titleStyle.toTextStyle(tokens.titleColor),
              ),
              SizedBox(height: tokens.subtitleGap),
              Text(
                subtitle,
                style: tokens.subtitleStyle.toTextStyle(tokens.subtitleColor),
              ),
            ],
          ),
        ),
        if (action != null) ...[SizedBox(width: tokens.actionGap), action!],
      ],
    );
  }
}
