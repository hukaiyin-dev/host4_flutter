import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../input/host4_emulator_input_event.dart';
import '../model/host4_emulator_control_profile.dart';
import '../model/host4_emulator_silicone_layout_variant.dart';
import 'host4_emulator_action_button.dart';
import 'host4_emulator_auxiliary_button.dart';
import 'host4_emulator_dpad.dart';

class Host4EmulatorLandscapeControls extends StatefulWidget {
  const Host4EmulatorLandscapeControls({
    required this.profile,
    required this.variant,
    required this.onInput,
    required this.onMenuTap,
    super.key,
  });

  final Host4EmulatorControlProfile profile;
  final Host4EmulatorSiliconeLayoutVariant variant;
  final ValueChanged<Host4EmulatorInputEvent> onInput;
  final VoidCallback onMenuTap;

  @override
  State<Host4EmulatorLandscapeControls> createState() =>
      _Host4EmulatorLandscapeControlsState();
}

class _Host4EmulatorLandscapeControlsState
    extends State<Host4EmulatorLandscapeControls> {
  bool _collapsed = false;
  bool _retroUsesStick = true;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final scale = math.min(size.width / 844, size.height / 390);
        final offset = Offset(
          (size.width - 844 * scale) / 2,
          (size.height - 390 * scale) / 2,
        );

        Widget positioned({
          required String identifier,
          required double left,
          required double top,
          required Size baseSize,
          required Widget child,
        }) {
          return Positioned(
            left: offset.dx + left * scale,
            top: offset.dy + top * scale,
            child: SizedBox.fromSize(
              key: ValueKey<String>(identifier),
              size: Size(baseSize.width * scale, baseSize.height * scale),
              child: child,
            ),
          );
        }

        final hide = positioned(
          identifier: 'landscape.controls.hide_toggle',
          left: 736,
          top: 336,
          baseSize: const Size.square(42),
          child: Host4EmulatorAuxiliaryButton(
            asset: 'ic_expand.svg',
            size: Size.square(42 * scale),
            onTap: () => setState(() => _collapsed = !_collapsed),
          ),
        );
        if (_collapsed) {
          return Stack(clipBehavior: Clip.none, children: <Widget>[hide]);
        }

        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            ..._controlWidgets(positioned, scale),
            ..._shoulderWidgets(positioned, scale),
            positioned(
              identifier: 'controls.select',
              left: 156,
              top: 339,
              baseSize: const Size(72, 36),
              child: Host4EmulatorAuxiliaryButton(
                asset: 'landscape_button_select.svg',
                size: Size(72 * scale, 36 * scale),
                input: 'select',
                onEvent: widget.onInput,
              ),
            ),
            positioned(
              identifier: 'controls.start',
              left: 616,
              top: 339,
              baseSize: const Size(72, 36),
              child: Host4EmulatorAuxiliaryButton(
                asset: 'landscape_button_start.svg',
                size: Size(72 * scale, 36 * scale),
                input: 'start',
                onEvent: widget.onInput,
              ),
            ),
            if (widget.variant ==
                Host4EmulatorSiliconeLayoutVariant.retroTraditional)
              positioned(
                identifier: 'landscape.controls.retro_mode_toggle',
                left: 66,
                top: 336,
                baseSize: const Size.square(42),
                child: _RetroModeToggle(
                  scale: scale,
                  showStickIcon: !_retroUsesStick,
                  onTap: () =>
                      setState(() => _retroUsesStick = !_retroUsesStick),
                ),
              ),
            positioned(
              identifier: 'controls.menu',
              left: 401,
              top: 336,
              baseSize: const Size.square(42),
              child: Host4EmulatorAuxiliaryButton(
                asset: 'logo_group.svg',
                size: Size.square(42 * scale),
                onTap: widget.onMenuTap,
              ),
            ),
            hide,
          ],
        );
      },
    );
  }

  List<Widget> _controlWidgets(
    Widget Function({
      required String identifier,
      required double left,
      required double top,
      required Size baseSize,
      required Widget child,
    })
    positioned,
    double scale,
  ) {
    final specs = switch (widget.variant) {
      Host4EmulatorSiliconeLayoutVariant.modernSymmetric =>
        const <_ControlSpec>[
          _ControlSpec(_ControlKind.dpad, 66, 132, 'dpad_left'),
          _ControlSpec(_ControlKind.actions, 652, 132, 'action_cluster'),
          _ControlSpec(_ControlKind.stick, 231, 215, 'stick_left'),
          _ControlSpec(_ControlKind.stick, 486, 212, 'stick_right'),
        ],
      Host4EmulatorSiliconeLayoutVariant.modernAsymmetric =>
        const <_ControlSpec>[
          _ControlSpec(_ControlKind.stick, 66, 132, 'stick_left'),
          _ControlSpec(_ControlKind.actions, 652, 132, 'action_cluster'),
          _ControlSpec(_ControlKind.dpad, 231, 215, 'dpad_left'),
          _ControlSpec(_ControlKind.stick, 486, 212, 'stick_right'),
        ],
      Host4EmulatorSiliconeLayoutVariant.retroTraditional => <_ControlSpec>[
        _ControlSpec(
          _retroUsesStick ? _ControlKind.stick : _ControlKind.dpad,
          112,
          157,
          _retroUsesStick ? 'stick_left' : 'dpad_left',
        ),
        const _ControlSpec(_ControlKind.actions, 606, 157, 'action_cluster'),
      ],
      Host4EmulatorSiliconeLayoutVariant.silicone => const <_ControlSpec>[],
    };

    return <Widget>[
      for (final spec in specs)
        positioned(
          identifier: 'landscape.controls.${spec.identifier}',
          left: spec.left,
          top: spec.top,
          baseSize: const Size.square(126),
          child: switch (spec.kind) {
            _ControlKind.dpad => Host4EmulatorDPad(
              size: 126 * scale,
              semanticsIdentifier: 'landscape.controls.${spec.identifier}',
              onEvent: widget.onInput,
            ),
            _ControlKind.actions => _LandscapeActionCluster(
              scale: scale,
              onInput: widget.onInput,
            ),
            _ControlKind.stick => _LandscapeStick(
              scale: scale,
              label: spec.identifier == 'stick_right' ? 'R' : 'L',
              semanticsIdentifier: 'landscape.controls.${spec.identifier}',
              onInput: widget.onInput,
            ),
          },
        ),
    ];
  }

  List<Widget> _shoulderWidgets(
    Widget Function({
      required String identifier,
      required double left,
      required double top,
      required Size baseSize,
      required Widget child,
    })
    positioned,
    double scale,
  ) {
    const specs = <_ShoulderSpec>[
      _ShoulderSpec('l2', 'l', 110, 29, 'landscape_shoulder_l2.svg'),
      _ShoulderSpec('l1', 'l', 144.88, 63.65, 'landscape_shoulder_l1.svg'),
      _ShoulderSpec('r2', 'r', 646.88, 29, 'landscape_shoulder_r2.svg'),
      _ShoulderSpec('r1', 'r', 612, 63.65, 'landscape_shoulder_r1.svg'),
    ];
    return <Widget>[
      for (final spec in specs)
        positioned(
          identifier: spec.name == 'l1' || spec.name == 'r1'
              ? 'controls.${spec.input}'
              : 'landscape.controls.btn_${spec.name}',
          left: spec.left,
          top: spec.top,
          baseSize: const Size.square(67.882),
          child: Host4EmulatorAuxiliaryButton(
            asset: spec.asset,
            size: Size.square(67.882 * scale),
            input: spec.input,
            onEvent: widget.onInput,
          ),
        ),
      if (widget.variant ==
              Host4EmulatorSiliconeLayoutVariant.modernSymmetric ||
          widget.variant ==
              Host4EmulatorSiliconeLayoutVariant.modernAsymmetric) ...<Widget>[
        positioned(
          identifier: 'landscape.controls.btn_l3',
          left: 288,
          top: 49,
          baseSize: const Size(72, 36),
          child: Host4EmulatorAuxiliaryButton(
            asset: 'landscape_shoulder_l3.svg',
            size: Size(72 * scale, 36 * scale),
            input: 'l',
            onEvent: widget.onInput,
          ),
        ),
        positioned(
          identifier: 'landscape.controls.btn_r3',
          left: 484,
          top: 49,
          baseSize: const Size(72, 36),
          child: Host4EmulatorAuxiliaryButton(
            asset: 'landscape_shoulder_r3.svg',
            size: Size(72 * scale, 36 * scale),
            input: 'r',
            onEvent: widget.onInput,
          ),
        ),
      ],
    ];
  }
}

