import 'package:flutter/material.dart';

import '../foundation/theme/host4_theme_scope.dart';
import 'host4_text.dart';

class Host4ListCell extends StatelessWidget {
  const Host4ListCell({
    required this.title,
    required this.subtitle,
    super.key,
    this.leading,
    this.trailingText,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget? leading;
  final String? trailingText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final tokens = theme.components.listCell;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(theme.radius.card),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.card,
            vertical: theme.spacing.md,
          ),
          decoration: BoxDecoration(
            color: tokens.background,
            borderRadius: BorderRadius.circular(theme.radius.card),
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                SizedBox(width: theme.spacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Host4Text(title, role: Host4TextRole.label),
                    SizedBox(height: theme.spacing.xs),
                    Text(
                      subtitle,
                      style: theme.typography.caption.toTextStyle(
                        tokens.subtitle,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailingText != null) ...[
                SizedBox(width: theme.spacing.md),
                Text(
                  trailingText!,
                  style: theme.typography.caption.toTextStyle(tokens.trailing),
                ),
              ],
              SizedBox(width: theme.spacing.sm),
              Icon(Icons.chevron_right_rounded, color: tokens.trailing),
            ],
          ),
        ),
      ),
    );
  }
}
