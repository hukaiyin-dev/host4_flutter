import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../input/host4_emulator_input_event.dart';
import 'host4_emulator_silicone_layout.dart';

enum Host4EmulatorSiliconePadActionVisual { round, direction }

class Host4EmulatorSiliconePadActionBinding {
  const Host4EmulatorSiliconePadActionBinding({
    required this.slot,
    required this.inputName,
    required this.label,
    required this.semanticsIdentifier,
    this.visual = Host4EmulatorSiliconePadActionVisual.round,
    this.visualInputName,
  });

  final Host4EmulatorSiliconePadSlot slot;
  final String inputName;
  final String label;
  final String semanticsIdentifier;
  final Host4EmulatorSiliconePadActionVisual visual;
  final String? visualInputName;
}

class Host4EmulatorSiliconePadSmallBinding {
  const Host4EmulatorSiliconePadSmallBinding({
    required this.slot,
    required this.inputName,
    required this.label,
    required this.semanticsIdentifier,
  });

  final Host4EmulatorSiliconePadSlot slot;
  final String inputName;
  final String label;
  final String semanticsIdentifier;
}

class Host4EmulatorSiliconePadBinding {
  const Host4EmulatorSiliconePadBinding({
    required this.side,
    required this.dpadIdentifier,
    required this.actions,
    this.dpadAliasIdentifier,
    this.actionClusterIdentifier,
    this.actionDirectionDisplayQuarterTurns = 0,
    this.dpadDisplayQuarterTurns = 0,
    this.dpadInputQuarterTurns = 0,
    this.innerTop,
    this.innerBottom,
  });

  final Host4EmulatorSiliconePadSide side;
  final String dpadIdentifier;
  final String? dpadAliasIdentifier;
  final String? actionClusterIdentifier;
  final int actionDirectionDisplayQuarterTurns;
  final int dpadDisplayQuarterTurns;
  final int dpadInputQuarterTurns;
  final List<Host4EmulatorSiliconePadActionBinding> actions;
  final Host4EmulatorSiliconePadSmallBinding? innerTop;
  final Host4EmulatorSiliconePadSmallBinding? innerBottom;
}

class Host4EmulatorSiliconePad extends StatelessWidget {
  const Host4EmulatorSiliconePad({
    required this.layout,
    required this.binding,
    required this.onEvent,
    this.offset = Offset.zero,
    super.key,
  });

