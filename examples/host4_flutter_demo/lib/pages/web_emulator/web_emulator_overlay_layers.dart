import 'package:flutter/widgets.dart';

class WebEmulatorOverlayLayers extends StatelessWidget {
  const WebEmulatorOverlayLayers({
    required this.game,
    required this.controls,
    this.overlay,
    this.activeMenuButton,
    super.key,
  });

  final Widget game;
  final Widget controls;
  final Widget? overlay;
  final Widget? activeMenuButton;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        game,
        controls,
        // ignore: use_null_aware_elements
        if (overlay case final overlay?) overlay,
        // ignore: use_null_aware_elements
        if (activeMenuButton case final activeMenuButton?) activeMenuButton,
      ],
    );
  }
}
