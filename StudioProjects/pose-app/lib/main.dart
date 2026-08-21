import 'dart:io' show stderr;
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/di/providers.dart';

/// Zone-guarded entry point.
///
/// Bootstrap sequence:
/// 1. Bind framework-level error handlers.
/// 2. Initialize shared preferences (async).
/// 3. Override the corresponding Riverpod provider.
/// 4. Run the app inside a [ProviderContainer] (so we can read providers
///    from the platform-level error handler).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Framework-level errors (widget tree).
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  // Async errors that escape the widget tree. Initial pass just prints
  // to stderr; once the container is up we swap this for a logger-backed
  // version.
  PlatformDispatcher.instance.onError = (error, stack) {
    stderr.writeln('Unhandled platform error: $error\n$stack');
    return true;
  };

  final sharedPreferences = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sharedPreferences),
    ],
  );

  // Now that the container is alive, route uncaught errors through it.
  final logger = container.read(loggerProvider);
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.fatal('Unhandled platform error',
        error: error, stackTrace: stack);
    return true;
  };

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AppVisualDirectorApp(),
    ),
  );
}
