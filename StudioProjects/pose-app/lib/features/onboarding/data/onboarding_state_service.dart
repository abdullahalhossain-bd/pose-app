import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the user has completed (or explicitly skipped)
/// onboarding, across app launches. A single boolean flag — this is
/// deliberately not a versioned/multi-step persistence scheme, since
/// there's only one onboarding flow to track completion for right now.
class OnboardingStateService {
  static const _key = 'onboarding_completed_v1';

  Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  /// Exposed for a future "reset app" / debug setting — not currently
  /// wired to any UI, but trivial to hook up when personalization
  /// controls (P2, spec §12: "reset learned preferences") land, since
  /// onboarding-reset is a natural neighbor to that.
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
