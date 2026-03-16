import 'package:flutter/material.dart';

class Host4PageScaffold extends StatelessWidget {
  const Host4PageScaffold({
    required this.title,
    required this.body,
    super.key,
    this.actions,
    this.useSafeArea = true,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final bool useSafeArea;

  @override
  Widget build(BuildContext context) {
    final content = useSafeArea ? SafeArea(child: body) : body;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      body: content,
    );
  }
}
