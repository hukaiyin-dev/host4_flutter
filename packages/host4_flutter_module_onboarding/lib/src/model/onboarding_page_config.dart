import 'package:flutter/widgets.dart';

import 'onboarding_page_action.dart';

class OnboardingPageConfig {
  const OnboardingPageConfig({
    required this.title,
    required this.description,
    required this.action,
    this.hint,
    this.secondaryAction,
    this.imageAsset,
    this.contentBuilder,
  });

  final String title;
  final String description;

  /// Primary button — required.
  final OnboardingPageAction action;

  /// Optional ⚠ warning/info text shown above the buttons.
  final String? hint;

  /// Optional secondary button (e.g. "Skip this step").
  final OnboardingPageAction? secondaryAction;

  /// Optional image asset path, e.g. 'assets/onboarding/welcome.png'.
  final String? imageAsset;

  /// Fully overrides the default page layout.
  /// title / description / hint / imageAsset are still available to use.
  final WidgetBuilder? contentBuilder;
}
