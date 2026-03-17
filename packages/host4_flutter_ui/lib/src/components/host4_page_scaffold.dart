import 'package:flutter/material.dart';

import 'host4_background.dart';

class Host4PageScaffold extends StatelessWidget {
  const Host4PageScaffold({
    required this.body,
    super.key,
    this.useSafeArea = true,
  });

  final Widget body;
  final bool useSafeArea;

  @override
  Widget build(BuildContext context) {
    final content = useSafeArea ? SafeArea(child: body) : body;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Host4Background(child: content),
    );
  }
}
