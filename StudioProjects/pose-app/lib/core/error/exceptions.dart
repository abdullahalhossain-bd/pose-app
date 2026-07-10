/// Base class for all app exceptions.
///
/// Exceptions are caught at the repository / use-case boundary and
/// converted to [Failure] objects. UI never sees exceptions.
abstract class AppException implements Exception {
  const AppException(this.message, {this.cause, this.stackTrace});

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause, super.stackTrace});
}

class ServerException extends AppException {
  const ServerException(
    super.message, {
    super.cause,
    super.stackTrace,
    this.statusCode,
  });

  final int? statusCode;
}

class CacheException extends AppException {
  const CacheException(super.message, {super.cause, super.stackTrace});
}

class ValidationException extends AppException {
  const ValidationException(
    super.message, {
    super.cause,
    super.stackTrace,
    this.errors = const {},
  });

  final Map<String, String> errors;
}

class AuthException extends AppException {
  const AuthException(super.message, {super.cause, super.stackTrace});
}

class PermissionException extends AppException {
  const PermissionException(super.message, {super.cause, super.stackTrace});
}

class UnexpectedException extends AppException {
  const UnexpectedException(super.message, {super.cause, super.stackTrace});
}
