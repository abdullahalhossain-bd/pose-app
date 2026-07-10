/// Top-level failure categories used across the app.
///
/// Each [Failure] is a value object that carries a user-presentable
/// message and an optional technical cause. UI layers map failures to
/// widgets (snackbar, error state, etc.) without ever inspecting the
/// underlying exception type.
sealed class Failure {
  const Failure({
    required this.message,
    this.code,
    this.cause,
    this.stackTrace,
  });

  final String message;
  final String? code;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType(code: $code): $message';
}

/// Network / connectivity issues.
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection. Please check your network.',
    super.code = 'network',
    super.cause,
    super.stackTrace,
  });
}

/// Server returned 4xx/5xx.
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code = 'server',
    super.cause,
    super.stackTrace,
    this.statusCode,
  });

  final int? statusCode;
}

/// Local cache / storage failed.
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Failed to read local data.',
    super.code = 'cache',
    super.cause,
    super.stackTrace,
  });
}

/// Input validation failed.
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code = 'validation',
    super.cause,
    super.stackTrace,
    this.errors = const {},
  });

  /// Field-level errors, e.g. `{'email': 'Invalid email'}`.
  final Map<String, String> errors;
}

/// User not authenticated or session expired.
class AuthFailure extends Failure {
  const AuthFailure({
    super.message = 'Your session has expired. Please sign in again.',
    super.code = 'auth',
    super.cause,
    super.stackTrace,
  });
}

/// User explicitly cancelled an action.
class CancelledFailure extends Failure {
  const CancelledFailure({
    super.message = 'Action cancelled.',
    super.code = 'cancelled',
    super.cause,
    super.stackTrace,
  });
}

/// Permission denied (camera, location, etc.).
class PermissionFailure extends Failure {
  const PermissionFailure({
    required super.message,
    super.code = 'permission',
    super.cause,
    super.stackTrace,
  });
}

/// Catch-all for unexpected errors. Should never reach UI in production.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    super.message = 'Something went wrong. Please try again.',
    super.code = 'unexpected',
    super.cause,
    super.stackTrace,
  });
}
