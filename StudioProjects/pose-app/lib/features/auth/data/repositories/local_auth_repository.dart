import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/token_store.dart';

/// Local-only implementation of [AuthRepository].
///
/// Day 1-7: no backend yet. This stub validates email format, fakes a
/// "password >= 8 chars" rule, generates a pseudo-token, and persists
/// the session via [TokenStore]. Day 8+ will replace this with a real
/// REST-backed repository — the domain layer won't change.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository({
    required this.tokenStore,
    required this.errorHandler,
  });

  final TokenStore tokenStore;
  final ErrorHandler errorHandler;

  @override
  Future<Either<Failure, AuthSession>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      if (!_isValidEmail(email)) {
        throw const ValidationException(
          'Enter a valid email',
          errors: {'email': 'Enter a valid email'},
        );
      }
      if (password.length < 8) {
        throw const ValidationException(
          'Password must be at least 8 characters',
          errors: {'password': 'At least 8 characters'},
        );
      }

      // Simulate latency.
      await Future<void>.delayed(const Duration(milliseconds: 600));

      final user = User(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        createdAt: DateTime.now(),
      );

      await tokenStore.saveTokens(
        accessToken: 'mock-access-${user.id}',
        refreshToken: 'mock-refresh-${user.id}',
      );
      await tokenStore.saveUser(uid: user.id, email: user.email);

      return Right(AuthSession(
        user: user,
        accessToken: tokenStore.accessToken!,
      ));
    } catch (e, st) {
      return Left(errorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, AuthSession>> register({
    required String email,
    required String password,
  }) async {
    // For the mock, register behaves identically to sign-in.
    return signIn(email: email, password: password);
  }

  @override
  Future<Either<Failure, void>> requestPasswordReset(String email) async {
    try {
      if (!_isValidEmail(email)) {
        throw const ValidationException('Enter a valid email');
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return const Right(null);
    } catch (e, st) {
      return Left(errorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, User>> completeProfile({
    required String displayName,
    String? photoUrl,
  }) async {
    try {
      if (displayName.trim().isEmpty) {
        throw const ValidationException('Display name is required');
      }
      await Future<void>.delayed(const Duration(milliseconds: 400));
      final uid = tokenStore.userId;
      final email = tokenStore.email;
      if (uid == null || email == null) {
        throw const AuthException('No active session to update.');
      }
      await tokenStore.saveUser(
        uid: uid,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
      );
      return Right(User(
        id: uid,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
      ));
    } catch (e, st) {
      return Left(errorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, AuthSession>> restoreSession() async {
    try {
      final token = tokenStore.accessToken;
      final uid = tokenStore.userId;
      if (token == null || uid == null) {
        return Left(AuthFailure(message: 'No cached session.'));
      }
      return Right(AuthSession(
        user: User(
          id: uid,
          email: tokenStore.email ?? '',
          displayName: tokenStore.displayName,
          photoUrl: tokenStore.photoUrl,
        ),
        accessToken: token,
      ));
    } catch (e, st) {
      return Left(errorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await tokenStore.clear();
      return const Right(null);
    } catch (e, st) {
      return Left(errorHandler.handle(e, st));
    }
  }

  @override
  Stream<User?> watchUser() {
    // Local impl doesn't support live updates — Day 8+ REST impl will.
    return const Stream.empty();
  }

  bool _isValidEmail(String s) => RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      ).hasMatch(s.trim());
}
