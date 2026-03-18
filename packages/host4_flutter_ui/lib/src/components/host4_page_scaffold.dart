import 'package:flutter/material.dart';

import '../foundation/theme/host4_theme_scope.dart';
import 'host4_background.dart';

class Host4PageScaffold extends StatelessWidget {
  const Host4PageScaffold({
    required this.body,
    super.key,
    this.useSafeArea = true,
    this.bottomNavigationBar,
  });

  final Widget body;
  final bool useSafeArea;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    // bottom: false — the tab bar handles its own safe area inset
    final content = useSafeArea ? SafeArea(bottom: false, child: body) : body;
    // Use pageBackground so iOS keyboard rounded-corner gutter shows the
    // correct color instead of the engine's default black window background.
    final backgroundColor = context.host4Theme.colors.pageBackground;
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Host4Background(child: content),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
