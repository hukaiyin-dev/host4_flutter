import 'package:flutter/material.dart';

import '../foundation/theme/host4_runtime_theme.dart';
import '../foundation/theme/host4_theme_scope.dart';

/// A single tab item descriptor.
///
/// [index] maps to the token's tab image slots (tab0, tab1, …).
/// [featured] items use [Host4TabBarComponentTokens.featuredIconSize] and may
/// visually overflow above the tab bar background.
/// [fallbackIcon] / [fallbackSelectedIcon] are used when the image asset
/// for this slot is missing or fails to load.
@immutable
class Host4TabItem {
  const Host4TabItem({
    required this.index,
    required this.label,
    this.featured = false,
    this.fallbackIcon,
    this.fallbackSelectedIcon,
  });

  final int index;
  final String label;
  final bool featured;
  final IconData? fallbackIcon;
  final IconData? fallbackSelectedIcon;
}

/// A bottom tab bar whose visual style is entirely driven by
/// [Host4TabBarComponentTokens] and [Host4ThemeImages.tabItems].
///
/// Place this as [Scaffold.bottomNavigationBar].
class Host4TabBar extends StatelessWidget {
  const Host4TabBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
  }) : assert(items.length > 0, 'Host4TabBar: items must not be empty.');

  final List<Host4TabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final tokens = theme.components.tabBar;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    assert(
      items.every((item) => item.index < theme.images.tabItems.length),
      'Host4TabBar: an item index exceeds the number of tab icon sets '
      'provided by the token (${theme.images.tabItems.length}).',
    );

    // Content height = tallest possible icon + optional label + bottom gap.
    // This may exceed tokens.height for featured items, causing the intended
    // visual overflow above the background surface.
    final hasFeatures = items.any((item) => item.featured);
    final maxIconSize =
        hasFeatures ? tokens.featuredIconSize : tokens.iconSize;
    final labelHeight =
        tokens.showLabels ? theme.typography.caption.lineHeight + 4.0 : 0.0;
    final contentHeight = maxIconSize + labelHeight + 4.0; // 4 = bottom gap

    // Total widget height: at least tokens.height so the background fills
    // properly even when content is shorter than the declared bar height.
    final totalHeight =
        contentHeight.clamp(tokens.height, double.infinity) + safeBottom;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none, // allows featured icons to overflow upward
        children: [
          // ── Background surface ──────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: tokens.height + safeBottom,
              color: tokens.background,
            ),
          ),

          // ── Tab items ───────────────────────────────────────────────────
          Positioned(
            bottom: safeBottom,
            left: 0,
            right: 0,
            child: SizedBox(
              height: contentHeight,
              child: Row(
                children: items
                    .map((item) => _buildItem(theme, tokens, item))
                    .toList(growable: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    Host4RuntimeTheme theme,
    Host4TabBarComponentTokens tokens,
    Host4TabItem item,
  ) {
    final selected = item.index == currentIndex;
    final iconSize = item.featured ? tokens.featuredIconSize : tokens.iconSize;
    final images = item.index < theme.images.tabItems.length
        ? theme.images.tabItems[item.index]
        : null;
    final imagePath =
        images != null ? (selected ? images.selected : images.normal) : null;
    final lightFallbackPath = images != null
        ? (selected ? images.lightFallbackSelected : images.lightFallbackNormal)
        : null;
    final fallback =
        selected ? (item.fallbackSelectedIcon ?? item.fallbackIcon) : item.fallbackIcon;
    final color =
        selected ? tokens.selectedLabelColor : tokens.labelColor;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(item.index),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: iconSize,
              height: iconSize,
              child: _buildIcon(imagePath, lightFallbackPath, fallback, iconSize, color),
            ),
            if (tokens.showLabels) ...[
              const SizedBox(height: 4),
              Text(
                item.label,
                style: theme.typography.caption.toTextStyle(color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(
    String? imagePath,
    String? lightFallbackPath,
    IconData? fallback,
    double size,
    Color color,
  ) {
    if (imagePath != null) {
      return Image.asset(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) {
          // Dark image missing — try the light-mode image before the icon fallback.
          if (lightFallbackPath != null) {
            return Image.asset(
              lightFallbackPath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _iconWidget(fallback, size, color),
            );
          }
          return _iconWidget(fallback, size, color);
        },
      );
    }
    return _iconWidget(fallback, size, color);
  }

  Widget _iconWidget(IconData? icon, double size, Color color) {
    if (icon != null) {
      return Icon(icon, size: size * 0.85, color: color);
    }
    return SizedBox(width: size, height: size);
  }
}
