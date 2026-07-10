import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/presentation/providers/session_provider.dart';

/// Single-screen onboarding for the MVP. Day 8+ can split into a
/// multi-step pager once we have the brand assets.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = <_OnboardingPage>[
    _OnboardingPage(
      icon: Icons.camera_alt,
      title: 'Capture with intent',
      description:
      'A visual director in your pocket — frame, expose, and compose like a pro.',
    ),
    _OnboardingPage(
      icon: Icons.auto_awesome,
      title: 'AI-assisted guidance',
      description:
      'Real-time prompts help you fix composition, lighting, and pose.',
    ),
    _OnboardingPage(
      icon: Icons.history,
      title: 'Build your visual library',
      description:
      'Every shot you take feeds your personal photography intelligence.',
    ),
  ];

  Future<void> _finish() async {
    await ref.read(sessionProvider.notifier).markOnboardingComplete();
    if (!mounted) return;
    context.go(RoutePaths.login);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AppTextButton(
                  label: _page == _pages.length - 1 ? '' : 'Skip',
                  onPressed: _page == _pages.length - 1 ? null : _finish,
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            p.icon,
                            size: 56,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                        const AppGap.lg(),
                        Text(
                          p.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const AppGap.sm(),
                        Text(
                          p.description,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(_pages.length, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        width: active ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? cs.primary
                              : cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  AppPrimaryButton(
                    label: _page == _pages.length - 1 ? 'Get started' : 'Next',
                    icon: _page == _pages.length - 1 ? null : Icons.arrow_forward,
                    onPressed: () {
                      if (_page == _pages.length - 1) {
                        _finish();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
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

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}