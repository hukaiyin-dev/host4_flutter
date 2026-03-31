import 'package:flutter/material.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';

import '../model/onboarding_page_action.dart';
import '../model/onboarding_page_config.dart';

class OnboardingPageContent extends StatelessWidget {
  const OnboardingPageContent({
    required this.config,
    required this.onAction,
    required this.isLoading,
    super.key,
  });

  final OnboardingPageConfig config;

  /// Called when a button is tapped; passes the action to the parent.
  final void Function(OnboardingPageAction action) onAction;

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (config.contentBuilder != null) {
      return config.contentBuilder!(context);
    }

    final theme = context.host4Theme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        theme.spacing.page,
        theme.spacing.xl,
        theme.spacing.page,
        theme.spacing.page,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (config.imageAsset != null) ...[
            Center(
              child: Image.asset(
                config.imageAsset!,
                height: 160,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: theme.spacing.xl),
          ],
          Text(
            config.title,
            style: theme.typography.title.toTextStyle(theme.colors.textPrimary),
          ),
          SizedBox(height: theme.spacing.sm),
          Text(
            config.description,
            style: theme.typography.body.toTextStyle(theme.colors.textSecondary),
          ),
          const Spacer(),
          if (config.hint != null) ...[
            _HintRow(hint: config.hint!),
            SizedBox(height: theme.spacing.md),
          ],
          Host4Button(
            label: config.action.label,
            onPressed: isLoading ? null : () => onAction(config.action),
            variant: Host4ButtonVariant.primary,
            expanded: true,
          ),
          if (config.secondaryAction != null) ...[
            SizedBox(height: theme.spacing.sm),
            Host4Button(
              label: config.secondaryAction!.label,
              onPressed: isLoading ? null : () => onAction(config.secondaryAction!),
              variant: Host4ButtonVariant.ghost,
              expanded: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _HintRow extends StatelessWidget {
  const _HintRow({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '⚠',
          style: theme.typography.body.toTextStyle(theme.colors.warning),
        ),
        SizedBox(width: theme.spacing.xs),
        Expanded(
          child: Text(
            hint,
            style: theme.typography.caption.toTextStyle(theme.colors.textSecondary),
          ),
        ),
      ],
    );
  }
}
