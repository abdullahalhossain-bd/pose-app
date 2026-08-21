import 'user.dart';

/// Result of a successful sign-in. Carries the user + the refreshable
/// auth token the data layer will store.
class AuthSession {
  const AuthSession({required this.user, required this.accessToken});

  final User user;
  final String accessToken;
}
