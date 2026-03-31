import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_module_onboarding/src/storage/onboarding_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OnboardingStore.shouldShow', () {
    test('returns true when key has never been written', () async {
      expect(await OnboardingStore.shouldShow('test_key'), isTrue);
    });

    test('returns false after markShown is called', () async {
      await OnboardingStore.markShown('test_key');
      expect(await OnboardingStore.shouldShow('test_key'), isFalse);
    });

    test('different keys are independent', () async {
      await OnboardingStore.markShown('key_a');
      expect(await OnboardingStore.shouldShow('key_a'), isFalse);
      expect(await OnboardingStore.shouldShow('key_b'), isTrue);
    });
  });

  group('OnboardingStore.markShown', () {
    test('is idempotent', () async {
      await OnboardingStore.markShown('test_key');
      await OnboardingStore.markShown('test_key');
      expect(await OnboardingStore.shouldShow('test_key'), isFalse);
    });
  });
}
