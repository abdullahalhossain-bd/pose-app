import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../application/onboarding_provider.dart';

/// Minimal, three-slide onboarding — deliberately not a long tutorial
/// (spec Phase 8: "explain ONE thing... do not create a long
/// tutorial"). Each slide covers exactly one of the four things the
/// spec asks for: what the app does, how AI guidance works, that
/// capture is always manual right now (no Auto Capture exists yet in
/// this codebase — see docs/ROADMAP.md — so this slide correctly
/// doesn't claim one), and that processing is on-device.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    _SlideContent(
      icon: Icons.camera_alt_rounded,
      title: 'AI Visual Director',
      body: 'Helps you take better photos, on your own — no photographer needed.',
    ),
    _SlideContent(
      icon: Icons.navigation_rounded,
      title: 'Real-time guidance',
      body: 'Point the camera at yourself and follow simple, one-at-a-time '
          'directions — move left, step back, hold still.',
    ),
    _SlideContent(
      icon: Icons.touch_app_rounded,
      title: 'You\'re always in control',
      body: 'The shutter button is always yours to press. The AI guides — '
          'it never takes the photo for you.',
    ),
    _SlideContent(
      icon: Icons.lock_outline_rounded,
      title: 'Processing stays on your device',
      body: 'Camera analysis happens entirely on your phone. Nothing is '
          'uploaded, and photos are only saved when you capture them.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardingStateServiceProvider).markCompleted();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _page == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) => _SlideView(slide: _slides[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.accent
                              : AppColors.textDisabled,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLastPage
                          ? _finish
                          : () => _controller.nextPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              ),
                      child: Text(isLastPage ? 'Get started' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideContent {
  final IconData icon;
  final String title;
  final String body;

  const _SlideContent({required this.icon, required this.title, required this.body});
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _SlideContent slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: AppColors.surfaceRaised,
              shape: BoxShape.circle,
            ),
            child: Icon(slide.icon, size: 36, color: AppColors.accent),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            slide.title,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            slide.body,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
