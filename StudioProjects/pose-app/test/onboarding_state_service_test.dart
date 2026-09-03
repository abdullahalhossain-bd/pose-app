import 'package:flutter_test/flutter_test.dart';
import 'package:ai_visual_director/features/onboarding/data/onboarding_state_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingStateService', () {
    test('isCompleted() is false on first launch (nothing persisted yet)', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OnboardingStateService();
      expect(await service.isCompleted(), false);
    });

    test('markCompleted() persists across a new service instance (simulates relaunch)', () async {
      SharedPreferences.setMockInitialValues({});
      await OnboardingStateService().markCompleted();

      // A fresh instance, same underlying (mocked) storage — this is
      // the actual behavior that matters: does the flag survive a
      // relaunch, not just persist within one object's lifetime.
      final secondLaunch = OnboardingStateService();
      expect(await secondLaunch.isCompleted(), true);
    });

    test('reset() clears a previously-completed flag', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OnboardingStateService();
      await service.markCompleted();
      expect(await service.isCompleted(), true);

      await service.reset();
      expect(await service.isCompleted(), false);
    });
  });
}