  final Host4EmulatorSiliconeResolvedLayout layout;
  final Host4EmulatorSiliconePadBinding binding;
  final ValueChanged<Host4EmulatorInputEvent> onEvent;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    final Rect padBounds = layout.padBounds[binding.side]!;
    final List<Widget> children = <Widget>[
      if (binding.actionClusterIdentifier case final String identifier)
        _positionAlias(identifier, _actionClusterBounds()),
      _positionSlot(
        Host4EmulatorSiliconePadSlot.dpad,
        _semanticAlias(
          binding.dpadAliasIdentifier,
          Semantics(
            key: ValueKey<String>(binding.dpadIdentifier),
            container: true,
            identifier: binding.dpadIdentifier,
            child: _DPadHotZones(
              bounds: _slot(Host4EmulatorSiliconePadSlot.dpad).hitRect,
              up: _slot(Host4EmulatorSiliconePadSlot.dpadUp),
              down: _slot(Host4EmulatorSiliconePadSlot.dpadDown),
              left: _slot(Host4EmulatorSiliconePadSlot.dpadLeft),
              right: _slot(Host4EmulatorSiliconePadSlot.dpadRight),
              source: binding.dpadIdentifier,
              displayQuarterTurns: binding.dpadDisplayQuarterTurns,
              inputQuarterTurns: binding.dpadInputQuarterTurns,
              onEvent: onEvent,
            ),
          ),
        ),
        useHitRect: true,
      ),
      for (final Host4EmulatorSiliconePadActionBinding action
          in binding.actions)
        _positionSlot(
          action.slot,
          _buttonHitTarget(
            control: _slot(action.slot),
            inputName: action.inputName,
            semanticsIdentifier: action.semanticsIdentifier,
            label: action.label,
            visual: switch (action.visual) {
              Host4EmulatorSiliconePadActionVisual.round => null,
              Host4EmulatorSiliconePadActionVisual.direction =>
                _DirectionalActionButtonVisual(
                  inputName: _rotatedDirectionName(
                    action.visualInputName ??
                        _directionNameForSlot(action.slot),
                    binding.actionDirectionDisplayQuarterTurns,
                  ),
                ),
            },
          ),
          useHitRect: true,
        ),
      if (binding.innerTop
          case final Host4EmulatorSiliconePadSmallBinding top)
        _smallButton(top),
      if (binding.innerBottom
          case final Host4EmulatorSiliconePadSmallBinding bottom)
        _smallButton(bottom),
    ];
    return _positionPad(
      padBounds,
      SizedBox.fromSize(
        size: padBounds.size,
        child: Stack(clipBehavior: Clip.none, children: children),
      ),
    );
  }

  Positioned _smallButton(Host4EmulatorSiliconePadSmallBinding binding) {
    final Host4EmulatorSiliconeResolvedControl control = _slot(binding.slot);
    return _positionSlot(
      binding.slot,
      _buttonHitTarget(
        control: control,
        inputName: binding.inputName,
        semanticsIdentifier: binding.semanticsIdentifier,
        label: binding.label,
        visual: _SmallButtonVisual(label: binding.label),
      ),
      useHitRect: true,
    );
  }

  Widget _buttonHitTarget({
    required Host4EmulatorSiliconeResolvedControl control,
    required String inputName,
    required String semanticsIdentifier,
    required String label,
    Widget? visual,
  }) {
    return Semantics(
      key: ValueKey<String>(semanticsIdentifier),
      container: true,
      enabled: true,
      identifier: semanticsIdentifier,
      label: label,
      child: _PressableInput(
        source: semanticsIdentifier,
        inputName: inputName,
        onEvent: onEvent,
        child: _centeredVisual(
          control: control,
          child: visual ?? _RoundButtonVisual(inputName: inputName),
        ),
      ),
    );
  }

  Widget _centeredVisual({
    required Host4EmulatorSiliconeResolvedControl control,
    required Widget child,
  }) {
    return SizedBox.fromSize(
      size: control.hitRect.size,
      child: Center(
        child: SizedBox.fromSize(
          size: control.visualSize,
          child: ExcludeSemantics(child: IgnorePointer(child: child)),
        ),
      ),
    );
  }

  Positioned _positionSlot(
    Host4EmulatorSiliconePadSlot slot,
    Widget child, {
    required bool useHitRect,
  }) {
    final Host4EmulatorSiliconeResolvedControl control = _slot(slot);
    return _positionRect(
      useHitRect ? control.hitRect : control.visualRect,
      child,
    );
  }

  Positioned _positionAlias(String identifier, Rect rect) {
    return _positionRect(
      rect,
      IgnorePointer(
        child: Semantics(
          key: ValueKey<String>(identifier),
          container: true,
          identifier: identifier,
          child: SizedBox.fromSize(size: rect.size),
        ),
      ),
    );
  }

  Positioned _positionPad(Rect rect, Widget child) {
    return Positioned(
      left: rect.left + offset.dx,
      top: rect.top + offset.dy,
      child: child,
    );
  }

  Positioned _positionRect(Rect rect, Widget child) {
    final Rect localRect =
        rect.shift(-layout.padBounds[binding.side]!.topLeft);
    return Positioned.fromRect(rect: localRect, child: child);
  }

  Widget _semanticAlias(String? identifier, Widget child) {
    if (identifier == null) return child;
    return Semantics(
      key: ValueKey<String>(identifier),
      container: true,
      identifier: identifier,
      child: child,
    );
  }

  Rect _actionClusterBounds() {
    Rect? bounds;
    for (final Host4EmulatorSiliconePadActionBinding action
        in binding.actions) {
      final Rect rect = _slot(action.slot).hitRect;
      bounds = bounds == null ? rect : bounds.expandToInclude(rect);
    }
    return bounds ?? Rect.zero;
  }

  Host4EmulatorSiliconeResolvedControl _slot(
    Host4EmulatorSiliconePadSlot slot,
  ) {
    return layout.slot(binding.side, slot);
  }

  static String _directionNameForSlot(Host4EmulatorSiliconePadSlot slot) {
    return switch (slot) {
      Host4EmulatorSiliconePadSlot.actionTop => 'up',
      Host4EmulatorSiliconePadSlot.actionBottom => 'down',
      Host4EmulatorSiliconePadSlot.actionLeft => 'left',
      Host4EmulatorSiliconePadSlot.actionRight => 'right',
      _ => throw StateError('Unsupported directional action slot: $slot'),
    };
  }
}

