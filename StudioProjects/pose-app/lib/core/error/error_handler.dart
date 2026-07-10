import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

import '../logging/app_logger.dart';
import 'exceptions.dart';
import 'failures.dart';

/// Centralized error handler.
///
/// Responsibilities:
/// 1. Convert thrown [AppException]s / unknown errors into [Failure]s.
/// 2. Route critical errors to logging + (in prod) crash reporting.
/// 3. Provide a single place to attach Crashlytics / Sentry later.
///
/// Usage in repositories / use-cases:
/// ```dart
/// Either<Failure, Result> doSomething() async {
///   try {
///     final r = await remoteDataSource.fetch();
///     return Right(r);
///   } catch (e, st) {
///     return Left(errorHandler.handle(e, st));
///   }
/// }
/// ```
class ErrorHandler {
  const ErrorHandler(this._logger);

  final AppLogger _logger;

  /// Converts any thrown object into a [Failure] and logs it.
  Failure handle(Object error, [StackTrace? stackTrace]) {
    final failure = _map(error, stackTrace);
    _report(failure, error, stackTrace);
    return failure;
  }

  /// Same as [handle] but for cases where you already know you want a
  /// specific [Failure] type — e.g. when a use-case validates input.
  Failure wrap(Failure failure) {
    _report(failure, failure.cause, failure.stackTrace);
    return failure;
  }

  Failure _map(Object error, StackTrace? stackTrace) {
    if (error is AppException) {
      return switch (error) {
        NetworkException() => NetworkFailure(
            message: error.message,
            cause: error,
            stackTrace: stackTrace,
          ),
        ServerException(:final statusCode) => ServerFailure(
            message: error.message,
            statusCode: statusCode,
            cause: error,
            stackTrace: stackTrace,
          ),
        CacheException() => CacheFailure(
            message: error.message,
            cause: error,
            stackTrace: stackTrace,
          ),
        ValidationException(:final errors) => ValidationFailure(
            message: error.message,
            errors: errors,
            cause: error,
            stackTrace: stackTrace,
          ),
        AuthException() => AuthFailure(
            message: error.message,
            cause: error,
            stackTrace: stackTrace,
          ),
        PermissionException() => PermissionFailure(
            message: error.message,
            cause: error,
            stackTrace: stackTrace,
          ),
        UnexpectedException() => UnexpectedFailure(
            message: error.message,
            cause: error,
            stackTrace: stackTrace,
          ),
      };
    }

    // Anything else — type errors, null checks, third-party exceptions.
    return UnexpectedFailure(
      message: error.toString(),
      cause: error,
      stackTrace: stackTrace,
    );
  }

  void _report(
    Failure failure,
    Object? error,
    StackTrace? stackTrace,
  ) {
    // In release mode, this is where Crashlytics.recordError would go.
    if (failure is UnexpectedFailure ||
        failure is ServerFailure ||
        failure is NetworkFailure) {
      _logger.error(
        failure.toString(),
        error: error,
        stackTrace: stackTrace,
      );
    } else {
      _logger.warning(failure.toString());
    }

    if (kReleaseMode) {
      // TODO(day-8+): wire up Firebase Crashlytics / Sentry here.
      // Crashlytics.instance.recordError(
      //   error ?? failure,
      //   stackTrace ?? StackTrace.current,
      //   reason: failure.code,
      // );
    }
  }
}
