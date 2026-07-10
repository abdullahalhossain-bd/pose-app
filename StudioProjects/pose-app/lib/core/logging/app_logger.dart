import 'package:flutter/foundation.dart';

/// Severity levels for the app's logging facade.
enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
  fatal,
}

/// Abstract logging interface. The concrete implementation
/// ([LoggerAdapter]) can be swapped without touching call sites.
///
/// Why a facade? Because in production we will need:
///  - Console output (dev)
///  - File rotation (staging)
///  - Remote logging / Crashlytics (prod)
///
/// Using a single interface now means we swap implementations later
/// without refactoring call sites.
abstract class AppLogger {
  void verbose(String message, {Object? error, StackTrace? stackTrace});
  void debug(String message, {Object? error, StackTrace? stackTrace});
  void info(String message, {Object? error, StackTrace? stackTrace});
  void warning(String message, {Object? error, StackTrace? stackTrace});
  void error(String message, {Object? error, StackTrace? stackTrace});
  void fatal(String message, {Object? error, StackTrace? stackTrace});
}
