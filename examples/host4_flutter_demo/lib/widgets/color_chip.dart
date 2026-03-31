import 'package:flutter/widgets.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';

class ColorChip extends StatelessWidget {
  const ColorChip({
    required this.label,
    required this.color,
    required this.theme,
    super.key,
  });

  final String label;
  final Color color;
  final Host4RuntimeTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(theme.spacing.sm),
      decoration: BoxDecoration(
        color: theme.colors.surfaceElevated,
        borderRadius: BorderRadius.circular(theme.radius.md),
        border: Border.all(color: theme.colors.borderDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(theme.radius.sm),
            ),
          ),
          SizedBox(width: theme.spacing.sm),
          Text(
            label,
            style: theme.typography.caption.toTextStyle(
              theme.colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
