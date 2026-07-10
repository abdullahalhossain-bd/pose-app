import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/auth_session.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Thin use-case wrappers around [AuthRepository].
///
/// Why bother? Two reasons:
/// 1. They give every entry point a name + a single responsibility —
///    easy to mock in tests, easy to extend later (analytics, audit
///    log, etc.).
/// 2. They keep the presentation layer free of the repository type
///    entirely — widgets only know about [Either].
class SignInUseCase {
  const SignInUseCase(this._repo);
  final AuthRepository _repo;

  Future<Either<Failure, AuthSession>> call({
    required String email,
    required String password,
  }) =>
      _repo.signIn(email: email, password: password);
}

class RegisterUseCase {
  const RegisterUseCase(this._repo);
  final AuthRepository _repo;

  Future<Either<Failure, AuthSession>> call({
    required String email,
    required String password,
  }) =>
      _repo.register(email: email, password: password);
}

class RequestPasswordResetUseCase {
  const RequestPasswordResetUseCase(this._repo);
  final AuthRepository _repo;

  Future<Either<Failure, void>> call(String email) =>
      _repo.requestPasswordReset(email);
}

class CompleteProfileUseCase {
  const CompleteProfileUseCase(this._repo);
  final AuthRepository _repo;

  Future<Either<Failure, User>> call({
    required String displayName,
    String? photoUrl,
  }) =>
      _repo.completeProfile(
        displayName: displayName,
        photoUrl: photoUrl,
      );
}

class RestoreSessionUseCase {
  const RestoreSessionUseCase(this._repo);
  final AuthRepository _repo;

  Future<Either<Failure, AuthSession>> call() => _repo.restoreSession();
}

class SignOutUseCase {
  const SignOutUseCase(this._repo);
  final AuthRepository _repo;

  Future<Either<Failure, void>> call() => _repo.signOut();
}
