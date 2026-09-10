import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Same A-confirm / B-back contract on every emulator overlay.
class Host4EmulatorUiShortcuts extends StatelessWidget {
  const Host4EmulatorUiShortcuts({required this.child, required this.onBack, this.onContinue, super.key});
  final Widget child;
  final VoidCallback onBack;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) => Focus(
    onKeyEvent: (_, event) {
      final key = event.logicalKey;
      final back = key == LogicalKeyboardKey.keyB || key == LogicalKeyboardKey.gameButtonB || key == LogicalKeyboardKey.escape;
      final start = key == LogicalKeyboardKey.gameButtonStart;
      if (!back && !start) return KeyEventResult.ignored;
      if (event is KeyDownEvent) { (start ? onContinue ?? onBack : onBack)(); }
      return KeyEventResult.handled;
    },
    child: Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyA): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
      },
      child: child,
    ),
  );
}
