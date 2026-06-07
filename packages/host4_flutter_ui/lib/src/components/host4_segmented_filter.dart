import 'package:flutter/material.dart';

import '../foundation/host4_svg_icon.dart';
import '../foundation/theme/host4_runtime_theme.dart';
import '../foundation/theme/host4_theme_scope.dart';

class Host4SegmentedFilterItem {
  const Host4SegmentedFilterItem({required this.label, this.icon});

  final String label;
  /// SVG asset path for the leading icon (e.g. `'assets/icons/filter.svg'`).
  final String? icon;
}

class Host4SegmentedFilter extends StatelessWidget {
  const Host4SegmentedFilter({
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
    super.key,
  });

  final List<Host4SegmentedFilterItem> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  Host4SegmentedFilterItemStateTokens _stateFor(
    Host4SegmentedFilterComponentTokens tokens,
    int index,
  ) => index == selectedIndex ? tokens.selectedState : tokens.defaultState;

  @override
  Widget build(BuildContext context) {
    final tokens = context.host4Theme.components.segmentedFilter;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.containerBackground,
        borderRadius: BorderRadius.circular(tokens.containerRadius),
        border: Border.all(color: tokens.containerBorder),
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.gap),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) SizedBox(width: tokens.gap),
              _SegmentItem(
                item: items[i],
                tokens: tokens,
                stateTokens: _stateFor(tokens, i),
                onTap: () => onChanged(i),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SegmentItem extends StatelessWidget {
  const _SegmentItem({
    required this.item,
    required this.tokens,
    required this.stateTokens,
    required this.onTap,
  });

  final Host4SegmentedFilterItem item;
  final Host4SegmentedFilterComponentTokens tokens;
  final Host4SegmentedFilterItemStateTokens stateTokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: stateTokens.background,
          borderRadius: BorderRadius.circular(tokens.radius),
          border: Border.all(color: stateTokens.border),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.paddingHorizontal,
            vertical: tokens.paddingVertical,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.icon != null) ...[
                Host4SvgIcon(assetPath: item.icon!, size: tokens.iconSize, color: stateTokens.foreground),
                SizedBox(width: tokens.iconGap),
              ],
              Text(
                item.label,
                style: tokens.labelStyle.toTextStyle(stateTokens.foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