class _PressableInput extends StatefulWidget {
  const _PressableInput({
    required this.source,
    required this.inputName,
    required this.onEvent,
    required this.child,
  });

  final String source;
  final String inputName;
  final ValueChanged<Host4EmulatorInputEvent> onEvent;
  final Widget child;

  @override
  State<_PressableInput> createState() => _PressableInputState();
}

class _PressableInputState extends State<_PressableInput> {
  bool _pressed = false;

  void _send(String phase, double value) {
    widget.onEvent(
      Host4EmulatorInputEvent(
        input: widget.inputName,
        phase: phase,
        value: value,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        source: widget.source,
      ),
    );
  }

  void _down() {
    if (_pressed) return;
    setState(() => _pressed = true);
    HapticFeedback.mediumImpact();
    _send(Host4EmulatorInputEvent.phaseDown, 1.0);
  }

  void _up() {
    if (!_pressed) return;
    setState(() => _pressed = false);
    _send(Host4EmulatorInputEvent.phaseUp, 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _down(),
      onTapUp: (_) => _up(),
      onTapCancel: _up,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 60),
        opacity: _pressed ? 0.85 : 1.0,
        child: widget.child,
      ),
    );
  }
}

class _DPadHotZones extends StatefulWidget {
  const _DPadHotZones({
    required this.bounds,
    required this.up,
    required this.down,
    required this.left,
    required this.right,
    required this.source,
    required this.displayQuarterTurns,
    required this.inputQuarterTurns,
    required this.onEvent,
  });

  final Rect bounds;
  final Host4EmulatorSiliconeResolvedControl up;
  final Host4EmulatorSiliconeResolvedControl down;
  final Host4EmulatorSiliconeResolvedControl left;
  final Host4EmulatorSiliconeResolvedControl right;
  final String source;
  final int displayQuarterTurns;
  final int inputQuarterTurns;
  final ValueChanged<Host4EmulatorInputEvent> onEvent;

  @override
  State<_DPadHotZones> createState() => _DPadHotZonesState();
}

class _DPadHotZonesState extends State<_DPadHotZones> {
  static const List<String> _directionOrder = <String>[
    'up',
    'down',
    'left',
    'right',
  ];

  final Map<int, Offset> _activePointers = <int, Offset>{};
  Set<String> _pressedInputs = <String>{};
  late List<_DPadDirectionHitZone> _hitZones = _resolveHitZones();

