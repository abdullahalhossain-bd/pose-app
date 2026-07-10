import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../error/error_handler.dart';
import '../logging/app_logger.dart';
import '../logging/logger_adapter.dart';
import '../routing/app_router.dart';
import '../theme/theme_mode_controller.dart';
import 'package:go_router/go_router.dart';

/// Composition root. All cross-cutting dependencies are declared here.
///
/// Feature providers live under `features/<feature>/presentation/providers`
/// and depend on these core providers as needed.
///
/// Why centralize? Because Riverpod's graph is implicit; having one
/// file that lists the cross-cutting providers makes the dependency
/// story obvious during code review.
final class CoreProviders {
  const CoreProviders._();

  static final Provider<AppConfig> appConfigProvider =
  Provider<AppConfig>((ref) {
    return AppConfig.load();
  });

  static final Provider<AppLogger> loggerProvider =
  Provider<AppLogger>((ref) {
    final logger = LoggerAdapter();
    // LoggerAdapter wraps package:logger's Logger which has no
    // close() -- nothing to dispose. Hook left here for future
    // implementations that own resources (file handles, sockets).
    ref.onDispose(() {});
    return logger;
  });

  static final Provider<ErrorHandler> errorHandlerProvider =
  Provider<ErrorHandler>((ref) {
    return ErrorHandler(ref.watch(loggerProvider));
  });

  /// SharedPreferences is async-initialized in `main.dart` via
  /// `ProviderScope.override`. Consumers just read this provider.
  static final Provider<SharedPreferences> sharedPreferencesProvider =
  Provider<SharedPreferences>((ref) {
    throw UnimplementedError(
      'sharedPreferencesProvider must be overridden in main() '
          'after SharedPreferences.getInstance() completes.',
    );
  });

  static final Provider<GoRouter> goRouterProvider =
  Provider<GoRouter>((ref) {
    final router = buildAppRouter(ref);
    ref.onDispose(() => router.dispose());
    return router;
  });

  static final ChangeNotifierProvider<ThemeModeController>
  themeModeControllerProvider =
  ChangeNotifierProvider<ThemeModeController>((ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    final controller = ThemeModeController(prefs);
    controller.load();
    return controller;
  });
}

/// Convenience re-exports so consumers can write
/// `import 'package:ai_visual_director/core/di/providers.dart';`
/// and reach everything.
final appConfigProvider = CoreProviders.appConfigProvider;
final loggerProvider = CoreProviders.loggerProvider;
final errorHandlerProvider = CoreProviders.errorHandlerProvider;
final sharedPreferencesProvider = CoreProviders.sharedPreferencesProvider;
final goRouterProvider = CoreProviders.goRouterProvider;
final themeModeControllerProvider =
    CoreProviders.themeModeControllerProvider;