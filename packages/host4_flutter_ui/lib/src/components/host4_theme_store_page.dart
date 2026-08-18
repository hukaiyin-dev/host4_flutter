import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/theme/host4_theme_manager.dart';
import '../foundation/theme/host4_theme_scope.dart';
import 'host4_system_status.dart';
import 'host4_top_bar.dart';

class Host4ThemeStorePage extends StatefulWidget {
  const Host4ThemeStorePage({
    super.key,
    this.manager,
    this.onConfirm,
    this.onBack,
    this.onSearch,
    this.title = '主题商店',
    this.confirmLabel = '确定',
    this.backLabel = '返回',
    this.statusSource,
    this.showSearchButton = true,
    this.showControllerHints = true,
    this.themeNameBuilder,
  });

  final Host4ThemeManager? manager;
  final VoidCallback? onConfirm;
  final VoidCallback? onBack;
  final VoidCallback? onSearch;
  final String title;
  final String confirmLabel;
  final String backLabel;

  /// 系统状态数据源；传入则在右上角显示时间 / Wi-Fi / 电量。
  final Host4SystemStatusSource? statusSource;

  /// 是否显示右上角搜索按钮。
  final bool showSearchButton;
  final bool showControllerHints;
  final String Function(Host4ThemeCatalogEntry entry)? themeNameBuilder;

  @override
  State<Host4ThemeStorePage> createState() => Host4ThemeStorePageState();
}

class Host4ThemeStorePageState extends State<Host4ThemeStorePage> {
  String? _pendingThemeId;
  Host4ThemeManager? _listenedManager;
  final Map<String, FocusNode> _cardFocusNodes = <String, FocusNode>{};
  bool _focusRequestScheduled = false;

  @override
  void initState() {
    super.initState();
    final manager = widget.manager;
    if (manager != null) {
      _attachManager(manager);
      _syncCardFocusNodes(manager);
      _scheduleSelectedThemeFocus(manager);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.manager == null) {
      _attachManager(context.host4ThemeManager);
      _syncCardFocusNodes(context.host4ThemeManager);
      _scheduleSelectedThemeFocus(context.host4ThemeManager);
    }
  }

  @override
  void dispose() {
    _listenedManager?.removeListener(_onManagerChanged);
    _listenedManager = null;
    for (final node in _cardFocusNodes.values) {
      node.dispose();
    }
    _cardFocusNodes.clear();
    super.dispose();
  }

  void requestInputFocus() {
    if (!mounted) {
      return;
    }
    _requestSelectedThemeFocus(_manager);
  }

