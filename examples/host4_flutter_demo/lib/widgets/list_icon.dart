import 'package:flutter/widgets.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';

class ListIcon extends StatelessWidget {
  const ListIcon({required this.icon, required this.color, super.key});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(theme.radius.md),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
