import 'package:flutter/material.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';

class DebugRow extends StatelessWidget {
  const DebugRow({
    required this.label,
    required this.value,
    required this.theme,
    super.key,
  });

  final String label;
  final String value;
  final Host4RuntimeTheme theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: theme.spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 148,
            child: Text(
              label,
              style: theme.typography.caption.toTextStyle(
                theme.colors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.typography.caption.toTextStyle(
                theme.colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
