import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../data/datasources/token_store.dart';
import '../../data/repositories/local_auth_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';
import 'session_provider.dart';

/// Auth-layer Riverpod providers.
///
/// Keep them here (not in `core/di`) so the auth feature is
/// self-contained — you can drop the entire `features/auth/` folder
/// into another project and only need to wire `authRepositoryProvider`.

final tokenStoreProvider = Provider<TokenStore>((ref) {
  return TokenStore(ref.watch(sharedPreferencesProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return LocalAuthRepository(
    tokenStore: ref.watch(tokenStoreProvider),
    errorHandler: ref.watch(errorHandlerProvider),
  );
});

final signInUseCaseProvider = Provider<SignInUseCase>(
  (ref) => SignInUseCase(ref.watch(authRepositoryProvider)),
);

final registerUseCaseProvider = Provider<RegisterUseCase>(
  (ref) => RegisterUseCase(ref.watch(authRepositoryProvider)),
);

final requestPasswordResetUseCaseProvider =
    Provider<RequestPasswordResetUseCase>(
  (ref) => RequestPasswordResetUseCase(ref.watch(authRepositoryProvider)),
);

final completeProfileUseCaseProvider = Provider<CompleteProfileUseCase>(
  (ref) => CompleteProfileUseCase(ref.watch(authRepositoryProvider)),
);

final restoreSessionUseCaseProvider = Provider<RestoreSessionUseCase>(
  (ref) => RestoreSessionUseCase(ref.watch(authRepositoryProvider)),
);

final signOutUseCaseProvider = Provider<SignOutUseCase>(
  (ref) => SignOutUseCase(ref.watch(authRepositoryProvider)),
);

/// Whether the device has a cached session that the splash screen
/// can restore without forcing the user through login again.
final hasCachedSessionProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  final result = await repo.restoreSession();
  return result.isRight();
});