  Host4ThemeManager get _manager {
    final explicitManager = widget.manager;
    if (explicitManager != null) {
      return explicitManager;
    }
    return context.host4ThemeManager;
  }

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
        _syncCardFocusNodes(manager);
        _scheduleFocusIfNeeded(manager);
        return Semantics(
          identifier: 'theme_store.surface',
          explicitChildNodes: true,
          child: FocusTraversalGroup(
            policy: ReadingOrderTraversalPolicy(),
            child: Builder(
              builder: (groupContext) {
                return Shortcuts(
                  shortcuts: const <ShortcutActivator, Intent>{
                    SingleActivator(LogicalKeyboardKey.arrowLeft):
                        DirectionalFocusIntent(TraversalDirection.left),
                    SingleActivator(LogicalKeyboardKey.arrowRight):
                        DirectionalFocusIntent(TraversalDirection.right),
                    SingleActivator(LogicalKeyboardKey.arrowUp):
                        DirectionalFocusIntent(TraversalDirection.up),
                    SingleActivator(LogicalKeyboardKey.arrowDown):
                        DirectionalFocusIntent(TraversalDirection.down),
                  },
                  child: Actions(
                    actions: <Type, Action<Intent>>{
                      DirectionalFocusIntent:
                          CallbackAction<DirectionalFocusIntent>(
                            onInvoke: (intent) {
                              _moveFocus(intent.direction);
                              return null;
                            },
                          ),
                    },
                    child: Focus(
                      onKeyEvent: _handleRepeatAndBackKeyEvent,
                      child: Scaffold(
                        backgroundColor: Colors.white,
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
                                key: const ValueKey<String>(
                                  'host4_theme_store_page',
                                ),
                                width: _ThemeStoreScene.designWidth,
                                height: _ThemeStoreScene.designHeight,
                                child: _ThemeStoreScene(
                                  manager: manager,
                                  pendingThemeId: _pendingThemeId,
                                  cardFocusNodes: _cardFocusNodes,
                                  title: widget.title,
                                  confirmLabel: widget.confirmLabel,
                                  backLabel: widget.backLabel,
                                  statusSource: widget.statusSource,
                                  showSearchButton: widget.showSearchButton,
                                  showControllerHints:
                                      widget.showControllerHints,
                                  themeNameBuilder: widget.themeNameBuilder,
                                  onConfirm:
                                      widget.onConfirm ??
                                      () => Navigator.maybePop(context),
                                  onBack:
                                      widget.onBack ??
                                      () => Navigator.maybePop(context),
                                  onSearch: widget.onSearch,
                                  onApplyTheme: _applyTheme,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  KeyEventResult _handleRepeatAndBackKeyEvent(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    final direction = _directionForKey(key);
    if ((event is KeyDownEvent || event is KeyRepeatEvent) &&
        direction != null) {
      _moveFocus(direction);
      return KeyEventResult.handled;
    }
    if (event is KeyRepeatEvent && _isActivateKey(key)) {
      return KeyEventResult.handled;
    }
    if (event is KeyDownEvent &&
        (key == LogicalKeyboardKey.keyB ||
            key == LogicalKeyboardKey.escape ||
            key == LogicalKeyboardKey.goBack ||
            key == LogicalKeyboardKey.gameButtonB)) {
      (widget.onBack ?? () => Navigator.maybePop(context))();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _moveFocus(TraversalDirection direction) {
    final focusedNode = FocusManager.instance.primaryFocus;
    if (focusedNode == null || !_cardFocusNodes.containsValue(focusedNode)) {
      _requestSelectedThemeFocus(_manager);
      return;
    }
    final catalog = _manager.catalog;
    final currentIndex = catalog.indexWhere(
      (entry) => identical(_cardFocusNodes[entry.id], focusedNode),
    );
    if (currentIndex < 0) {
      _requestSelectedThemeFocus(_manager);
      return;
    }
    final nextIndex = switch (direction) {
      TraversalDirection.left || TraversalDirection.up => currentIndex - 1,
      TraversalDirection.right || TraversalDirection.down => currentIndex + 1,
    };
    if (nextIndex < 0 || nextIndex >= catalog.length) {
      return;
    }
    _cardFocusNodes[catalog[nextIndex].id]?.requestFocus();
  }

  void _attachManager(Host4ThemeManager manager) {
    if (identical(_listenedManager, manager)) {
      return;
    }
    _listenedManager?.removeListener(_onManagerChanged);
    _listenedManager = manager;
    manager.addListener(_onManagerChanged);
  }

  void _onManagerChanged() {
    if (!mounted || _listenedManager == null) {
      return;
    }
    _syncCardFocusNodes(_listenedManager!);
    _scheduleFocusIfNeeded(_listenedManager!);
    setState(() {});
  }

  void _syncCardFocusNodes(Host4ThemeManager manager) {
    final ids = manager.catalog.map((entry) => entry.id).toSet();
    final removed = _cardFocusNodes.keys
        .where((id) => !ids.contains(id))
        .toList(growable: false);
    for (final id in removed) {
      _cardFocusNodes.remove(id)?.dispose();
    }
    for (final id in ids) {
      _cardFocusNodes.putIfAbsent(
        id,
        () => FocusNode(debugLabel: 'host4_theme_card_$id'),
      );
    }
  }

  void _scheduleFocusIfNeeded(Host4ThemeManager manager) {
    final focusedNode = FocusManager.instance.primaryFocus;
    if (_cardFocusNodes.containsValue(focusedNode)) {
      return;
    }
    _scheduleSelectedThemeFocus(manager);
  }

  void _scheduleSelectedThemeFocus(Host4ThemeManager manager) {
    if (_focusRequestScheduled) {
      return;
    }
    _focusRequestScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusRequestScheduled = false;
      if (!mounted) {
        return;
      }
      _requestSelectedThemeFocus(manager);
    });
  }

  void _requestSelectedThemeFocus(Host4ThemeManager manager) {
    final catalog = manager.catalog;
    if (catalog.isEmpty) {
      return;
    }
    if (_cardFocusNodes.containsValue(FocusManager.instance.primaryFocus)) {
      return;
    }
    final selectedId = manager.currentThemeId;
    final fallbackId = catalog.first.id;
    final node = _cardFocusNodes[selectedId] ?? _cardFocusNodes[fallbackId];
    node?.requestFocus();
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

bool _isActivateKey(LogicalKeyboardKey key) {
  return key == LogicalKeyboardKey.keyA ||
      key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.numpadEnter ||
      key == LogicalKeyboardKey.select ||
      key == LogicalKeyboardKey.gameButtonA;
}

TraversalDirection? _directionForKey(LogicalKeyboardKey key) {
  return switch (key) {
    LogicalKeyboardKey.arrowLeft => TraversalDirection.left,
    LogicalKeyboardKey.arrowRight => TraversalDirection.right,
    LogicalKeyboardKey.arrowUp => TraversalDirection.up,
    LogicalKeyboardKey.arrowDown => TraversalDirection.down,
    _ => null,
  };
}

class _ThemeStoreScene extends StatelessWidget {
  const _ThemeStoreScene({
    required this.manager,
    required this.pendingThemeId,
    required this.cardFocusNodes,
    required this.title,
    required this.confirmLabel,
    required this.backLabel,
    required this.showSearchButton,
    required this.showControllerHints,
    required this.onConfirm,
    required this.onBack,
    required this.onApplyTheme,
    this.themeNameBuilder,
    this.statusSource,
    this.onSearch,
  });

  static const designWidth = 844.0;
  static const designHeight = 390.0;

  final Host4ThemeManager manager;
  final String? pendingThemeId;
  final Map<String, FocusNode> cardFocusNodes;
  final String title;
  final String confirmLabel;
  final String backLabel;
  final Host4SystemStatusSource? statusSource;
  final bool showSearchButton;
  final bool showControllerHints;
  final VoidCallback onConfirm;
  final VoidCallback onBack;
  final VoidCallback? onSearch;
  final void Function(Host4ThemeManager, Host4ThemeCatalogEntry) onApplyTheme;
  final String Function(Host4ThemeCatalogEntry entry)? themeNameBuilder;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: const ColoredBox(
            key: ValueKey<String>('host4_theme_store_content_background'),
            color: Color(0xFFF4F7FC),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          child: Host4TopBar(
            key: const ValueKey<String>('host4_theme_store_top_bar'),
            safeAreaTop: 0,
            title: title,
            titleKey: const ValueKey<String>('host4_theme_store_title'),
            trailing: showSearchButton
                ? _HeaderIconButton(
                    keyValue: 'host4_theme_store_search',
                    icon: Icons.search_rounded,
                    onTap: onSearch,
                  )
                : null,
            status: statusSource == null
                ? null
                : Host4SystemStatus(
                    key: const ValueKey<String>(
                      'host4_theme_store_system_status',
                    ),
                    source: statusSource!,
                  ),
          ),
        ),
        Positioned(
          left: 66,
          top: 84,
          width: 532,
          child: _ThemeStoreGrid(
            manager: manager,
            pendingThemeId: pendingThemeId,
            cardFocusNodes: cardFocusNodes,
            themeNameBuilder: themeNameBuilder,
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
              onConfirm: onConfirm,
              onBack: onBack,
            ),
          ),
      ],
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
        child: SizedBox(
          width: 40,
          height: 32,
          child: Center(
            child: Icon(icon, size: 24, color: theme.colors.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _ThemeStoreGrid extends StatelessWidget {
  const _ThemeStoreGrid({
    required this.manager,
    required this.pendingThemeId,
    required this.cardFocusNodes,
    required this.onApplyTheme,
    this.themeNameBuilder,
  });

  final Host4ThemeManager manager;
  final String? pendingThemeId;
  final Map<String, FocusNode> cardFocusNodes;
  final void Function(Host4ThemeManager, Host4ThemeCatalogEntry) onApplyTheme;
  final String Function(Host4ThemeCatalogEntry entry)? themeNameBuilder;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var index = 0; index < manager.catalog.length; index++)
          _ThemeCard(
            entry: manager.catalog[index],
            focusNode: cardFocusNodes[manager.catalog[index].id]!,
            selected: manager.currentThemeId == manager.catalog[index].id,
            loading: pendingThemeId == manager.catalog[index].id,
            themeName:
                themeNameBuilder?.call(manager.catalog[index]) ??
                manager.catalog[index].name,
            onActivate: () => onApplyTheme(manager, manager.catalog[index]),
          ),
      ],
    );
  }
}

class _ThemeCard extends StatefulWidget {
  const _ThemeCard({
    required this.entry,
    required this.focusNode,
    required this.selected,
    required this.loading,
    required this.themeName,
    required this.onActivate,
  });

  final Host4ThemeCatalogEntry entry;
  final FocusNode focusNode;
  final bool selected;
  final bool loading;
  final String themeName;
  final VoidCallback onActivate;

  @override
  State<_ThemeCard> createState() => _ThemeCardState();
}

class _ThemeCardState extends State<_ThemeCard> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _ThemeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.focusNode, widget.focusNode)) {
      oldWidget.focusNode.removeListener(_handleFocusChanged);
      widget.focusNode.addListener(_handleFocusChanged);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChanged);
    super.dispose();
  }

  void _handleFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    // 已应用主题与手柄焦点可能落在不同卡片；描边只给焦点项，
    // 当前主题通过右下角 pill / 背景亮度区分，避免同时出现两个选中框。
    final focused = widget.focusNode.hasPrimaryFocus;
    final borderColor = focused
        ? theme.colors.focus
        : theme.colors.borderDefault;
    final borderWidth = focused ? 2.0 : 1.0;

    return Semantics(
      identifier: 'theme_store.card_${widget.entry.id}',
      button: true,
      selected: widget.selected,
      child: Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.keyA): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (intent) {
                widget.onActivate();
                return null;
              },
            ),
          },
          child: Focus(
            focusNode: widget.focusNode,
            child: InkWell(
              key: ValueKey<String>('host4_theme_card_${widget.entry.id}'),
              onTap: () {
                widget.focusNode.requestFocus();
                widget.onActivate();
              },
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 172,
                height: 124,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: widget.selected ? 0.88 : 0.68,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: borderColor,
                            width: borderWidth,
                          ),
                          boxShadow: focused
                              ? [
                                  BoxShadow(
                                    color: theme.colors.focus.withValues(
                                      alpha: 0.2,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 4,
                      top: 4,
                      width: 164,
                      height: 89,
                      child: _ThemePreview(entry: widget.entry),
                    ),
                    Positioned(
                      left: 11,
                      top: 98,
                      width: 96,
                      height: 18,
                      child: Text(
                        widget.themeName,
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
                      child: _ThemeActionPill(
                        selected: widget.selected,
                        loading: widget.loading,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
    final background = selected
        ? theme.colors.brandPrimary
        : theme.colors.textPrimary;

    return Semantics(
      identifier: selected ? 'theme_store.selected_pill' : null,
      child: Container(
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
      ),
    );
  }
}

class _ThemeStoreControllerHints extends StatelessWidget {
  const _ThemeStoreControllerHints({
    required this.confirmLabel,
    required this.backLabel,
    required this.onConfirm,
    required this.onBack,
  });

  final String confirmLabel;
  final String backLabel;
  final VoidCallback onConfirm;
  final VoidCallback onBack;

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
            keyValue: 'host4_theme_store_controller_hints_confirm',
            label: 'A',
            text: confirmLabel,
            color: const Color(0xFF32A565),
            onTap: onConfirm,
          ),
          const SizedBox(width: 26),
          _ControllerHintButton(
            keyValue: 'host4_theme_store_controller_hints_back',
            label: 'B',
            text: backLabel,
            color: const Color(0xFFD8474F),
            onTap: onBack,
          ),
        ],
      ),
    );
  }
}

class _ControllerHintButton extends StatelessWidget {
  const _ControllerHintButton({
    required this.keyValue,
    required this.label,
    required this.text,
    required this.color,
    required this.onTap,
  });

  final String keyValue;
  final String label;
  final String text;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return Semantics(
      button: true,
      child: GestureDetector(
        key: ValueKey<String>(keyValue),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 42,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
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
            ),
          ),
        ),
      ),
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