enum _ControlKind { dpad, actions, stick }

class _ControlSpec {
  const _ControlSpec(this.kind, this.left, this.top, this.identifier);

  final _ControlKind kind;
  final double left;
  final double top;
  final String identifier;
}

class _ShoulderSpec {
  const _ShoulderSpec(this.name, this.input, this.left, this.top, this.asset);

  final String name;
  final String input;
  final double left;
  final double top;
  final String asset;
}

class _LandscapeActionCluster extends StatelessWidget {
  const _LandscapeActionCluster({required this.scale, required this.onInput});

  final double scale;
  final ValueChanged<Host4EmulatorInputEvent> onInput;

  @override
  Widget build(BuildContext context) {
    final diameter = 37.8 * scale;
    final center = (126 / 2 - 37.8 / 2) * scale;
    final edge = (126 - 37.8) * scale;
    return SizedBox.square(
      dimension: 126 * scale,
      child: Stack(
        children: <Widget>[
          _button('x', 'X', center, 0, diameter),
          _button('y', 'Y', 0, center, diameter),
          _button('a', 'A', edge, center, diameter),
          _button('b', 'B', center, edge, diameter),
        ],
      ),
    );
  }

  Widget _button(
    String input,
    String label,
    double left,
    double top,
    double diameter,
  ) {
    return Positioned(
      left: left,
      top: top,
      child: KeyedSubtree(
        key: ValueKey<String>('controls.$input'),
        child: Host4EmulatorActionButton(
          input: input,
          label: label,
          diameter: diameter,
          onEvent: onInput,
        ),
      ),
    );
  }
}

