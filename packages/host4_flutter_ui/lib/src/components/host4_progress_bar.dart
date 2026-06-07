import 'package:flutter/material.dart';

import '../foundation/theme/host4_runtime_theme.dart';
import '../foundation/theme/host4_theme_scope.dart';

enum Host4ProgressBarVariant { normal, success, warning, error }

class Host4ProgressBar extends StatelessWidget {
  const Host4ProgressBar({
    required this.value,
    super.key,
    this.variant = Host4ProgressBarVariant.normal,
  });

  /// Progress value between 0.0 and 1.0. Null shows an indeterminate bar.
  final double? value;
  final Host4ProgressBarVariant variant;

  Color _fillColor(Host4ProgressBarComponentTokens tokens) => switch (variant) {
    Host4ProgressBarVariant.success => tokens.fillSuccess,
    Host4ProgressBarVariant.warning => tokens.fillWarning,
    Host4ProgressBarVariant.error => tokens.fillError,
    _ => tokens.fill,
  };

  @override
  Widget build(BuildContext context) {
    final tokens = context.host4Theme.components.progressBar;
    final fill = _fillColor(tokens);

    return ClipRRect(
      borderRadius: BorderRadius.circular(tokens.radius),
      child: SizedBox(
        height: tokens.height,
        child: LinearProgressIndicator(
          value: value,
          backgroundColor: tokens.track,
          valueColor: AlwaysStoppedAnimation<Color>(fill),
          minHeight: tokens.height,
        ),
      ),
    );
  }
}