  @override
  void didUpdateWidget(covariant _DPadHotZones oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bounds != widget.bounds ||
        oldWidget.up != widget.up ||
        oldWidget.down != widget.down ||
        oldWidget.left != widget.left ||
        oldWidget.right != widget.right ||
        oldWidget.inputQuarterTurns != widget.inputQuarterTurns) {
      _hitZones = _resolveHitZones();
    }
  }

  @override
  void dispose() {
    _releaseAll();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    _activePointers[event.pointer] = event.localPosition;
    _syncPressedInputs();
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_activePointers.containsKey(event.pointer)) return;
    if (_activePointers[event.pointer] == event.localPosition) return;
    _activePointers[event.pointer] = event.localPosition;
    _syncPressedInputs();
  }

  void _handlePointerUp(PointerUpEvent event) {
    _activePointers.remove(event.pointer);
    _syncPressedInputs();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _activePointers.remove(event.pointer);
    _syncPressedInputs();
  }

  void _syncPressedInputs() {
    final Set<String> next = <String>{};
    for (final Offset position in _activePointers.values) {
      next.addAll(_inputsAt(position));
    }
    for (final String input in _directionOrder) {
      if (next.contains(input) && !_pressedInputs.contains(input)) {
        HapticFeedback.mediumImpact();
        _send(input, Host4EmulatorInputEvent.phaseDown);
      }
    }
    for (final String input in _directionOrder) {
      if (_pressedInputs.contains(input) && !next.contains(input)) {
        _send(input, Host4EmulatorInputEvent.phaseUp);
      }
    }
    _pressedInputs = next;
  }

  void _releaseAll() {
    if (_pressedInputs.isNotEmpty) {
      for (final String input in _directionOrder) {
        if (_pressedInputs.contains(input)) {
          _send(input, Host4EmulatorInputEvent.phaseUp);
        }
      }
    }
    _activePointers.clear();
    _pressedInputs = <String>{};
  }

  Set<String> _inputsAt(Offset position) {
    final Set<String> inputs = <String>{};
    for (final _DPadDirectionHitZone zone in _hitZones) {
      if (zone.localRect.contains(position)) inputs.add(zone.inputName);
    }
    return inputs;
  }

  List<_DPadDirectionHitZone> _resolveHitZones() {
    _DPadDirectionHitZone zone(
      String inputName,
      Host4EmulatorSiliconeResolvedControl control,
    ) {
      return _DPadDirectionHitZone(
        inputName: _rotatedDirectionName(inputName, widget.inputQuarterTurns),
        localRect: control.hitRect.shift(-widget.bounds.topLeft),
      );
    }

    return <_DPadDirectionHitZone>[
      zone('up', widget.up),
      zone('down', widget.down),
      zone('left', widget.left),
      zone('right', widget.right),
    ];
  }

  void _send(String inputName, String phase) {
    widget.onEvent(
      Host4EmulatorInputEvent(
        input: inputName,
        phase: phase,
        value: phase == Host4EmulatorInputEvent.phaseUp ? 0 : 1,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        source: widget.source,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: SizedBox.fromSize(
        size: widget.bounds.size,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned.fill(
              child: ExcludeSemantics(
                child: IgnorePointer(
                  child: _DPadClusterVisual(
                    displayQuarterTurns: widget.displayQuarterTurns,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DPadDirectionHitZone {
  const _DPadDirectionHitZone({
    required this.inputName,
    required this.localRect,
  });

  final String inputName;
  final Rect localRect;
}

class _DPadClusterVisual extends StatelessWidget {
  const _DPadClusterVisual({required this.displayQuarterTurns});

  static const Size _verticalButtonSize = Size(46.98, 48.6);
  static const Size _horizontalButtonSize = Size(48.6, 46.98);
  static const Offset _upButtonCenter = Offset(65.25, 25);
  static const Offset _downButtonCenter = Offset(65.25, 105.5);
  static const Offset _leftButtonCenter = Offset(25, 65.25);
  static const Offset _rightButtonCenter = Offset(105.5, 65.25);

  final int displayQuarterTurns;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      child: RotatedBox(
        quarterTurns: displayQuarterTurns,
        child: SizedBox.square(
          dimension: 126,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              _button(
                center: _upButtonCenter,
                size: _verticalButtonSize,
                inputName: 'up',
              ),
              _button(
                center: _downButtonCenter,
                size: _verticalButtonSize,
                inputName: 'down',
              ),
              _button(
                center: _leftButtonCenter,
                size: _horizontalButtonSize,
                inputName: 'left',
              ),
              _button(
                center: _rightButtonCenter,
                size: _horizontalButtonSize,
                inputName: 'right',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _button({
    required Offset center,
    required Size size,
    required String inputName,
  }) {
    return Positioned(
      left: center.dx - size.width / 2,
      top: center.dy - size.height / 2,
      width: size.width,
      height: size.height,
      child: _DPadDirectionVisual(inputName: inputName),
    );
  }
}

String _rotatedDirectionName(String inputName, int quarterTurns) {
  const List<String> directions = <String>['up', 'right', 'down', 'left'];
  final int index = directions.indexOf(inputName);
  if (index < 0) {
    throw StateError('Unsupported dpad input: $inputName');
  }
  final int next = (index + quarterTurns) % directions.length;
  return directions[next < 0 ? next + directions.length : next];
}

class _RoundButtonVisual extends StatelessWidget {
  const _RoundButtonVisual({required this.inputName});

  final String inputName;

  String get _asset {
    return switch (inputName) {
      'a' => 'assets/controls/btn_a.svg',
      'b' => 'assets/controls/btn_b.svg',
      'x' => 'assets/controls/btn_x.svg',
      'y' => 'assets/controls/btn_y.svg',
      _ => throw StateError('Unsupported round button input: $inputName'),
    };
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double baseCircle = 37.8;
        const double baseCanvas = 45;
        const double baseOffset = 3.6;
        final double diameter = constraints.biggest.shortestSide;
        final double scale = diameter / baseCircle;
        final double svgSize = baseCanvas * scale;
        final double offset = -baseOffset * scale;
        return SizedBox.square(
          dimension: diameter,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned(
                left: offset,
                top: offset,
                child: SvgPicture.asset(
                  _asset,
                  package: 'host4_flutter_emulator_ui',
                  width: svgSize,
                  height: svgSize,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DPadDirectionVisual extends StatelessWidget {
  const _DPadDirectionVisual({required this.inputName});

  final String inputName;

  String get _asset {
    return switch (inputName) {
      'up' => 'assets/controls/dpad_up.svg',
      'down' => 'assets/controls/dpad_down.svg',
      'left' => 'assets/controls/dpad_left.svg',
      'right' => 'assets/controls/dpad_right.svg',
      _ => throw StateError('Unsupported dpad input: $inputName'),
    };
  }

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _asset,
      package: 'host4_flutter_emulator_ui',
      fit: BoxFit.fill,
    );
  }
}

class _DirectionalActionButtonVisual extends StatelessWidget {
  const _DirectionalActionButtonVisual({required this.inputName});

  final String inputName;

  String get _asset {
    return switch (inputName) {
      'up' => 'assets/controls/btn_direction_up.svg',
      'down' => 'assets/controls/btn_direction_down.svg',
      'left' => 'assets/controls/btn_direction_left.svg',
      'right' => 'assets/controls/btn_direction_right.svg',
      _ => throw StateError('Unsupported directional action input: $inputName'),
    };
  }

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _asset,
      package: 'host4_flutter_emulator_ui',
      fit: BoxFit.fill,
    );
  }
}

class _SmallButtonVisual extends StatelessWidget {
  const _SmallButtonVisual({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SmallButtonVisualPainter(label));
  }
}

/// Shoulder button with pill shape and text label, matching Delta's
/// `DeltaSmallButton(style: pillShoulder)`.
class Host4EmulatorSiliconeSmallButton extends StatelessWidget {
  const Host4EmulatorSiliconeSmallButton({
    required this.hitSize,
    required this.visualSize,
    required this.label,
    required this.inputName,
    this.onEvent,
    this.onTap,
    super.key,
  }) : assert(onEvent != null || onTap != null);

  final Size hitSize;
  final Size visualSize;
  final String label;
  final String inputName;
  final ValueChanged<Host4EmulatorInputEvent>? onEvent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final visual = CustomPaint(painter: _SmallButtonVisualPainter(label));
    final Widget inner;
    if (onEvent != null) {
      inner = _PressableInput(
        source: 'silicone.shoulder.$inputName',
        inputName: inputName,
        onEvent: onEvent!,
        child: visual,
      );
    } else {
      inner = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: visual,
      );
    }
    return SizedBox.fromSize(
      size: hitSize,
      child: Center(
        child: SizedBox.fromSize(size: visualSize, child: inner),
      ),
    );
  }
}

class _SmallButtonVisualPainter extends CustomPainter {
  const _SmallButtonVisualPainter(this.label);

  final String label;

  static const Color _fillColor = Color(0x996A7691);
  static const Color _strokeColor = Color(0xFF774FEF);
  static const Color _textColor = Color(0xFFF1EDFD);

  @override
  void paint(Canvas canvas, Size size) {
    const double strokeWidth = 1.5;
    if (size.width <= strokeWidth || size.height <= strokeWidth) return;
    final double radius = size.height / 2;
    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius - strokeWidth / 2),
    );
    canvas.drawRRect(rrect, Paint()..color = _fillColor);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = _strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: _textColor,
          fontWeight: FontWeight.w900,
          fontSize: _fitLabelFontSize(size, label),
          letterSpacing: 0.5,
          fontFamily: 'Roboto',
          fontFamilyFallback: const <String>['SF Pro Display'],
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '',
    )..layout(maxWidth: size.width);
    textPainter.paint(
      canvas,
      Offset(
        size.width / 2 - textPainter.width / 2,
        size.height / 2 - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _SmallButtonVisualPainter oldDelegate) =>
      label != oldDelegate.label;

  double _fitLabelFontSize(Size size, String text) {
    final double maxWidth = math.max(size.width - 4, 1);
    final double maxHeight = math.max(size.height - 4, 1);
    double fontSize = size.height * 0.5;
    while (fontSize > 7) {
      final TextPainter tester = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: fontSize,
            letterSpacing: 0.5,
            fontFamily: 'Roboto',
            fontFamilyFallback: const <String>['SF Pro Display'],
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      if (tester.width <= maxWidth && tester.height <= maxHeight) {
        return fontSize;
      }
      fontSize -= 0.5;
    }
    return 7;
  }
}
