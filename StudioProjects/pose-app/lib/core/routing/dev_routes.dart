import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../shared/widgets/gallery/design_system_gallery.dart';
import '../routing/route_paths.dart';

/// Adds dev-only routes (design-system gallery, playground, etc.)
/// to an existing route list. Only enabled in non-release builds.
List<RouteBase> buildDevRoutes() {
  if (kReleaseMode) return [];

  return [
    GoRoute(
      path: '/dev/gallery',
      builder: (_, __) => const DesignSystemGallery(),
    ),
    GoRoute(
      path: '/dev/playground',
      builder: (_, __) => const SplashScreen(), // placeholder
    ),
  ];
}

/// Wrap a screen builder with a custom transition.
Page<T> fadeThrough<T>({
  required Widget child,
  required LocalKey key,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeOutCubic).animate(animation),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
  );
}
