import 'package:flutter/material.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';

import '../model/onboarding_page_action.dart';
import '../model/onboarding_page_config.dart';
import 'onboarding_page_content.dart';

class OnboardingPageView extends StatelessWidget {
  const OnboardingPageView({
    required this.pages,
    required this.controller,
    required this.currentIndex,
    required this.onAction,
    required this.isLoading,
    super.key,
  });

  final List<OnboardingPageConfig> pages;
  final PageController controller;
  final int currentIndex;
  final void Function(OnboardingPageAction action) onAction;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: controller,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pages.length,
            itemBuilder: (context, index) {
              return OnboardingPageContent(
                config: pages[index],
                onAction: onAction,
                isLoading: isLoading,
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: theme.spacing.lg),
          child: _DotIndicator(
            total: pages.length,
            current: currentIndex,
          ),
        ),
      ],
    );
  }
}

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.total, required this.current});

  final int total;
  final int current;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final isActive = index <= current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.symmetric(horizontal: theme.spacing.xs / 2),
          width: isActive ? 16 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? theme.colors.brandPrimary
                : theme.colors.borderDefault,
            borderRadius: BorderRadius.circular(theme.radius.pill),
          ),
        );
      }),
    );
  }
}
