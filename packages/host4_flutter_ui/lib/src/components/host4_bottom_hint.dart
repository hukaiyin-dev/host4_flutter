import 'package:flutter/material.dart';

import '../foundation/theme/host4_theme_scope.dart';
import 'host4_card.dart';

class Host4BottomHint extends StatelessWidget {
  const Host4BottomHint({
    required this.label,
    super.key,
    this.leading,
  });

  final String label;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final navTokens = theme.components.navigationBar;
    final mediaQuery = MediaQuery.of(context);
    final compactHeight = mediaQuery.size.height - mediaQuery.padding.top < 360;
    final maxLines = compactHeight ? 2 : 1;

    return Host4Card(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.md,
        vertical: theme.spacing.sm,
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            SizedBox(width: theme.spacing.sm),
          ],
          Expanded(
            child: Text(
              label,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.label.toTextStyle(navTokens.subtitle),
            ),
          ),
        ],
      ),
    );
  }
}
