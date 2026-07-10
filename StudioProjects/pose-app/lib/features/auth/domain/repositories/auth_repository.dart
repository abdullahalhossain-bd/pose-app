import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/auth_session.dart';
import '../entities/user.dart';

/// Auth repository contract.
///
/// Domain layer defines it; data layer implements it. UI / use-cases
/// only ever see this interface so swapping implementations (mock →
/// REST → REST + biometric) is local to the data layer.
abstract class AuthRepository {
  /// Sends a magic link / OTP to [email].
  Future<Either<Failure, void>> requestPasswordReset(String email);

  /// Signs the user in with email + password.
  Future<Either<Failure, AuthSession>> signIn({
    required String email,
    required String password,
  });

  /// Registers a new account.
  Future<Either<Failure, AuthSession>> register({
    required String email,
    required String password,
  });

  /// Completes the user's profile after first sign-in.
  Future<Either<Failure, User>> completeProfile({
    required String displayName,
    String? photoUrl,
  });

  /// Restores a previously-cached session, if any.
  Future<Either<Failure, AuthSession>> restoreSession();

  /// Clears the current session.
  Future<Either<Failure, void>> signOut();

  /// Streams the current [User] (or `null` when signed out).
  Stream<User?> watchUser();
}
