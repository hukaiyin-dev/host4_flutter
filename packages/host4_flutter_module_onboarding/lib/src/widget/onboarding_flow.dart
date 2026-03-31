import 'package:flutter/material.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';

import '../model/onboarding_page_action.dart';
import '../model/onboarding_page_config.dart';
import '../storage/onboarding_store.dart';
import 'onboarding_page_view.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({
    required this.pages,
    required this.storageKey,
    required this.onComplete,
    this.skipLabel,
    super.key,
  }) : assert(pages.length > 0, 'pages must not be empty');

  final List<OnboardingPageConfig> pages;

  /// Unique key for persisting whether this flow has been shown.
  /// Recommended format: 'com.example.app.onboarding_v1'
  final String storageKey;

  /// Called after the last page completes or the global skip button is tapped.
  /// The storageKey is written before this callback fires.
  final VoidCallback onComplete;

  /// Label for the global skip button in the top-right corner.
  /// Pass null to hide the button (forced onboarding).
  final String? skipLabel;

  /// Returns true if this flow has not yet been marked as shown.
  /// Use this at app startup to decide whether to push [OnboardingFlow].
  /// For settings re-entry, push directly without checking.
  static Future<bool> shouldShow(String storageKey) =>
      OnboardingStore.shouldShow(storageKey);

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  late final PageController _pageController;
  int _currentIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleAction(OnboardingPageAction action) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final shouldAdvance = await action.onPressed(context);
      if (!mounted) return;
      if (!shouldAdvance) {
        setState(() => _isLoading = false);
        return;
      }

      final isLastPage = _currentIndex == widget.pages.length - 1;
      if (isLastPage) {
        await _complete();
      } else {
        setState(() {
          _currentIndex++;
          _isLoading = false;
        });
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
      rethrow;
    }
  }

  Future<void> _complete() async {
    await OnboardingStore.markShown(widget.storageKey);
    if (!mounted) return;
    widget.onComplete();
  }

  Future<void> _skip() async {
    await _complete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: theme.colors.pageBackground,
      body: Stack(
        children: [
          OnboardingPageView(
            pages: widget.pages,
            controller: _pageController,
            currentIndex: _currentIndex,
            onAction: _handleAction,
            isLoading: _isLoading,
          ),
          if (widget.skipLabel != null)
            Positioned(
              top: topInset + theme.spacing.sm,
              right: theme.spacing.page,
              child: TextButton(
                onPressed: _isLoading ? null : _skip,
                child: Text(
                  widget.skipLabel!,
                  style: theme.typography.label.toTextStyle(
                    theme.colors.textSecondary,
                  ),
                ),
              ),
            ),
          if (_isLoading)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.transparent,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
