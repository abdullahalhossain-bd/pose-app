import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart'; // ✅ 4x ../ (আগে ৩টা ছিল)
import '../../../../core/di/providers.dart';             // ✅ 4x ../ (আগে ২টা ছিল)

/// Immutable snapshot of the current authentication + onboarding state.
@immutable
class SessionState {
  const SessionState({
    this.isAuthenticated = false,
    this.isOnboarded = false,
    this.hasProfile = false,
    this.userId,
    this.email,
  });

  final bool isAuthenticated;
  final bool isOnboarded;
  final bool hasProfile;
  final String? userId;
  final String? email;

  SessionState copyWith({
    bool? isAuthenticated,
    bool? isOnboarded,
    bool? hasProfile,
    String? userId,
    String? email,
  }) {
    return SessionState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      hasProfile: hasProfile ?? this.hasProfile,
      userId: userId ?? this.userId,
      email: email ?? this.email,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SessionState &&
              runtimeType == other.runtimeType &&
              isAuthenticated == other.isAuthenticated &&
              isOnboarded == other.isOnboarded &&
              hasProfile == other.hasProfile &&
              userId == other.userId &&
              email == other.email;

  @override
  int get hashCode => Object.hash(
    isAuthenticated,
    isOnboarded,
    hasProfile,
    userId,
    email,
  );
}

class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier(this._prefs) : super(const SessionState()) {
    _hydrate();
  }

  final SharedPreferences _prefs;

  void _hydrate() {
    state = SessionState(
      isAuthenticated:
      _prefs.getBool('${AppConstants.sessionKey}_authed') ?? false,
      isOnboarded:
      _prefs.getBool(AppConstants.onboardingCompleteKey) ?? false,
      hasProfile:
      _prefs.getBool('${AppConstants.sessionKey}_profile') ?? false,
      userId: _prefs.getString('${AppConstants.sessionKey}_uid'),
      email: _prefs.getString('${AppConstants.sessionKey}_email'),
    );
  }

  Future<void> markOnboardingComplete() async {
    await _prefs.setBool(AppConstants.onboardingCompleteKey, true);
    state = state.copyWith(isOnboarded: true);
  }

  Future<void> signIn({required String userId, required String email}) async {
    await _prefs.setBool('${AppConstants.sessionKey}_authed', true);
    await _prefs.setString('${AppConstants.sessionKey}_uid', userId);
    await _prefs.setString('${AppConstants.sessionKey}_email', email);
    state = state.copyWith(isAuthenticated: true, userId: userId, email: email);
  }

  Future<void> markProfileComplete() async {
    await _prefs.setBool('${AppConstants.sessionKey}_profile', true);
    state = state.copyWith(hasProfile: true);
  }

  Future<void> signOut() async {
    await _prefs.remove('${AppConstants.sessionKey}_authed');
    await _prefs.remove('${AppConstants.sessionKey}_uid');
    await _prefs.remove('${AppConstants.sessionKey}_email');
    await _prefs.remove('${AppConstants.sessionKey}_profile');
    state = const SessionState(isOnboarded: true);
  }
}

final sessionProvider =
StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  return SessionNotifier(ref.watch(sharedPreferencesProvider));
});