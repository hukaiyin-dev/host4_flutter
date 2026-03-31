import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_module_onboarding/host4_flutter_module_onboarding.dart';

void main() {
  group('OnboardingPageAction', () {
    testWidgets('onPressed returning true signals advance', (tester) async {
      final action = OnboardingPageAction(
        label: 'Next',
        onPressed: (_) async => true,
      );

      late BuildContext capturedContext;
      await tester.pumpWidget(Builder(builder: (ctx) {
        capturedContext = ctx;
        return const SizedBox.shrink();
      }));

      expect(await action.onPressed(capturedContext), isTrue);
    });

    testWidgets('onPressed returning false signals stay', (tester) async {
      final action = OnboardingPageAction(
        label: 'Pick folder',
        onPressed: (_) async => false,
      );

      late BuildContext capturedContext;
      await tester.pumpWidget(Builder(builder: (ctx) {
        capturedContext = ctx;
        return const SizedBox.shrink();
      }));

      expect(await action.onPressed(capturedContext), isFalse);
    });
  });
}
