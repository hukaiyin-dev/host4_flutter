import 'package:flutter/material.dart';

import '../foundation/host4_svg_icon.dart';
import '../foundation/theme/host4_runtime_theme.dart';
import '../foundation/theme/host4_theme_scope.dart';

/// A single tab item descriptor.
///
/// [index] maps to the token's component tab image slots (home, list, settings, …).
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
    this.enabled = true,
    this.fallbackIcon,
    this.fallbackSelectedIcon,
  });

  final int index;
  final String label;
  final bool featured;
  final bool enabled;
  /// SVG asset path used as fallback when the theme image for this tab is missing.
  final String? fallbackIcon;
  /// SVG asset path used as selected-state fallback when the theme image is missing.
  final String? fallbackSelectedIcon;
}

/// A bottom tab bar whose visual style is entirely driven by
/// [Host4TabBarComponentTokens].
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

    // Content height = tallest possible icon + optional label + bottom gap.
    // This may exceed tokens.height for featured items, causing the intended
    // visual overflow above the background surface.
    final hasFeatures = items.any((item) => item.featured);
    final maxIconSize = hasFeatures ? tokens.featuredIconSize : tokens.iconSize;
    final showLabels = items.any((item) => item.label.isNotEmpty);
    final labelHeight =
        showLabels ? tokens.labelStyle.lineHeight + tokens.labelGap : 0.0;
    final contentHeight = maxIconSize + labelHeight + tokens.bottomGap;

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
                    .map((item) => _buildItem(tokens, item, showLabels))
                    .toList(growable: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    Host4TabBarComponentTokens tokens,
    Host4TabItem item,
    bool showLabels,
  ) {
    return Expanded(
      child: _Host4TabBarItemView(
        tokens: tokens,
        item: item,
        selected: item.index == currentIndex,
        showLabels: showLabels,
        onTap: item.enabled ? () => onTap(item.index) : null,
        buildIcon: _buildIcon,
      ),
    );
  }

  Widget _buildIcon(
    String? imagePath,
    String? lightFallbackPath,
    String? fallbackSvgPath,
    double size,
    Color color,
  ) {
    if (imagePath != null) {
      return Image.asset(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder: (_, error, stackTrace) {
          // Dark image missing — try the light-mode image before the SVG fallback.
          if (lightFallbackPath != null) {
            return Image.asset(
              lightFallbackPath,
              fit: BoxFit.contain,
              errorBuilder: (_, error, stackTrace) =>
                  _iconWidget(fallbackSvgPath, size, color),
            );
          }
          return _iconWidget(fallbackSvgPath, size, color);
        },
      );
    }
    return _iconWidget(fallbackSvgPath, size, color);
  }

  Widget _iconWidget(String? svgPath, double size, Color color) {
    if (svgPath != null) {
      return Host4SvgIcon(assetPath: svgPath, size: size * 0.85, color: color);
    }
    return SizedBox(width: size, height: size);
  }
}

class _Host4TabBarItemView extends StatefulWidget {
  const _Host4TabBarItemView({
    required this.tokens,
    required this.item,
    required this.selected,
    required this.showLabels,
    required this.onTap,
    required this.buildIcon,
  });

  final Host4TabBarComponentTokens tokens;
  final Host4TabItem item;
  final bool selected;
  final bool showLabels;
  final VoidCallback? onTap;
  final Widget Function(String?, String?, String?, double, Color) buildIcon;

  @override
  State<_Host4TabBarItemView> createState() => _Host4TabBarItemViewState();
}

class _Host4TabBarItemViewState extends State<_Host4TabBarItemView> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final item = widget.item;
    final iconSize = item.featured ? tokens.featuredIconSize : tokens.iconSize;
    final images =
        item.index < tokens.items.length ? tokens.items[item.index] : null;
    final imagePath = images != null
        ? (widget.selected ? images.selected : images.normal)
        : null;
    final lightFallbackPath = images != null
        ? (widget.selected
            ? images.lightFallbackSelected
            : images.lightFallbackNormal)
        : null;
    final fallback = widget.selected
        ? (item.fallbackSelectedIcon ?? item.fallbackIcon)
        : item.fallbackIcon;
    final state = _stateTokens(tokens, item);

    return InkWell(
      onTap: widget.onTap,
      onHighlightChanged: (value) => setState(() => _pressed = value),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: widget.buildIcon(
              imagePath,
              lightFallbackPath,
              fallback,
              iconSize,
              state.iconColor,
            ),
          ),
          if (widget.showLabels) ...[
            SizedBox(height: tokens.labelGap),
            Text(
              item.label,
              style: tokens.labelStyle.toTextStyle(state.labelColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          SizedBox(height: tokens.bottomGap),
        ],
      ),
    );
  }

  Host4TabBarItemStateTokens _stateTokens(
    Host4TabBarComponentTokens tokens,
    Host4TabItem item,
  ) {
    if (!item.enabled) return tokens.itemStates.disabledState;
    if (_pressed) return tokens.itemStates.pressedState;
    if (widget.selected) return tokens.itemStates.selectedState;
    return tokens.itemStates.defaultState;
  }
}
