import 'package:logger/logger.dart' as pkg;

import 'app_logger.dart';

/// Concrete [AppLogger] implementation backed by the `logger` package.
///
/// Filtering:
/// - In debug builds: `LogLevel.verbose` and up are printed.
/// - In release builds: only `warning` and above are printed
///   (perf + PII concerns). This is also where remote log shipping
///   would be added in Day 8+.
class LoggerAdapter implements AppLogger {
  LoggerAdapter({pkg.Logger? logger}) : _logger = logger ?? _default;

  static final pkg.Logger _default = pkg.Logger(
    filter: _AppLogFilter(),
    printer: pkg.PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 100,
      colors: true,
      printEmojis: false,
      dateTimeFormat: pkg.DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  final pkg.Logger _logger;

  @override
  void verbose(String message,
      {Object? error, StackTrace? stackTrace}) {
    _logger.t(message, error: error, stackTrace: stackTrace);
  }

  @override
  void debug(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  @override
  void info(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  @override
  void warning(String message,
      {Object? error, StackTrace? stackTrace}) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  @override
  void fatal(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}

class _AppLogFilter extends pkg.LogFilter {
  @override
  bool shouldLog(pkg.LogEvent event) {
    // `logger` reads `kReleaseMode` from development; we mirror that.
    if (kReleaseMode) {
      return event.level.index >= pkg.Level.warning.index;
    }
    return true;
  }
}
