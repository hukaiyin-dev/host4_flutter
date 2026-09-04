import 'package:flutter/widgets.dart';

class WebEmulatorSessionHost extends StatelessWidget {
  const WebEmulatorSessionHost({
    super.key,
    required this.romPicker,
    this.emulator,
  });

  final Widget romPicker;
  final Widget? emulator;

  @override
  Widget build(BuildContext context) => emulator ?? romPicker;
}
