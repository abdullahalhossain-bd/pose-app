import 'package:ai_visual_director/features/auth/data/datasources/token_store.dart';
import 'package:ai_visual_director/features/auth/data/repositories/local_auth_repository.dart';
import 'package:ai_visual_director/core/error/error_handler.dart';
import 'package:ai_visual_director/core/logging/logger_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late final LocalAuthRepository repo;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = LocalAuthRepository(
      tokenStore: TokenStore(prefs),
      errorHandler: ErrorHandler(LoggerAdapter()),
    );
  });

  group('LocalAuthRepository', () {
    test('signIn rejects invalid email', () async {
      final r = await repo.signIn(email: 'bad', password: 'password1A');
      expect(r.isLeft(), true);
      r.fold(
        (f) => expect(f.code, 'validation'),
        (_) => fail('Should have failed'),
      );
    });

    test('signIn rejects short password', () async {
      final r = await repo.signIn(email: 'a@b.com', password: 'short');
      expect(r.isLeft(), true);
    });

    test('signIn accepts valid creds and persists session', () async {
      final r = await repo.signIn(email: 'a@b.com', password: 'password1A');
      expect(r.isRight(), true);
    });

    test('restoreSession returns Left after signOut', () async {
      await repo.signOut();
      final r = await repo.restoreSession();
      expect(r.isLeft(), true);
    });
  });
}
