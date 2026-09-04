import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../input/host4_emulator_input_event.dart';

class Host4EmulatorDPad extends StatefulWidget {
  const Host4EmulatorDPad({
    required this.size,
    required this.onEvent,
    this.semanticsIdentifier = 'controls.dpad',
    super.key,
  });

  final double size;
  final ValueChanged<Host4EmulatorInputEvent> onEvent;
  final String semanticsIdentifier;

  @override
  State<Host4EmulatorDPad> createState() => _Host4EmulatorDPadState();
}

class _Host4EmulatorDPadState extends State<Host4EmulatorDPad>
    with TickerProviderStateMixin {
  final Map<int, Set<String>> _pointerInputs = <int, Set<String>>{};
  late final Map<String, AnimationController> _animations;

  @override
  void initState() {
    super.initState();
    _animations = <String, AnimationController>{
      for (final input in <String>['up', 'down', 'left', 'right'])
        input: AnimationController(
          duration: const Duration(milliseconds: 60),
          vsync: this,
        ),
    };
  }

  @override
  void dispose() {
    for (final animation in _animations.values) {
      animation.dispose();
    }
    super.dispose();
  }

  void _updatePointer(int pointer, Offset localPosition) {
    final next = host4EmulatorDPadInputsAt(
      localPosition,
      widget.size,
      widget.size,
    );
    final previous = _pointerInputs[pointer] ?? const <String>{};
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final input in previous.difference(next)) {
      widget.onEvent(
        Host4EmulatorInputEvent(
          input: input,
          phase: Host4EmulatorInputEvent.phaseUp,
          value: 0,
          timestamp: now,
          source: widget.semanticsIdentifier,
        ),
      );
    }
    final activated = next.difference(previous);
    for (final input in activated) {
      widget.onEvent(
        Host4EmulatorInputEvent(
          input: input,
          phase: Host4EmulatorInputEvent.phaseDown,
          timestamp: now,
          source: widget.semanticsIdentifier,
        ),
      );
    }
    if (activated.isNotEmpty) HapticFeedback.mediumImpact();
    _pointerInputs[pointer] = next;
    _syncHighlights();
  }

  void _clearPointer(int pointer) {
    final previous = _pointerInputs.remove(pointer) ?? const <String>{};
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final input in previous) {
      widget.onEvent(
        Host4EmulatorInputEvent(
          input: input,
          phase: Host4EmulatorInputEvent.phaseUp,
          value: 0,
          timestamp: now,
          source: widget.semanticsIdentifier,
        ),
      );
    }
    _syncHighlights();
  }

  void _syncHighlights() {
    final pressed = <String>{};
    for (final inputs in _pointerInputs.values) {
      pressed.addAll(inputs);
    }
    for (final entry in _animations.entries) {
      if (pressed.contains(entry.key)) {
        entry.value.forward();
      } else {
        entry.value.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: Semantics(
        container: true,
        enabled: true,
        identifier: widget.semanticsIdentifier,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: IgnorePointer(
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    _arm('up', true, Alignment.topCenter),
                    _arm('down', true, Alignment.bottomCenter),
                    _arm('left', false, Alignment.centerLeft),
                    _arm('right', false, Alignment.centerRight),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (event) =>
                    _updatePointer(event.pointer, event.localPosition),
                onPointerMove: (event) =>
                    _updatePointer(event.pointer, event.localPosition),
                onPointerUp: (event) => _clearPointer(event.pointer),
                onPointerCancel: (event) => _clearPointer(event.pointer),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _arm(String input, bool vertical, Alignment alignment) {
    final scale = widget.size / 126;
    final width = (vertical ? 44.0 : 45.0) * scale;
    final height = (vertical ? 45.0 : 44.0) * scale;
    return AnimatedBuilder(
      animation: _animations[input]!,
      child: SvgPicture.asset(
        'assets/controls/dpad_$input.svg',
        package: 'host4_flutter_emulator_ui',
        width: width,
        height: height,
      ),
      builder: (context, child) => Align(
        alignment: alignment,
        child: Opacity(
          opacity: 1 - 0.15 * _animations[input]!.value,
          child: child,
        ),
      ),
    );
  }
}

@visibleForTesting
Set<String> host4EmulatorDPadInputsAt(
  Offset local,
  double width,
  double height,
) {
  const divisor = 3.0;
  final top = Rect.fromLTWH(0, 0, width, height / divisor);
  final bottom = Rect.fromLTWH(
    0,
    height * (divisor - 1) / divisor,
    width,
    height / divisor,
  );
  final left = Rect.fromLTWH(0, 0, width / divisor, height);
  final right = Rect.fromLTWH(
    width * (divisor - 1) / divisor,
    0,
    width / divisor,
    height,
  );
  return <String>{
    if (top.contains(local)) 'up',
    if (bottom.contains(local)) 'down',
    if (left.contains(local)) 'left',
    if (right.contains(local)) 'right',
  };
}
