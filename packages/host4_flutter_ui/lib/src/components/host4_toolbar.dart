import 'package:flutter/material.dart';

import '../foundation/theme/host4_theme_scope.dart';

class Host4Toolbar extends StatelessWidget {
  const Host4Toolbar({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = context.host4Theme.components.toolbar;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.background,
        border: Border(
          bottom: BorderSide(color: tokens.borderBottom),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.paddingHorizontal,
          vertical: tokens.paddingVertical,
        ),
        child: Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(width: tokens.gap),
              if (i == 0) Expanded(child: children[i]) else children[i],
            ],
          ],
        ),
      ),
    );
  }
}
