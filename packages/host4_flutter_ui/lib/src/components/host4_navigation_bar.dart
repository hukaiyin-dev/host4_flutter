import 'package:flutter/material.dart';

import '../foundation/theme/host4_theme_scope.dart';
import 'host4_text.dart';

class Host4NavigationBar extends StatelessWidget {
  const Host4NavigationBar({
    required this.title,
    super.key,
    this.subtitle,
    this.leading,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final tokens = theme.components.navigationBar;

    return Container(
      padding: EdgeInsets.fromLTRB(
        theme.spacing.page,
        theme.spacing.lg,
        theme.spacing.page,
        theme.spacing.md,
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading!, SizedBox(width: theme.spacing.md)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle case String subtitleText)
                  Text(
                    subtitleText,
                    style: theme.typography.caption.toTextStyle(
                      tokens.subtitle,
                    ),
                  ),
                Host4Text(
                  title,
                  role: Host4TextRole.title,
                  style: theme.typography.title.toTextStyle(tokens.title),
                ),
              ],
            ),
          ),
          if (trailing case Widget trailingWidget) trailingWidget,
        ],
      ),
    );
  }
}
