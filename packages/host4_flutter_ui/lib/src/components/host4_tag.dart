import 'package:flutter/material.dart';

import '../foundation/theme/host4_theme_scope.dart';
import '../foundation/theme/host4_runtime_theme.dart';

enum Host4TagVariant { normal, selected, disabled }

class Host4Tag extends StatelessWidget {
  const Host4Tag({
    required this.label,
    super.key,
    this.icon,
    this.variant = Host4TagVariant.normal,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final Host4TagVariant variant;
  final VoidCallback? onTap;

  Host4TagStateTokens _stateTokens(Host4TagComponentTokens tokens) =>
      switch (variant) {
        Host4TagVariant.selected => tokens.selectedState,
        Host4TagVariant.disabled => tokens.disabledState,
        _ => tokens.defaultState,
      };

  @override
  Widget build(BuildContext context) {
    final tokens = context.host4Theme.components.tag;
    final state = _stateTokens(tokens);

    final chip = DecoratedBox(
      decoration: BoxDecoration(
        color: state.background,
        borderRadius: BorderRadius.circular(tokens.radius),
        border: Border.all(color: state.border),
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
              Icon(icon, size: tokens.iconSize, color: state.icon),
              SizedBox(width: tokens.iconGap),
            ],
            Text(
              label,
              style: tokens.labelStyle.toTextStyle(state.foreground),
            ),
          ],
        ),
      ),
    );

    if (onTap == null || variant == Host4TagVariant.disabled) return chip;
    return GestureDetector(onTap: onTap, child: chip);
  }
}
