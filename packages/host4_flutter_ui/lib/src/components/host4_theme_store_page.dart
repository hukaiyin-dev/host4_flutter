import 'package:flutter/material.dart';

import '../foundation/theme/host4_theme_manager.dart';
import '../foundation/theme/host4_theme_scope.dart';

class Host4ThemeStorePage extends StatefulWidget {
  const Host4ThemeStorePage({
    super.key,
    this.manager,
    this.onBack,
    this.onSearch,
    this.title = '主题商店',
    this.confirmLabel = '确定',
    this.backLabel = '返回',
    this.timeLabel = '14:51',
    this.showControllerHints = true,
  });

  final Host4ThemeManager? manager;
  final VoidCallback? onBack;
  final VoidCallback? onSearch;
  final String title;
  final String confirmLabel;
  final String backLabel;
  final String timeLabel;
  final bool showControllerHints;

  @override
  State<Host4ThemeStorePage> createState() => _Host4ThemeStorePageState();
}

class _Host4ThemeStorePageState extends State<Host4ThemeStorePage> {
  String? _pendingThemeId;

  @override
  Widget build(BuildContext context) {
    final explicitManager = widget.manager;
    if (explicitManager != null) {
      return Host4ThemeScope(
        manager: explicitManager,
        child: _buildStore(explicitManager),
      );
    }

    return _buildStore(context.host4ThemeManager);
  }

  Widget _buildStore(Host4ThemeManager manager) {
    return AnimatedBuilder(
      animation: manager,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          resizeToAvoidBottomInset: false,
          body: MediaQuery.removePadding(
            context: context,
            removeLeft: true,
            removeTop: true,
            removeRight: true,
            removeBottom: true,
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.fill,
                child: SizedBox(
                  key: const ValueKey<String>('host4_theme_store_page'),
                  width: _ThemeStoreScene.designWidth,
                  height: _ThemeStoreScene.designHeight,
                  child: _ThemeStoreScene(
                    manager: manager,
                    pendingThemeId: _pendingThemeId,
                    title: widget.title,
                    confirmLabel: widget.confirmLabel,
                    backLabel: widget.backLabel,
                    timeLabel: widget.timeLabel,
                    showControllerHints: widget.showControllerHints,
                    onBack: widget.onBack ?? () => Navigator.maybePop(context),
                    onSearch: widget.onSearch,
                    onApplyTheme: _applyTheme,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _applyTheme(
    Host4ThemeManager manager,
    Host4ThemeCatalogEntry entry,
  ) async {
    if (_pendingThemeId != null || manager.currentThemeId == entry.id) {
      return;
    }

    setState(() {
      _pendingThemeId = entry.id;
    });

    try {
      await manager.applyTheme(
        entry.id,
        mode: manager.currentMode ?? manager.theme.meta.defaultMode,
      );
    } finally {
      if (mounted) {
        setState(() {
          _pendingThemeId = null;
        });
      }
    }
  }
}

class _ThemeStoreScene extends StatelessWidget {
  const _ThemeStoreScene({
    required this.manager,
    required this.pendingThemeId,
    required this.title,
    required this.confirmLabel,
    required this.backLabel,
    required this.timeLabel,
    required this.showControllerHints,
    required this.onBack,
    required this.onApplyTheme,
    this.onSearch,
  });

  static const designWidth = 844.0;
  static const designHeight = 390.0;

  final Host4ThemeManager manager;
  final String? pendingThemeId;
  final String title;
  final String confirmLabel;
  final String backLabel;
  final String timeLabel;
  final bool showControllerHints;
  final VoidCallback onBack;
  final VoidCallback? onSearch;
  final void Function(Host4ThemeManager, Host4ThemeCatalogEntry) onApplyTheme;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(color: Colors.white.withValues(alpha: 0.92)),
        ),
        _ThemeStoreHeader(
          title: title,
          timeLabel: timeLabel,
          onBack: onBack,
          onSearch: onSearch,
        ),
        Positioned(
          left: 66,
          top: 84,
          width: 532,
          child: _ThemeStoreGrid(
            manager: manager,
            pendingThemeId: pendingThemeId,
            onApplyTheme: onApplyTheme,
          ),
        ),
        if (showControllerHints)
          Positioned(
            right: 24,
            bottom: 14,
            child: _ThemeStoreControllerHints(
              confirmLabel: confirmLabel,
              backLabel: backLabel,
            ),
          ),
      ],
    );
  }
}

class _ThemeStoreHeader extends StatelessWidget {
  const _ThemeStoreHeader({
    required this.title,
    required this.timeLabel,
    required this.onBack,
    this.onSearch,
  });

