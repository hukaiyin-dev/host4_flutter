import 'package:flutter/material.dart';

import '../foundation/host4_svg_icon.dart';
import '../foundation/theme/host4_theme_scope.dart';

class Host4InfoChip extends StatelessWidget {
  const Host4InfoChip({required this.label, super.key, this.icon});

  final String label;
  /// SVG asset path for the leading icon (e.g. `'assets/icons/info.svg'`).
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.host4Theme.components.infoChip;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.background,
        borderRadius: BorderRadius.circular(tokens.radius),
        border: Border.all(color: tokens.border),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.paddingHorizontal,
          vertical: tokens.paddingVertical,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Host4SvgIcon(assetPath: icon!, size: tokens.iconSize, color: tokens.iconColor),
              SizedBox(width: tokens.iconGap),
            ],
            Text(
              label,
              style: tokens.labelStyle.toTextStyle(tokens.foreground),
            ),
          ],
        ),
      ),
    );
  }
}
