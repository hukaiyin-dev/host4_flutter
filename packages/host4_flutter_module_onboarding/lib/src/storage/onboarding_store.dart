import 'package:shared_preferences/shared_preferences.dart';

abstract final class OnboardingStore {
  static String _key(String storageKey) => 'host4_onboarding.$storageKey';

  static Future<bool> shouldShow(String storageKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(storageKey)) != true;
  }

  static Future<void> markShown(String storageKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(storageKey), true);
  }
}
