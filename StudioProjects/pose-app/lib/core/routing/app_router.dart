import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/session_provider.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/profile_setup_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/camera/presentation/screens/camera_screen.dart';
import '../../features/home/presentation/screens/home_shell_screen.dart';
import '../../features/home/presentation/screens/main_home_screen.dart';
import '../../features/home/presentation/screens/profile_screen.dart';
import '../../features/home/presentation/screens/search_screen.dart';
import '../../features/home/presentation/screens/settings_screen.dart';
import '../../features/home/presentation/screens/history_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../routing/route_names.dart';
import '../routing/route_paths.dart';

/// Single source of truth for app navigation.
///
/// Architecture:
/// - `redirect` implements the auth state machine (splash → onboarding
///   → auth → profile setup → home).
/// - Each feature owns its screens; this file only wires them up.
/// - StatefulShellRoute is used for the bottom-nav so nested tabs
///   preserve their own back stacks (Day 4).
GoRouter buildAppRouter(Ref ref) {
  return GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: !kReleaseMode,
    redirect: (context, state) => _guard(ref, state),
    routes: [
      GoRoute(
        name: RouteNames.splash,
        path: RoutePaths.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        name: RouteNames.onboarding,
        path: RoutePaths.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        name: RouteNames.login,
        path: RoutePaths.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        name: RouteNames.register,
        path: RoutePaths.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        name: RouteNames.forgotPassword,
        path: RoutePaths.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        name: RouteNames.profileSetup,
        path: RoutePaths.profileSetup,
        builder: (_, __) => const ProfileSetupScreen(),
      ),

      // Bottom-nav shell (Day 4)
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) =>
            HomeShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: RouteNames.home,
                path: RoutePaths.home,
                builder: (_, __) => const MainHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: RouteNames.search,
                path: RoutePaths.search,
                builder: (_, __) => const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: RouteNames.history,
                path: RoutePaths.history,
                builder: (_, __) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: RouteNames.settings,
                path: RoutePaths.settings,
                builder: (_, __) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        name: RouteNames.profile,
        path: RoutePaths.profile,
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        name: RouteNames.camera,
        path: RoutePaths.camera,
        builder: (_, __) => const CameraScreen(),
      ),
    ],
  );
}

/// Auth / onboarding guard. Decides where to send the user based on
/// the current [SessionState].
String? _guard(Ref ref, GoRouterState state) {
  final session = ref.read(sessionProvider);
  final path = state.matchedLocation;

  // Allow the splash + onboarding screens to be reached at any time —
  // the splash screen itself drives the initial redirect.
  if (path == RoutePaths.splash) return null;

  final isAuthed = session.isAuthenticated;
  final isOnboarded = session.isOnboarded;
  final hasProfile = session.hasProfile;

  // Public routes reachable while not authenticated.
  final publicRoutes = {
    RoutePaths.login,
    RoutePaths.register,
    RoutePaths.forgotPassword,
    RoutePaths.onboarding,
  };

  if (!isOnboarded && path != RoutePaths.onboarding) {
    return RoutePaths.onboarding;
  }
  if (!isAuthed && !publicRoutes.contains(path)) {
    return RoutePaths.login;
  }
  if (isAuthed && !hasProfile && path != RoutePaths.profileSetup) {
    return RoutePaths.profileSetup;
  }
  if (isAuthed && hasProfile && publicRoutes.contains(path)) {
    return RoutePaths.home;
  }
  return null;
}
