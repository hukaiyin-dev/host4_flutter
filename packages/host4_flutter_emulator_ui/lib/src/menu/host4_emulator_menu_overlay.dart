import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/emulator_ui_strings.dart';
import '../model/host4_emulator_save_entry.dart';
import '../session/host4_emulator_session_actions.dart';

enum _MenuAction {
  quickLoad,
  saveManager,
  quickSave,
  speed,
  exit,
  continueGame,
  layout,
  keyLocator,
}

class _MenuItemModel {
  const _MenuItemModel({
    required this.identifier,
    required this.title,
    required this.asset,
    this.subtitle,
    this.highlight = false,
  });

  final String identifier;
  final String title;
  final String asset;
  final String? subtitle;
  final bool highlight;
}

class _MenuLayoutSpec {
  const _MenuLayoutSpec({
    required this.baseWidth,
    required this.panelWidth,
    required this.panelTop,
    required this.buttonHeight,
    required this.columns,
    required this.gap,
  });

  final double baseWidth;
  final double panelWidth;
  final double panelTop;
  final double buttonHeight;
  final int columns;
  final double gap;

  static const portrait = _MenuLayoutSpec(
    baseWidth: 390,
    panelWidth: 342,
    panelTop: 75,
    buttonHeight: 102,
    columns: 2,
    gap: 8,
  );

  static const landscape = _MenuLayoutSpec(
    baseWidth: 844,
    panelWidth: 424,
    panelTop: 49,
    buttonHeight: 65,
    columns: 3,
    gap: 8,
  );
}

class _MenuSpec {
  const _MenuSpec({required this.layout, required this.rows});

  final _MenuLayoutSpec layout;
  final List<List<_MenuAction?>> rows;
}

class Host4EmulatorMenuOverlay extends StatefulWidget {
  const Host4EmulatorMenuOverlay({
    required this.actions,
    required this.onOpenSaveManager,
    this.dataSource,
    this.onOpenLayoutPicker,
    this.onOpenKeyLocator,
    this.showLayoutAction = true,
    super.key,
  });

  final Host4EmulatorSessionActions actions;
  final Host4EmulatorSaveDataSource? dataSource;
  final VoidCallback onOpenSaveManager;
  final VoidCallback? onOpenLayoutPicker;
  final VoidCallback? onOpenKeyLocator;
  final bool showLayoutAction;

  @override
  State<Host4EmulatorMenuOverlay> createState() =>
      _Host4EmulatorMenuOverlayState();
}

class _Host4EmulatorMenuOverlayState extends State<Host4EmulatorMenuOverlay> {
  static const _portraitSpec = _MenuSpec(
    layout: _MenuLayoutSpec.portrait,
    rows: <List<_MenuAction?>>[
      <_MenuAction?>[_MenuAction.quickSave, _MenuAction.exit],
      <_MenuAction?>[_MenuAction.saveManager, _MenuAction.speed],
      <_MenuAction?>[_MenuAction.quickLoad, _MenuAction.continueGame],
    ],
  );

  static const _landscapeSpec = _MenuSpec(
    layout: _MenuLayoutSpec.landscape,
    rows: <List<_MenuAction?>>[
      <_MenuAction?>[
        _MenuAction.quickLoad,
        _MenuAction.saveManager,
        _MenuAction.quickSave,
      ],
      <_MenuAction?>[_MenuAction.speed, _MenuAction.keyLocator, _MenuAction.exit],
      <_MenuAction?>[_MenuAction.continueGame, _MenuAction.layout, null],
    ],
  );

  static const _landscapeWithoutLayoutSpec = _MenuSpec(
    layout: _MenuLayoutSpec.landscape,
    rows: <List<_MenuAction?>>[
      <_MenuAction?>[
        _MenuAction.quickLoad,
        _MenuAction.saveManager,
        _MenuAction.quickSave,
      ],
      <_MenuAction?>[_MenuAction.speed, _MenuAction.keyLocator, _MenuAction.exit],
      <_MenuAction?>[_MenuAction.continueGame, null, null],
    ],
  );