class _LandscapeStick extends StatelessWidget {
  const _LandscapeStick({
    required this.scale,
    required this.label,
    required this.semanticsIdentifier,
    required this.onInput,
  });

  final double scale;
  final String label;
  final String semanticsIdentifier;
  final ValueChanged<Host4EmulatorInputEvent> onInput;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 126 * scale,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: CustomPaint(painter: _LandscapeStickPainter(label)),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: Host4EmulatorDPad(
                size: 126 * scale,
                semanticsIdentifier: semanticsIdentifier,
                onEvent: onInput,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LandscapeStickPainter extends CustomPainter {
  const _LandscapeStickPainter(this.label);

  final String label;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 126;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(
      center,
      60 * scale,
      Paint()
        ..color = const Color(0x33F1EDFD)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * scale,
    );
    canvas.drawCircle(
      center,
      30 * scale,
      Paint()..color = const Color(0x996A7691),
    );
    canvas.drawCircle(
      center,
      30 * scale,
      Paint()
        ..color = const Color(0xFF774FEF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.25 * scale,
    );
    final text = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: const Color(0xFFF1EDFD).withValues(alpha: 0.8),
          fontWeight: FontWeight.w900,
          fontSize: 18 * scale,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
  }

  @override
  bool shouldRepaint(covariant _LandscapeStickPainter oldDelegate) =>
      label != oldDelegate.label;
}

class _RetroModeToggle extends StatelessWidget {
  const _RetroModeToggle({
    required this.scale,
    required this.showStickIcon,
    required this.onTap,
  });

  final double scale;
  final bool showStickIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xA6FFFFFF),
        ),
        child: Center(
          child: SvgPicture.asset(
            'assets/controls/${showStickIcon ? 'ic_yaogan.svg' : 'ic_shizijian.svg'}',
            package: 'host4_flutter_emulator_ui',
            width: 24 * scale,
            height: 24 * scale,
          ),
        ),
      ),
    );
  }
}
