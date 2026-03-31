import 'package:flutter/material.dart';

import '../foundation/theme/host4_theme_scope.dart';

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
        tokens.paddingHorizontal,
        tokens.paddingTop,
        tokens.paddingHorizontal,
        tokens.paddingBottom,
      ),
      color: tokens.background,
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            SizedBox(width: tokens.leadingGap),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle case String subtitleText)
                  Text(
                    subtitleText,
                    style: tokens.subtitleStyle.toTextStyle(tokens.subtitle),
                  ),
                Text(title, style: tokens.titleStyle.toTextStyle(tokens.title)),
              ],
            ),
          ),
          if (trailing case Widget trailingWidget) trailingWidget,
        ],
      ),
    );
  }
}
