import 'package:flutter/widgets.dart';

class OnboardingPageAction {
  const OnboardingPageAction({
    required this.label,
    required this.onPressed,
  });

  final String label;

  /// Returns true to advance to the next page (or complete if last page).
  /// Returns false to stay on the current page (e.g. user cancelled a picker).
  final Future<bool> Function(BuildContext context) onPressed;
}