  final FocusScopeNode _menuScopeNode = FocusScopeNode(
    debugLabel: 'host4_emulator_menu_scope',
  );
  late final Map<_MenuAction, FocusNode> _focusNodes = <_MenuAction, FocusNode>{
    for (final action in _MenuAction.values)
      action: FocusNode(debugLabel: 'menu_${action.name}_focus'),
  };

  bool _busy = false;
  String? _error;
  int? _manualSaveCount;
  DateTime? _quickSaveTime;
  int _summaryLoadEpoch = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSaveSummary());
  }

  @override
  void didUpdateWidget(Host4EmulatorMenuOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataSource != widget.dataSource) {
      unawaited(_loadSaveSummary());
    }
  }

  Future<void> _loadSaveSummary() async {
    final epoch = ++_summaryLoadEpoch;
    _manualSaveCount = null;
    _quickSaveTime = null;
    try {
      final catalog = await widget.dataSource?.load();
      if (!mounted || epoch != _summaryLoadEpoch) return;
      setState(() {
        _manualSaveCount = catalog?.manual.length;
        _quickSaveTime = catalog?.quick?.modifiedAt.toLocal();
      });
    } catch (_) {
      // Summary failure must not prevent opening the save manager.
      if (!mounted || epoch != _summaryLoadEpoch) return;
      setState(() => _manualSaveCount = null);
    }
  }

  Map<_MenuAction, _MenuItemModel> get _items => <_MenuAction, _MenuItemModel>{
    _MenuAction.quickLoad: _MenuItemModel(
      identifier: 'menu.quick_load',
      title: EmulatorUiStrings.t('menu.quickLoad'),
      subtitle: _quickSaveTime == null ? null
          : '${_quickSaveTime!.hour.toString().padLeft(2, '0')}:${_quickSaveTime!.minute.toString().padLeft(2, '0')}',
      asset: 'assets/controls/ic_save.svg',
    ),
    _MenuAction.saveManager: _MenuItemModel(
      identifier: 'menu.save_manager',
      title: EmulatorUiStrings.t('menu.saveManager'),
      subtitle: _manualSaveCount == null
          ? null
          : EmulatorUiStrings.t('menu.saveManagerUsed', {
              'used': _manualSaveCount,
              'total': host4EmulatorManualSaveSlotCount,
            }),
      asset: 'assets/controls/ic_cundangguanli.svg',
    ),
    _MenuAction.quickSave: _MenuItemModel(
      identifier: 'menu.quick_save',
      title: EmulatorUiStrings.t('menu.quickSave'),
      subtitle: EmulatorUiStrings.t('menu.quickSaveSubtitle'),
      asset: 'assets/controls/ic_load.svg',
    ),
    _MenuAction.speed: _MenuItemModel(
      identifier: 'menu.speed',
      title: EmulatorUiStrings.t('menu.speed'),
      asset: 'assets/controls/ic_beisu.svg',
    ),
    _MenuAction.exit: _MenuItemModel(
      identifier: 'menu.exit',
      title: EmulatorUiStrings.t('menu.exit'),
      asset: 'assets/controls/ic_quit.svg',
    ),
    _MenuAction.continueGame: _MenuItemModel(
      identifier: 'menu.continue',
      title: EmulatorUiStrings.t('menu.continue'),
      subtitle: EmulatorUiStrings.t('menu.continueSubtitle'),
      asset: 'assets/controls/ic_jixuyouxi.svg',
      highlight: true,
    ),
    _MenuAction.layout: _MenuItemModel(
      identifier: 'menu.layout',
      title: EmulatorUiStrings.t('menu.layout'),
      asset: 'assets/controls/ic_buju.svg',
    ),
    _MenuAction.keyLocator: _MenuItemModel(
      identifier: 'menu.key_locator',
      title: EmulatorUiStrings.t('menu.keyLocator'),
      asset: 'assets/controls/ic_dingwei.svg',
    ),
  };

  @override
  void dispose() {
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    _menuScopeNode.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleRate() async {
    final next = widget.actions.rate == 1 ? 2.0 : 1.0;
    await widget.actions.setRate(next);
  }

  VoidCallback? _onTapFor(_MenuAction action) {
    return switch (action) {
      _MenuAction.quickLoad => () => unawaited(_run(widget.actions.quickLoad)),
      _MenuAction.saveManager => widget.onOpenSaveManager,
      _MenuAction.quickSave => () => unawaited(_run(() async {
        await widget.actions.quickSave();
        await _loadSaveSummary();
      })),
      _MenuAction.speed => () => unawaited(_run(_toggleRate)),
      _MenuAction.exit => () => unawaited(_run(widget.actions.exit)),
      _MenuAction.continueGame => () => unawaited(_run(widget.actions.resume)),
      _MenuAction.layout => widget.onOpenLayoutPicker,
      _MenuAction.keyLocator => widget.onOpenKeyLocator,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _OverlayColors.mask,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final landscape = constraints.maxWidth > constraints.maxHeight;
          final spec = landscape
              ? widget.showLayoutAction
                    ? _landscapeSpec
                    : _landscapeWithoutLayoutSpec
              : _portraitSpec;
          final scale = (constraints.maxWidth / spec.layout.baseWidth).clamp(
            0.0,
            2.0,
          );
          final panelWidth = spec.layout.panelWidth * scale;
          return Stack(
            children: <Widget>[
              Positioned(
                // Portrait toolbar is anchored below the top safe inset.
                // Keep the cards below it; landscape geometry is unchanged.
                top: spec.layout.panelTop * scale +
                    (landscape ? 0 : MediaQuery.paddingOf(context).top),
                left: (constraints.maxWidth - panelWidth) / 2,
                width: panelWidth,
                child: IgnorePointer(
                  ignoring: _busy,
                  child: FocusScope(
                    node: _menuScopeNode,
                    autofocus: true,
                    child: FocusTraversalGroup(
                      policy: ReadingOrderTraversalPolicy(),
                      child: _MenuPanel(
                        spec: spec,
                        scale: scale,
                        itemBuilder: (action) => _MenuButton(
                          item: _items[action]!,
                          action: action,
                          focusNode: _focusNodes[action]!,
                          autofocus: action == _MenuAction.continueGame,
                          scale: scale,
                          buttonHeight: spec.layout.buttonHeight,
                          speed: widget.actions.rate,
                          onTap: _onTapFor(action),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_error != null)
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 24,
                  child: Text(
                    _error!,
                    key: const ValueKey<String>('menu.error'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _OverlayColors.error),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MenuPanel extends StatelessWidget {
  const _MenuPanel({
    required this.spec,
    required this.scale,
    required this.itemBuilder,
  });

  final _MenuSpec spec;
  final double scale;
  final Widget Function(_MenuAction action) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey<String>('menu.title'),
      container: true,
      identifier: 'menu.title',
      label: EmulatorUiStrings.t('menu.pauseLabel'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (var rowIndex = 0; rowIndex < spec.rows.length; rowIndex++) ...[
            if (rowIndex > 0) SizedBox(height: spec.layout.gap * scale),
            SizedBox(
              height: spec.layout.buttonHeight * scale,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (
                    var columnIndex = 0;
                    columnIndex < spec.layout.columns;
                    columnIndex++
                  ) ...[
                    if (columnIndex > 0)
                      SizedBox(width: spec.layout.gap * scale),
                    Expanded(
                      child: switch (spec.rows[rowIndex][columnIndex]) {
                        final action? => itemBuilder(action),
                        null => const SizedBox.shrink(),
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.item,
    required this.action,
    required this.focusNode,
    required this.autofocus,
    required this.scale,
    required this.buttonHeight,
    required this.speed,
    required this.onTap,
  });

  final _MenuItemModel item;
  final _MenuAction action;
  final FocusNode focusNode;
  final bool autofocus;
  final double scale;
  final double buttonHeight;
  final double speed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final focusOutset = 4 * scale;
    final cardRadius = 8 * scale;
    final focusRadius = cardRadius + focusOutset;
    final highlighted = item.highlight;
    final enabled = onTap != null;
    final titleColor = highlighted
        ? _OverlayColors.brand
        : enabled
        ? _OverlayColors.title
        : _OverlayColors.muted;
    final subtitleColor = highlighted
        ? _OverlayColors.brand
        : _OverlayColors.muted;
    final iconColor = highlighted
        ? _OverlayColors.brand
        : enabled
        ? _OverlayColors.icon
        : _OverlayColors.muted;

    return Actions(
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) { onTap?.call(); return null; }),
      },
      child: _Pressable(
      onTap: onTap,
      child: Focus(
        focusNode: focusNode,
        autofocus: autofocus,
        canRequestFocus: enabled,
        child: Builder(
          builder: (context) {
            final focused = Focus.of(context).hasFocus;
            return Semantics(
              key: ValueKey<String>(item.identifier),
              container: true,
              identifier: item.identifier,
              button: enabled,
              enabled: enabled,
              child: SizedBox(
                height: buttonHeight * scale,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    if (focused)
                      Positioned.fill(
                        left: -focusOutset,
                        top: -focusOutset,
                        right: -focusOutset,
                        bottom: -focusOutset,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(focusRadius),
                            border: Border.all(
                              color: _OverlayColors.focusRing,
                              width: 2 * scale,
                            ),
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        decoration: BoxDecoration(
                          color: highlighted
                              ? _OverlayColors.highlight
                              : _OverlayColors.card,
                          borderRadius: BorderRadius.circular(cardRadius),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(8 * scale),
                          child: Row(
                            children: <Widget>[
                              SizedBox(
                                width: 34 * scale,
                                height: 34 * scale,
                                child: Center(
                                  child: SvgPicture.asset(
                                    item.asset,
                                    package: 'host4_flutter_emulator_ui',
                                    width: 24 * scale,
                                    height: 24 * scale,
                                    fit: BoxFit.contain,
                                    colorFilter: ColorFilter.mode(
                                      iconColor,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 4 * scale),
                              Expanded(
                                child: _MenuButtonText(
                                  item: item,
                                  action: action,
                                  speed: speed,
                                  scale: scale,
                                  titleColor: titleColor,
                                  subtitleColor: subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      ),
    );
  }
}

class _MenuButtonText extends StatelessWidget {
  const _MenuButtonText({
    required this.item,
    required this.action,
    required this.speed,
    required this.scale,
    required this.titleColor,
    required this.subtitleColor,
  });

  final _MenuItemModel item;
  final _MenuAction action;
  final double speed;
  final double scale;
  final Color titleColor;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    final title = Text(
      item.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: _OverlayText.labelHeavy(scale, color: titleColor),
    );
    final subtitle = action == _MenuAction.speed
        ? '${speed.toStringAsFixed(1)}x'
        : item.subtitle;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        title,
        if (subtitle != null)
          Semantics(
            key: action == _MenuAction.speed
                ? const ValueKey<String>('menu.speed_label')
                : null,
            container: action == _MenuAction.speed,
            identifier: action == _MenuAction.speed ? 'menu.speed_label' : null,
            child: Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _OverlayText.caption(scale, color: subtitleColor),
            ),
          ),
      ],
    );
  }
}

class _Pressable extends StatefulWidget {
  const _Pressable({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value && mounted) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 60),
        opacity: !enabled
            ? 0.45
            : _pressed
            ? 0.85
            : 1,
        child: widget.child,
      ),
    );
  }
}

class _OverlayColors {
  const _OverlayColors._();

  static const mask = Color(0xCC121A29);
  static const card = Color(0xFFE7EDF8);
  static const title = Color(0xFF121A29);
  static const muted = Color(0xFF6A7691);
  static const icon = Color(0xFF3A424F);
  static const brand = Color(0xFF774FEF);
  static const focusRing = Color(0xFF9272F2);
  static const highlight = Color(0xFFC9B9F9);
  static const error = Color(0xFFEF4444);
}

class _OverlayText {
  const _OverlayText._();

  static TextStyle labelHeavy(double scale, {required Color color}) {
    return TextStyle(
      color: color,
      fontSize: 14 * scale,
      fontWeight: FontWeight.w900,
      height: 18 / 14,
    );
  }

  static TextStyle caption(double scale, {required Color color}) {
    return TextStyle(
      color: color,
      fontSize: 12 * scale,
      fontWeight: FontWeight.w400,
      height: 16 / 12,
    );
  }
}
