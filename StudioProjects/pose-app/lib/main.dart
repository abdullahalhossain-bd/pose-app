import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/camera/presentation/screens/camera_screen.dart';
import 'features/onboarding/application/onboarding_provider.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Locked to portrait: the pose coordinate pipeline (camera sensor →
  // normalized landmark space → guidance) does not yet compensate for
  // device rotation. Allowing landscape here without that compensation
  // would silently produce incorrect "move left/right" guidance whenever
  // the device is rotated. Revisit once rotation handling is implemented
  // and verified on a real device — see docs/P0_VERIFICATION_REPORT.md.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const ProviderScope(child: AiVisualDirectorApp()));
}

class AiVisualDirectorApp extends StatelessWidget {
  const AiVisualDirectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Visual Director',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const _RootGate(),
    );
  }
}

/// Decides between onboarding and the camera screen based on persisted
/// completion state. A `Consumer` rather than baking this into
/// `AiVisualDirectorApp` directly, so `MaterialApp`'s own build (theme,
/// title, etc) never depends on the async onboarding check.
class _RootGate extends ConsumerWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingCompleted = ref.watch(onboardingCompletedProvider);

    return onboardingCompleted.when(
      // While the persisted flag is loading, show the same loading
      // affordance the camera screen itself uses — no flash of the
      // wrong screen, no blank frame (spec §15).
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      ),
      // If reading the persisted flag fails for any reason, fail open
      // to the camera rather than trapping the user in onboarding they
      // may have already completed — onboarding is a one-time
      // explanation, not a gate that should ever block core
      // functionality.
      error: (_, __) => const CameraScreen(),
      data: (completed) {
        if (completed) return const CameraScreen();
        return OnboardingScreen(
          onDone: () => ref.invalidate(onboardingCompletedProvider),
        );
      },
    );
  }
}
