import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../auth/presentation/providers/session_provider.dart';

/// Initial loading + session-restore decision point.
///
/// Flow:
/// 1. Show branded splash.
/// 2. Wait for [SessionNotifier] to hydrate from SharedPreferences.
/// 3. Decide next route.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) => _routeAfterMinDelay());
  }

  Future<void> _routeAfterMinDelay() async {
    // Minimum splash duration for branding (800ms).
    await Future<void>.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    final session = ref.read(sessionProvider);

    final String next;
    if (!session.isOnboarded) {
      next = RoutePaths.onboarding;
    } else if (!session.isAuthenticated) {
      next = RoutePaths.login;
    } else if (!session.hasProfile) {
      next = RoutePaths.profileSetup;
    } else {
      next = RoutePaths.home;
    }

    if (mounted) context.go(next);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: 64,
                  color: cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'AI Visual Director',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Photography Intelligence Platform',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: cs.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
