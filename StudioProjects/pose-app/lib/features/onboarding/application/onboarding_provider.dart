import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/onboarding_state_service.dart';

final onboardingStateServiceProvider =
    Provider<OnboardingStateService>((ref) => OnboardingStateService());

/// Whether onboarding has already been completed — checked once, on
/// app start, to decide whether to show the onboarding flow or go
/// straight to the camera.
final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(onboardingStateServiceProvider);
  return service.isCompleted();
});
