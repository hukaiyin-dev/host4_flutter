import 'dart:math' as math;

import 'package:display_metrics/display_metrics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../input/host4_emulator_input_event.dart';
import '../model/host4_emulator_control_layout_style.dart';
import '../model/host4_emulator_control_profile.dart';
import '../model/host4_emulator_silicone_layout_variant.dart';
import 'host4_emulator_action_button.dart';
import 'host4_emulator_auxiliary_button.dart';
import 'host4_emulator_dpad.dart';
import 'host4_emulator_landscape_controls.dart';
import 'host4_emulator_silicone_layout.dart';
import 'host4_emulator_silicone_pad.dart';

class Host4EmulatorControlsLayer extends StatelessWidget {
  const Host4EmulatorControlsLayer({
    required this.profile,
    required this.onInput,
    required this.onMenuTap,
    this.onLocateTap,
    this.layoutStyle = Host4EmulatorControlLayoutStyle.modern,
    this.siliconeLayoutVariant = Host4EmulatorSiliconeLayoutVariant.silicone,
    super.key,
  });

  final Host4EmulatorControlProfile profile;
  final ValueChanged<Host4EmulatorInputEvent> onInput;
  final VoidCallback onMenuTap;
  final VoidCallback? onLocateTap;
  final Host4EmulatorControlLayoutStyle layoutStyle;
  final Host4EmulatorSiliconeLayoutVariant siliconeLayoutVariant;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final landscape = constraints.maxWidth >= constraints.maxHeight;
        if (layoutStyle == Host4EmulatorControlLayoutStyle.modern) {
          return _ModernControls(
            profile: profile,
            onInput: onInput,
            onMenuTap: onMenuTap,
          );
        }
        if (!landscape ||
            siliconeLayoutVariant ==
                Host4EmulatorSiliconeLayoutVariant.silicone) {
          return DisplayMetricsWidget(
            child: _SiliconeControls(
              profile: profile,
              onInput: onInput,
              onMenuTap: onMenuTap,
              onLocateTap: onLocateTap,
            ),
          );
        }
        return Host4EmulatorLandscapeControls(
          profile: profile,
          variant: siliconeLayoutVariant,
          onInput: onInput,
          onMenuTap: onMenuTap,
        );
      },
    );
  }
}

class Host4EmulatorActiveMenuButton extends StatelessWidget {
  const Host4EmulatorActiveMenuButton({
    required this.layoutStyle,
    required this.onTap,
    this.siliconeLayoutVariant = Host4EmulatorSiliconeLayoutVariant.silicone,
    super.key,
  });

