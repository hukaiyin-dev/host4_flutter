import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../input/host4_emulator_input_event.dart';
import '../model/host4_emulator_control_layout_style.dart';
import '../model/host4_emulator_control_profile.dart';
import 'host4_emulator_action_button.dart';
import 'host4_emulator_auxiliary_button.dart';
import 'host4_emulator_dpad.dart';
import 'host4_emulator_silicone_layout.dart';
import 'host4_emulator_silicone_pad.dart';

class Host4EmulatorControlsLayer extends StatelessWidget {
  const Host4EmulatorControlsLayer({
    required this.profile,
    required this.onInput,
    required this.onMenuTap,
    this.layoutStyle = Host4EmulatorControlLayoutStyle.modern,
    super.key,
  });

  final Host4EmulatorControlProfile profile;
  final ValueChanged<Host4EmulatorInputEvent> onInput;
  final VoidCallback onMenuTap;
  final Host4EmulatorControlLayoutStyle layoutStyle;

  @override
  Widget build(BuildContext context) {
    return switch (layoutStyle) {
      Host4EmulatorControlLayoutStyle.modern => _ModernControls(
        profile: profile,
        onInput: onInput,
        onMenuTap: onMenuTap,
      ),
      Host4EmulatorControlLayoutStyle.silicone => _SiliconeControls(
        profile: profile,
        onInput: onInput,
        onMenuTap: onMenuTap,
      ),
    };
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

class _SiliconeControls extends StatelessWidget {
  const _SiliconeControls({
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
        final metrics = Host4EmulatorSiliconeMetrics.of(context);

        final Host4EmulatorSiliconeResolvedLayout layout;
        final List<Host4EmulatorSiliconePadBinding> bindings;

        if (landscape) {
          layout = Host4EmulatorSiliconeLayoutResolver.landscape(
            screenSize: size,
            metrics: metrics,
          );
          bindings = _landscapeBindings;
        } else {
          final padding = MediaQuery.paddingOf(context);
          layout = Host4EmulatorSiliconeLayoutResolver.portrait(
            screenSize: size,
            metrics: metrics,
            topInset: padding.top,
            bottomInset: padding.bottom,
          );
          bindings = _portraitBindings;
        }

        final edge = 24.0 *
            (landscape
                ? math.min(size.width / 844, size.height / 390)
                    .clamp(0.65, 1.4)
                : math.min(size.width / 390, size.height / 844)
                    .clamp(0.78, 1.25));

        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            for (final binding in bindings)
              Host4EmulatorSiliconePad(
                layout: layout,
                binding: binding,
                onEvent: onInput,
              ),
            if (profile.hasShoulderButtons && !landscape) ..._portraitShoulders(
              layout,
            ),
            if (profile.hasShoulderButtons && landscape) ..._landscapeShoulders(
              layout,
            ),
            _menuButton(layout, size, landscape, edge),
          ],
        );
      },
    );
  }

  List<Widget> _portraitShoulders(
    Host4EmulatorSiliconeResolvedLayout layout,
  ) {
    return <Widget>[
      _auxiliaryFromControl(layout, 'game.controls.btn_l', 'l',
          'landscape_shoulder_l1.svg'),
      _auxiliaryFromControl(layout, 'game.controls.btn_r', 'r',
          'landscape_shoulder_r1.svg'),
    ];
  }

  List<Widget> _landscapeShoulders(
    Host4EmulatorSiliconeResolvedLayout layout,
  ) {
    return <Widget>[
      _auxiliaryFromControl(layout, 'landscape.controls.btn_l2', 'l',
          'landscape_shoulder_l1.svg'),
      _auxiliaryFromControl(layout, 'landscape.controls.btn_r2', 'r',
          'landscape_shoulder_r1.svg'),
    ];
  }

  Widget _auxiliaryFromControl(
    Host4EmulatorSiliconeResolvedLayout layout,
    String identifier,
    String input,
    String asset,
  ) {
    final control = layout.controls[identifier];
    if (control == null) return const SizedBox.shrink();
    return Positioned(
      left: control.hitRect.left,
      top: control.hitRect.top,
      child: Host4EmulatorAuxiliaryButton(
        input: input,
        asset: asset,
        size: control.hitRect.size,
        onEvent: onInput,
      ),
    );
  }

  Widget _menuButton(
    Host4EmulatorSiliconeResolvedLayout layout,
    Size size,
    bool landscape,
    double edge,
  ) {
    final String identifier = landscape
        ? 'landscape.controls.btn_set'
        : 'game.controls.btn_set';
    final control = layout.controls[identifier];
    if (control == null) {
      return Positioned(
        left: size.width / 2 - 21,
        top: edge,
        child: Host4EmulatorAuxiliaryButton(
          asset: 'logo_group.svg',
          size: const Size.square(42),
          onTap: onMenuTap,
        ),
      );
    }
    return Positioned(
      left: control.hitRect.left,
      top: control.hitRect.top,
      child: Host4EmulatorAuxiliaryButton(
        asset: 'logo_group.svg',
        size: control.hitRect.size,
        onTap: onMenuTap,
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
            label: 'START',
            semanticsIdentifier: 'game.controls.btn_start',
          ),
          innerBottom: Host4EmulatorSiliconePadSmallBinding(
            slot: Host4EmulatorSiliconePadSlot.innerBottom,
            inputName: 'select',
            label: 'SELECT',
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
            label: 'SELECT',
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
            label: 'START',
            semanticsIdentifier: 'landscape.controls.btn_start',
          ),
        ),
      ];
}
