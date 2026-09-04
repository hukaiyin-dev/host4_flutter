import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../input/host4_emulator_input_event.dart';

class Host4EmulatorAuxiliaryButton extends StatefulWidget {
  const Host4EmulatorAuxiliaryButton({
    required this.asset,
    required this.size,
    this.input,
    this.onEvent,
    this.onTap,
    super.key,
  });

  final String asset;
  final Size size;
  final String? input;
  final ValueChanged<Host4EmulatorInputEvent>? onEvent;
  final VoidCallback? onTap;

  @override
  State<Host4EmulatorAuxiliaryButton> createState() =>
      _Host4EmulatorAuxiliaryButtonState();
}

class _Host4EmulatorAuxiliaryButtonState
    extends State<Host4EmulatorAuxiliaryButton> {
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
    final input = widget.input;
    final onEvent = widget.onEvent;
    if (input == null || onEvent == null) return;
    onEvent(
      Host4EmulatorInputEvent(
        input: input,
        phase: phase,
        value: value,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        source: 'controls.$input',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _down(),
      onTapUp: (_) => _up(),
      onTapCancel: _up,
      onTap: widget.onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 60),
        opacity: _pressed ? 0.85 : 1,
        child: SvgPicture.asset(
          'assets/controls/${widget.asset}',
          package: 'host4_flutter_emulator_ui',
          width: widget.size.width,
          height: widget.size.height,
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}