  final Host4EmulatorControlLayoutStyle layoutStyle;
  final Host4EmulatorSiliconeLayoutVariant siliconeLayoutVariant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final landscape = size.width >= size.height;
        if (layoutStyle == Host4EmulatorControlLayoutStyle.modern) {
          final scale = landscape
              ? math.min(size.width / 844, size.height / 390).clamp(0.65, 1.4)
              : math.min(size.width / 390, size.height / 844).clamp(0.78, 1.25);
          return SafeArea(
            child: Stack(
              children: <Widget>[
                Positioned(
                  key: const ValueKey<String>('controls.active_menu'),
                  left: size.width / 2 - 21 * scale,
                  top: 24 * scale,
                  child: Host4EmulatorAuxiliaryButton(
                    asset: 'logo_group.svg',
                    size: Size.square(42 * scale),
                    onTap: onTap,
                  ),
                ),
              ],
            ),
          );
        }
        if (!landscape ||
            siliconeLayoutVariant ==
                Host4EmulatorSiliconeLayoutVariant.silicone) {
          return DisplayMetricsWidget(child: _ActiveSiliconeMenuButton(onTap));
        }
        final scale = math.min(size.width / 844, size.height / 390);
        final offset = Offset(
          (size.width - 844 * scale) / 2,
          (size.height - 390 * scale) / 2,
        );
        return Stack(
          children: <Widget>[
            Positioned(
              key: const ValueKey<String>('controls.active_menu'),
              left: offset.dx + 401 * scale,
              top: offset.dy + 336 * scale,
              child: Host4EmulatorAuxiliaryButton(
                asset: 'logo_group.svg',
                size: Size.square(42 * scale),
                onTap: onTap,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ActiveSiliconeMenuButton extends StatelessWidget {
  const _ActiveSiliconeMenuButton(this.onTap);

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final landscape = size.width >= size.height;
        final metrics = Host4EmulatorSiliconeMetrics.of(context);
        final padding = MediaQuery.paddingOf(context);
        final layout = landscape
            ? Host4EmulatorSiliconeLayoutResolver.landscape(
                screenSize: size,
                metrics: metrics,
              )
            : Host4EmulatorSiliconeLayoutResolver.portrait(
                screenSize: size,
                metrics: metrics,
                topInset: padding.top,
                bottomInset: padding.bottom,
              );
        final identifier = landscape
            ? 'landscape.controls.btn_set'
            : 'game.controls.btn_set';
        final control = layout.controls[identifier];
        if (control == null) return const SizedBox.shrink();
        return Stack(
          children: <Widget>[
            Positioned(
              left: control.hitRect.left,
              top: control.hitRect.top,
              child: _SiliconeSystemButton(
                semanticsIdentifier: 'controls.active_menu',
                hitSize: control.hitRect.size,
                visualSize: control.visualSize,
                asset: 'logo_group.svg',
                centerStyle: true,
                selected: true,
                onTap: onTap,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ModernControls extends StatelessWidget {
  const _ModernControls({
    required this.profile,
    required this.onInput,
    required this.onMenuTap,
  });

  final Host4EmulatorControlProfile profile;
  final ValueChanged<Host4EmulatorInputEvent> onInput;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final landscape = size.width >= size.height;
        final scale = landscape
            ? math.min(size.width / 844, size.height / 390).clamp(0.65, 1.4)
            : math.min(size.width / 390, size.height / 844).clamp(0.78, 1.25);
        final dpadSize = 126.0 * scale;
        final actionSize = 48.0 * scale;
        final edge = 24.0 * scale;

        return SafeArea(
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned(
                key: const ValueKey<String>('controls.dpad'),
                left: edge,
                bottom: landscape ? edge : 72 * scale,
                child: Host4EmulatorDPad(size: dpadSize, onEvent: onInput),
              ),
              Positioned(
                key: const ValueKey<String>('controls.b'),
                right: 92 * scale,
                bottom: landscape ? 28 * scale : 74 * scale,
                child: Host4EmulatorActionButton(
                  input: 'b',
                  label: 'B',
                  diameter: actionSize,
                  onEvent: onInput,
                ),
              ),
              Positioned(
                key: const ValueKey<String>('controls.a'),
                right: 28 * scale,
                bottom: landscape ? 86 * scale : 130 * scale,
                child: Host4EmulatorActionButton(
                  input: 'a',
                  label: 'A',
                  diameter: actionSize,
                  onEvent: onInput,
                ),
              ),
              Positioned(
                key: const ValueKey<String>('controls.select'),
                left: size.width / 2 - 88 * scale,
                bottom: 22 * scale,
                child: Host4EmulatorAuxiliaryButton(
                  input: 'select',
                  asset: 'landscape_button_select.svg',
                  size: Size(72 * scale, 28 * scale),
                  onEvent: onInput,
                ),
              ),
              Positioned(
                key: const ValueKey<String>('controls.start'),
                left: size.width / 2 + 16 * scale,
                bottom: 22 * scale,
                child: Host4EmulatorAuxiliaryButton(
                  input: 'start',
                  asset: 'landscape_button_start.svg',
                  size: Size(72 * scale, 28 * scale),
                  onEvent: onInput,
                ),
              ),
              if (profile.hasShoulderButtons) ...<Widget>[
                Positioned(
                  key: const ValueKey<String>('controls.l'),
                  left: edge,
                  top: edge,
                  child: Host4EmulatorAuxiliaryButton(
                    input: 'l',
                    asset: 'landscape_shoulder_l1.svg',
                    size: Size.square(68 * scale),
                    onEvent: onInput,
                  ),
                ),
                Positioned(
                  key: const ValueKey<String>('controls.r'),
                  right: edge,
                  top: edge,
                  child: Host4EmulatorAuxiliaryButton(
                    input: 'r',
                    asset: 'landscape_shoulder_r1.svg',
                    size: Size.square(68 * scale),
                    onEvent: onInput,
                  ),
                ),
              ],
              Positioned(
                key: const ValueKey<String>('controls.menu'),
                left: size.width / 2 - 21 * scale,
                top: edge,
                child: Host4EmulatorAuxiliaryButton(
                  asset: 'logo_group.svg',
                  size: Size.square(42 * scale),
                  onTap: onMenuTap,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SiliconeControls extends StatefulWidget {
  const _SiliconeControls({
    required this.profile,
    required this.onInput,
    required this.onMenuTap,
    required this.onLocateTap,
  });

  final Host4EmulatorControlProfile profile;
  final ValueChanged<Host4EmulatorInputEvent> onInput;
  final VoidCallback onMenuTap;
  final VoidCallback? onLocateTap;

  @override
  State<_SiliconeControls> createState() => _SiliconeControlsState();
}

class _SiliconeControlsState extends State<_SiliconeControls> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final landscape = size.width >= size.height;
        final metrics = Host4EmulatorSiliconeMetrics.of(context);
        final padding = MediaQuery.paddingOf(context);

        final Host4EmulatorSiliconeResolvedLayout layout;
        final List<Host4EmulatorSiliconePadBinding> bindings;

        if (landscape) {
          layout = Host4EmulatorSiliconeLayoutResolver.landscape(
            screenSize: size,
            metrics: metrics,
          );
          bindings = widget.profile.hasFourFaceButtons
              ? _landscapeBindingsWithFourFaceButtons
              : widget.profile.hasShoulderButtons
              ? _landscapeBindings
              : _landscapeBindingsWithoutShoulders;
        } else {
          layout = Host4EmulatorSiliconeLayoutResolver.portrait(
            screenSize: size,
            metrics: metrics,
            topInset: padding.top,
            bottomInset: padding.bottom,
          );
          bindings = _portraitBindings;
        }

        if (_collapsed) {
          return SizedBox.fromSize(
            size: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[_hideToggle(layout, landscape)],
            ),
          );
        }

        return SizedBox.fromSize(
          size: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              for (final binding in bindings)
                Host4EmulatorSiliconePad(
                  layout: layout,
                  binding: binding,
                  onEvent: widget.onInput,
                ),
              if (!landscape) ..._portraitShoulders(layout),
              if (widget.profile.hasShoulderButtons && landscape)
                ..._landscapeShoulders(layout),
              if (!landscape && widget.onLocateTap != null)
                _locateButton(layout),
              _menuButton(layout, size, landscape),
              _hideToggle(layout, landscape),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _portraitShoulders(Host4EmulatorSiliconeResolvedLayout layout) {
    return <Widget>[
      _shoulderButton(layout, 'game.controls.btn_l', 'l', 'L'),
      _shoulderButton(layout, 'game.controls.btn_r', 'r', 'R'),
    ];
  }

  List<Widget> _landscapeShoulders(Host4EmulatorSiliconeResolvedLayout layout) {
    return <Widget>[
      _shoulderButton(layout, 'landscape.controls.btn_l2', 'l', 'L'),
      _shoulderButton(layout, 'landscape.controls.btn_r2', 'r', 'R'),
    ];
  }

  Widget _shoulderButton(
    Host4EmulatorSiliconeResolvedLayout layout,
    String identifier,
    String input,
    String label,
  ) {
    final control = layout.controls[identifier];
    if (control == null) return const SizedBox.shrink();
    return Positioned(
      left: control.hitRect.left,
      top: control.hitRect.top,
      child: Host4EmulatorSiliconeSmallButton(
        hitSize: control.hitRect.size,
        visualSize: control.visualSize,
        label: label,
        inputName: input,
        onEvent: widget.onInput,
      ),
    );
  }

  Widget _menuButton(
    Host4EmulatorSiliconeResolvedLayout layout,
    Size size,
    bool landscape,
  ) {
    final String identifier = landscape
        ? 'landscape.controls.btn_set'
        : 'game.controls.btn_set';
    final control = layout.controls[identifier];
    if (control == null) {
      return Positioned(
        left: size.width / 2 - 21,
        top: 24,
        child: Host4EmulatorAuxiliaryButton(
          asset: 'logo_group.svg',
          size: const Size.square(42),
          onTap: widget.onMenuTap,
        ),
      );
    }
    return Positioned(
      left: control.hitRect.left,
      top: control.hitRect.top,
      child: _SiliconeSystemButton(
        semanticsIdentifier: identifier,
        hitSize: control.hitRect.size,
        visualSize: control.visualSize,
        asset: 'logo_group.svg',
        centerStyle: true,
        onTap: widget.onMenuTap,
      ),
    );
  }

  Widget _locateButton(Host4EmulatorSiliconeResolvedLayout layout) {
    const identifier = 'game.controls.btn_locate_placeholder';
    final control = layout.controls[identifier];
    if (control == null) return const SizedBox.shrink();
    return Positioned(
      left: control.hitRect.left,
      top: control.hitRect.top,
      child: _SiliconeSystemButton(
        semanticsIdentifier: identifier,
        hitSize: control.hitRect.size,
        visualSize: control.visualSize,
        asset: 'ic_dingwei.svg',
        onTap: widget.onLocateTap!,
      ),
    );
  }

  Widget _hideToggle(
    Host4EmulatorSiliconeResolvedLayout layout,
    bool landscape,
  ) {
    final String identifier = landscape
        ? 'landscape.controls.hide_toggle'
        : 'game.controls.btn_hide_toggle';
    final control = layout.controls[identifier];
    if (control == null) return const SizedBox.shrink();
    return Positioned(
      left: control.hitRect.left,
      top: control.hitRect.top,
      child: _SiliconeSystemButton(
        semanticsIdentifier: identifier,
        hitSize: control.hitRect.size,
        visualSize: control.visualSize,
        asset: 'ic_expand.svg',
        iconQuarterTurns: _collapsed ? 2 : 0,
        onTap: () => setState(() => _collapsed = !_collapsed),
      ),
    );
  }

  static const List<Host4EmulatorSiliconePadBinding> _portraitBindings =
      <Host4EmulatorSiliconePadBinding>[
        Host4EmulatorSiliconePadBinding(
          side: Host4EmulatorSiliconePadSide.single,
          dpadIdentifier: 'game.controls.dpad',
          actions: <Host4EmulatorSiliconePadActionBinding>[
            Host4EmulatorSiliconePadActionBinding(
              slot: Host4EmulatorSiliconePadSlot.actionTop,
              inputName: 'x',
              label: 'X',
              semanticsIdentifier: 'game.controls.btn_x',
            ),
            Host4EmulatorSiliconePadActionBinding(
              slot: Host4EmulatorSiliconePadSlot.actionLeft,
              inputName: 'y',
              label: 'Y',
              semanticsIdentifier: 'game.controls.btn_y',
            ),
            Host4EmulatorSiliconePadActionBinding(
              slot: Host4EmulatorSiliconePadSlot.actionRight,
              inputName: 'a',
              label: 'A',
              semanticsIdentifier: 'game.controls.btn_a',
            ),
            Host4EmulatorSiliconePadActionBinding(
              slot: Host4EmulatorSiliconePadSlot.actionBottom,
              inputName: 'b',
              label: 'B',
              semanticsIdentifier: 'game.controls.btn_b',
            ),
          ],
          innerTop: Host4EmulatorSiliconePadSmallBinding(
            slot: Host4EmulatorSiliconePadSlot.innerTop,
            inputName: 'start',
            label: 'Start',
            semanticsIdentifier: 'game.controls.btn_start',
          ),
          innerBottom: Host4EmulatorSiliconePadSmallBinding(
            slot: Host4EmulatorSiliconePadSlot.innerBottom,
            inputName: 'select',
            label: 'Select',
            semanticsIdentifier: 'game.controls.btn_select',
          ),
        ),
      ];

  static const List<Host4EmulatorSiliconePadBinding> _landscapeBindings =
      <Host4EmulatorSiliconePadBinding>[
        Host4EmulatorSiliconePadBinding(
          side: Host4EmulatorSiliconePadSide.left,
          dpadIdentifier: 'landscape.controls.dpad_left',
          actionClusterIdentifier: 'landscape.controls.action_cluster_left',
          dpadDisplayQuarterTurns: 1,
          dpadInputQuarterTurns: 1,
          actionDirectionDisplayQuarterTurns: 1,
          actions: <Host4EmulatorSiliconePadActionBinding>[
            Host4EmulatorSiliconePadActionBinding(
              slot: Host4EmulatorSiliconePadSlot.actionTop,
              inputName: 'up',
              label: 'Up',
              semanticsIdentifier: 'landscape.controls.dpad_left.up',
              visual: Host4EmulatorSiliconePadActionVisual.direction,
            ),
            Host4EmulatorSiliconePadActionBinding(
              slot: Host4EmulatorSiliconePadSlot.actionBottom,
              inputName: 'down',
              label: 'Down',
              semanticsIdentifier: 'landscape.controls.dpad_left.down',
              visual: Host4EmulatorSiliconePadActionVisual.direction,
            ),
            Host4EmulatorSiliconePadActionBinding(
              slot: Host4EmulatorSiliconePadSlot.actionLeft,
              inputName: 'left',
              label: 'Left',
              semanticsIdentifier: 'landscape.controls.dpad_left.left',
              visual: Host4EmulatorSiliconePadActionVisual.direction,
            ),
            Host4EmulatorSiliconePadActionBinding(
              slot: Host4EmulatorSiliconePadSlot.actionRight,
              inputName: 'right',
              label: 'Right',
              semanticsIdentifier: 'landscape.controls.dpad_left.right',
              visual: Host4EmulatorSiliconePadActionVisual.direction,
            ),
          ],
          innerTop: Host4EmulatorSiliconePadSmallBinding(
            slot: Host4EmulatorSiliconePadSlot.innerTop,
            inputName: 'l',
            label: 'L',
            semanticsIdentifier: 'landscape.controls.btn_l1',
          ),
          innerBottom: Host4EmulatorSiliconePadSmallBinding(
            slot: Host4EmulatorSiliconePadSlot.innerBottom,
            inputName: 'select',
            label: 'Select',
            semanticsIdentifier: 'landscape.controls.btn_select',
          ),
        ),
        Host4EmulatorSiliconePadBinding(
          side: Host4EmulatorSiliconePadSide.right,
          dpadIdentifier: 'landscape.controls.action_cluster',
          actionClusterIdentifier: 'landscape.controls.dpad_right',
          dpadDisplayQuarterTurns: -1,
          dpadInputQuarterTurns: -1,
          actionDirectionDisplayQuarterTurns: -1,
          actions: <Host4EmulatorSiliconePadActionBinding>[
            Host4EmulatorSiliconePadActionBinding(
              slot: Host4EmulatorSiliconePadSlot.actionRight,
              inputName: 'a',
              label: 'A',
              semanticsIdentifier: 'landscape.controls.btn_a',
            ),
            Host4EmulatorSiliconePadActionBinding(
              slot: Host4EmulatorSiliconePadSlot.actionBottom,
              inputName: 'b',
              label: 'B',
              semanticsIdentifier: 'landscape.controls.btn_b',
            ),
          ],
          innerTop: Host4EmulatorSiliconePadSmallBinding(
            slot: Host4EmulatorSiliconePadSlot.innerTop,
            inputName: 'r',
            label: 'R',
            semanticsIdentifier: 'landscape.controls.btn_r1',
          ),
          innerBottom: Host4EmulatorSiliconePadSmallBinding(
            slot: Host4EmulatorSiliconePadSlot.innerBottom,
            inputName: 'start',
            label: 'Start',
            semanticsIdentifier: 'landscape.controls.btn_start',
          ),
        ),
      ];

  static final List<Host4EmulatorSiliconePadBinding>
  _landscapeBindingsWithFourFaceButtons = _landscapeBindings
      .map(_withFourFaceButtons)
      .toList(growable: false);

  static Host4EmulatorSiliconePadBinding _withFourFaceButtons(
    Host4EmulatorSiliconePadBinding binding,
  ) {
    if (binding.side != Host4EmulatorSiliconePadSide.right) {
      return binding;
    }
    return Host4EmulatorSiliconePadBinding(
      side: binding.side,
      dpadIdentifier: binding.dpadIdentifier,
      actions: <Host4EmulatorSiliconePadActionBinding>[
        const Host4EmulatorSiliconePadActionBinding(
          slot: Host4EmulatorSiliconePadSlot.actionTop,
          inputName: 'x',
          label: 'X',
          semanticsIdentifier: 'landscape.controls.btn_x',
        ),
        const Host4EmulatorSiliconePadActionBinding(
          slot: Host4EmulatorSiliconePadSlot.actionLeft,
          inputName: 'y',
          label: 'Y',
          semanticsIdentifier: 'landscape.controls.btn_y',
        ),
        ...binding.actions,
      ],
      dpadAliasIdentifier: binding.dpadAliasIdentifier,
      actionClusterIdentifier: binding.actionClusterIdentifier,
      actionDirectionDisplayQuarterTurns:
          binding.actionDirectionDisplayQuarterTurns,
      dpadDisplayQuarterTurns: binding.dpadDisplayQuarterTurns,
      dpadInputQuarterTurns: binding.dpadInputQuarterTurns,
      innerTop: binding.innerTop,
      innerBottom: binding.innerBottom,
    );
  }

  static final List<Host4EmulatorSiliconePadBinding>
  _landscapeBindingsWithoutShoulders = _landscapeBindings
      .map(_withoutShoulderBinding)
      .toList(growable: false);

  static Host4EmulatorSiliconePadBinding _withoutShoulderBinding(
    Host4EmulatorSiliconePadBinding binding,
  ) {
    return Host4EmulatorSiliconePadBinding(
      side: binding.side,
      dpadIdentifier: binding.dpadIdentifier,
      actions: binding.actions,
      dpadAliasIdentifier: binding.dpadAliasIdentifier,
      actionClusterIdentifier: binding.actionClusterIdentifier,
      actionDirectionDisplayQuarterTurns:
          binding.actionDirectionDisplayQuarterTurns,
      dpadDisplayQuarterTurns: binding.dpadDisplayQuarterTurns,
      dpadInputQuarterTurns: binding.dpadInputQuarterTurns,
      innerBottom: binding.innerBottom,
    );
  }
}

class _SiliconeSystemButton extends StatefulWidget {
  const _SiliconeSystemButton({
    required this.semanticsIdentifier,
    required this.hitSize,
    required this.visualSize,
    required this.asset,
    required this.onTap,
    this.centerStyle = false,
    this.selected = false,
    this.iconQuarterTurns = 0,
  });

  final String semanticsIdentifier;
  final Size hitSize;
  final Size visualSize;
  final String asset;
  final VoidCallback onTap;
  final bool centerStyle;
  final bool selected;
  final int iconQuarterTurns;

  @override
  State<_SiliconeSystemButton> createState() => _SiliconeSystemButtonState();
}

class _SiliconeSystemButtonState extends State<_SiliconeSystemButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
    if (value) HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: ValueKey<String>(widget.semanticsIdentifier),
      container: true,
      enabled: true,
      identifier: widget.semanticsIdentifier,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: SizedBox.fromSize(
          size: widget.hitSize,
          child: Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 60),
              opacity: _pressed ? 0.85 : 1,
              child: Container(
                width: widget.visualSize.width,
                height: widget.visualSize.height,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.centerStyle
                      ? widget.selected
                            ? const Color(0xFFE7EDF8)
                            : const Color(0x66E7EDF8)
                      : const Color(0xA6FFFFFF),
                ),
                alignment: Alignment.center,
                child: SizedBox.square(
                  dimension: widget.visualSize.shortestSide * 0.55,
                  child: RotatedBox(
                    quarterTurns: widget.iconQuarterTurns,
                    child: SvgPicture.asset(
                      'assets/controls/${widget.asset}',
                      package: 'host4_flutter_emulator_ui',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
