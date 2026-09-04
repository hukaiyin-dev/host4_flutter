import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../input/host4_emulator_input_event.dart';

class Host4EmulatorActionButton extends StatefulWidget {
  const Host4EmulatorActionButton({
    required this.input,
    required this.label,
    required this.diameter,
    required this.onEvent,
    super.key,
  });

  final String input;
  final String label;
  final double diameter;
  final ValueChanged<Host4EmulatorInputEvent> onEvent;

  @override
  State<Host4EmulatorActionButton> createState() =>
      _Host4EmulatorActionButtonState();
}

class _Host4EmulatorActionButtonState extends State<Host4EmulatorActionButton> {
  bool _pressed = false;

  void _down() {
    if (_pressed) return;
    setState(() => _pressed = true);
    HapticFeedback.mediumImpact();
    _send(Host4EmulatorInputEvent.phaseDown, 1);
  }

  void _up() {
    if (!_pressed) return;
    setState(() => _pressed = false);
    _send(Host4EmulatorInputEvent.phaseUp, 0);
  }

  void _send(String phase, double value) {
    widget.onEvent(
      Host4EmulatorInputEvent(
        input: widget.input,
        phase: phase,
        value: value,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        source: 'controls.${widget.input}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canvasSize = widget.diameter * 45 / 37.8;
    return Semantics(
      button: true,
      label: widget.label,
      identifier: 'controls.${widget.input}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _down(),
        onTapUp: (_) => _up(),
        onTapCancel: _up,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 60),
          opacity: _pressed ? 0.85 : 1,
          child: SizedBox.square(
            dimension: widget.diameter,
            child: OverflowBox(
              minWidth: 0,
              minHeight: 0,
              maxWidth: canvasSize,
              maxHeight: canvasSize,
              child: SvgPicture.asset(
                'assets/controls/btn_${widget.input}.svg',
                package: 'host4_flutter_emulator_ui',
                width: canvasSize,
                height: canvasSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
