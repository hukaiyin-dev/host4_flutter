import 'package:flutter/material.dart';
import 'package:host4_flutter_module_onboarding/host4_flutter_module_onboarding.dart';

import '../l10n/generated/app_localizations.dart';

const _storageKey = 'com.host4.demo.onboarding_demo_v1';

void pushOnboardingDemo(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => OnboardingFlow(
        storageKey: _storageKey,
        skipLabel: l10n.onboardingDemoSkip,
        onComplete: () {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.onboardingDemoCompleteMessage)),
          );
        },
        pages: _buildPages(l10n),
      ),
    ),
  );
}

List<OnboardingPageConfig> _buildPages(AppLocalizations l10n) {
  return [
    // Page 1: Welcome
    OnboardingPageConfig(
      title: l10n.onboardingP1Title,
      description: l10n.onboardingP1Desc,
      action: OnboardingPageAction(
        label: l10n.onboardingP1Action,
        onPressed: (_) async => true,
      ),
    ),

    // Page 2: Storage permission (simulated)
    OnboardingPageConfig(
      title: l10n.onboardingP2Title,
      description: l10n.onboardingP2Desc,
      action: OnboardingPageAction(
        label: l10n.onboardingP2Action,
        onPressed: (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 800));
          return true;
        },
      ),
    ),

    // Page 3: Choose data folder (simulated, cancellable)
    OnboardingPageConfig(
      title: l10n.onboardingP3Title,
      description: l10n.onboardingP3Desc,
      action: OnboardingPageAction(
        label: l10n.onboardingP3Action,
        onPressed: (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 600));
          // Simulate successful folder selection
          return true;
        },
      ),
    ),

    // Page 4: Choose ROMs folder (simulated)
    OnboardingPageConfig(
      title: l10n.onboardingP4Title,
      description: l10n.onboardingP4Desc,
      hint: l10n.onboardingP4Hint,
      action: OnboardingPageAction(
        label: l10n.onboardingP4Action,
        onPressed: (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 600));
          return true;
        },
      ),
    ),

    // Page 5: Create platform dirs (with secondary skip action)
    OnboardingPageConfig(
      title: l10n.onboardingP5Title,
      description: l10n.onboardingP5Desc,
      action: OnboardingPageAction(
        label: l10n.onboardingP5Action,
        onPressed: (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 1200));
          return true;
        },
      ),
      secondaryAction: OnboardingPageAction(
        label: l10n.onboardingP5Skip,
        onPressed: (_) async => true,
      ),
    ),

    // Page 6: Done
    OnboardingPageConfig(
      title: l10n.onboardingP6Title,
      description: l10n.onboardingP6Desc,
      hint: l10n.onboardingP6Hint,
      action: OnboardingPageAction(
        label: l10n.onboardingP6Action,
        onPressed: (_) async => true,
      ),
    ),
  ];
}
