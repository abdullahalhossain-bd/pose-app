import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/providers.dart';
import 'core/theme/app_theme.dart';

/// Root widget. Builds the [MaterialApp.router] with the app's theme
/// system, persisted theme mode, and GoRouter.
///
/// Side-effect-free except for reading providers; all bootstrap work
/// happens in `main.dart`.
class AppVisualDirectorApp extends ConsumerWidget {
  const AppVisualDirectorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeControllerProvider).mode;

    return MaterialApp.router(
      title: config.appName,
      debugShowCheckedModeBanner: !config.isProduction,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        // Apply text-scaling bounds so users with very high DPI settings
        // don't break our dense layouts.
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.4,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