  final String title;
  final String timeLabel;
  final VoidCallback onBack;
  final VoidCallback? onSearch;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return Positioned(
      left: 0,
      top: 0,
      width: _ThemeStoreScene.designWidth,
      height: 68,
      child: ColoredBox(
        color: Colors.white.withValues(alpha: 0.70),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: SizedBox(
            height: 48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _HeaderIconButton(
                  keyValue: 'host4_theme_store_back',
                  icon: Icons.chevron_left_rounded,
                  onTap: onBack,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  key: const ValueKey<String>('host4_theme_store_title'),
                  style: TextStyle(
                    color: theme.colors.textPrimary,
                    fontSize: 15.6,
                    height: 1.38,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const Spacer(),
                _HeaderIconButton(
                  keyValue: 'host4_theme_store_search',
                  icon: Icons.search_rounded,
                  onTap: onSearch,
                ),
                const SizedBox(width: 20),
                Text(
                  timeLabel,
                  key: const ValueKey<String>('host4_theme_store_time'),
                  style: TextStyle(
                    color: theme.colors.textPrimary,
                    fontSize: 13.6,
                    height: 1.29,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(width: 12),
                const _HeaderWifiIcon(),
                const SizedBox(width: 8),
                const _HeaderBatteryIcon(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.keyValue,
    required this.icon,
    required this.onTap,
  });

  final String keyValue;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return Semantics(
      button: true,
      child: InkResponse(
        key: ValueKey<String>(keyValue),
        onTap: onTap,
        radius: 22,
        child: Container(
          width: 40,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colors.surfaceMuted,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: theme.colors.borderDefault),
          ),
          child: Icon(icon, size: 24, color: theme.colors.textPrimary),
        ),
      ),
    );
  }
}

class _HeaderWifiIcon extends StatelessWidget {
  const _HeaderWifiIcon();

  @override
  Widget build(BuildContext context) {
    final color = context.host4Theme.colors.textPrimary;
    return SizedBox(
      key: const ValueKey<String>('host4_theme_store_wifi'),
      width: 24,
      height: 24,
      child: Icon(Icons.wifi_rounded, size: 18, color: color),
    );
  }
}

class _HeaderBatteryIcon extends StatelessWidget {
  const _HeaderBatteryIcon();

  @override
  Widget build(BuildContext context) {
    final color = context.host4Theme.colors.textPrimary;
    return SizedBox(
      key: const ValueKey<String>('host4_theme_store_battery'),
      width: 24,
      height: 24,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 10,
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                border: Border.all(color: color, width: 1.2),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 14,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
            Container(
              width: 2,
              height: 5,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeStoreGrid extends StatelessWidget {
  const _ThemeStoreGrid({
    required this.manager,
    required this.pendingThemeId,
    required this.onApplyTheme,
  });

  final Host4ThemeManager manager;
  final String? pendingThemeId;
  final void Function(Host4ThemeManager, Host4ThemeCatalogEntry) onApplyTheme;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in manager.catalog)
          _ThemeCard(
            entry: entry,
            selected: manager.currentThemeId == entry.id,
            loading: pendingThemeId == entry.id,
            onTap: () => onApplyTheme(manager, entry),
          ),
      ],
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.entry,
    required this.selected,
    required this.loading,
    required this.onTap,
  });

  final Host4ThemeCatalogEntry entry;
  final bool selected;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        key: ValueKey<String>('host4_theme_card_${entry.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 172,
          height: 124,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color:
                        Colors.white.withValues(alpha: selected ? 0.88 : 0.68),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? theme.colors.brandPrimary
                          : theme.colors.borderDefault,
                      width: selected ? 2 : 1,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 4,
                top: 4,
                width: 164,
                height: 89,
                child: _ThemePreview(entry: entry),
              ),
              Positioned(
                left: 11,
                top: 98,
                width: 96,
                height: 18,
                child: Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colors.textSecondary,
                    fontSize: 13.6,
                    height: 1.29,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
              Positioned(
                left: 116,
                top: 100,
                width: 48,
                height: 16,
                child: _ThemeActionPill(selected: selected, loading: loading),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.entry});

  final Host4ThemeCatalogEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = _parseHexColor(entry.previewColor) ?? Colors.black;
    final image = entry.previewAssetPath;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: DecoratedBox(
        decoration: BoxDecoration(color: color),
        child: image == null
            ? const SizedBox.expand()
            : Image.asset(
                image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return ColoredBox(color: color);
                },
              ),
      ),
    );
  }
}

class _ThemeActionPill extends StatelessWidget {
  const _ThemeActionPill({required this.selected, required this.loading});

  final bool selected;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final background =
        selected ? theme.colors.brandPrimary : theme.colors.textPrimary;

    return Container(
      key: ValueKey<String>(
        selected ? 'host4_theme_selected_pill' : 'host4_theme_switch_pill',
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: selected
            ? null
            : Border.all(color: theme.colors.surface, width: 0.8),
      ),
      child: loading
          ? SizedBox(
              width: 8,
              height: 8,
              child: CircularProgressIndicator(
                strokeWidth: 1.4,
                color: theme.colors.textInverse,
              ),
            )
          : Icon(
              selected ? Icons.check_rounded : Icons.swap_horiz_rounded,
              color: theme.colors.textInverse,
              size: selected ? 15 : 14,
            ),
    );
  }
}

class _ThemeStoreControllerHints extends StatelessWidget {
  const _ThemeStoreControllerHints({
    required this.confirmLabel,
    required this.backLabel,
  });

  final String confirmLabel;
  final String backLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('host4_theme_store_controller_hints'),
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0F172A),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ControllerHintButton(
            label: 'A',
            text: confirmLabel,
            color: const Color(0xFF32A565),
          ),
          const SizedBox(width: 26),
          _ControllerHintButton(
            label: 'B',
            text: backLabel,
            color: const Color(0xFFD8474F),
          ),
        ],
      ),
    );
  }
}

class _ControllerHintButton extends StatelessWidget {
  const _ControllerHintButton({
    required this.label,
    required this.text,
    required this.color,
  });

  final String label;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          text,
          style: TextStyle(
            color: theme.colors.textSecondary,
            fontSize: 13.6,
            height: 1.2,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

Color? _parseHexColor(String? value) {
  final raw = value?.replaceFirst('#', '');
  if (raw == null || (raw.length != 6 && raw.length != 8)) return null;
  final normalized = raw.length == 6 ? 'FF$raw' : raw;
  final parsed = int.tryParse(normalized, radix: 16);
  if (parsed == null) return null;
  return Color(parsed);
}
