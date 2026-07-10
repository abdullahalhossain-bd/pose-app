import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';

/// Persistent token store. Uses [SharedPreferences] for Day 1-7
/// scaffolding — Day 8+ will swap to flutter_secure_storage.
class TokenStore {
  TokenStore(this._prefs);
  final SharedPreferences _prefs;

  static const _kAccessToken = '${AppConstants.storagePrefix}access_token';
  static const _kRefreshToken = '${AppConstants.storagePrefix}refresh_token';
  static const _kUid = '${AppConstants.sessionKey}_uid';
  static const _kEmail = '${AppConstants.sessionKey}_email';
  static const _kDisplayName = '${AppConstants.sessionKey}_display_name';
  static const _kPhotoUrl = '${AppConstants.sessionKey}_photo_url';

  String? get accessToken => _prefs.getString(_kAccessToken);
  String? get refreshToken => _prefs.getString(_kRefreshToken);
  String? get userId => _prefs.getString(_kUid);
  String? get email => _prefs.getString(_kEmail);
  String? get displayName => _prefs.getString(_kDisplayName);
  String? get photoUrl => _prefs.getString(_kPhotoUrl);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _prefs.setString(_kAccessToken, accessToken);
    await _prefs.setString(_kRefreshToken, refreshToken);
  }

  Future<void> saveUser({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    await _prefs.setString(_kUid, uid);
    await _prefs.setString(_kEmail, email);
    if (displayName != null) {
      await _prefs.setString(_kDisplayName, displayName);
    }
    if (photoUrl != null) {
      await _prefs.setString(_kPhotoUrl, photoUrl);
    }
  }

  Future<void> clear() async {
    await _prefs.remove(_kAccessToken);
    await _prefs.remove(_kRefreshToken);
    await _prefs.remove(_kUid);
    await _prefs.remove(_kEmail);
    await _prefs.remove(_kDisplayName);
    await _prefs.remove(_kPhotoUrl);
  }

  @visibleForTesting
  Map<String, String> debugSnapshot() => {
        'uid': userId ?? '',
        'email': email ?? '',
        'displayName': displayName ?? '',
        'photoUrl': photoUrl ?? '',
        'accessToken': accessToken ?? '',
        'refreshToken': refreshToken ?? '',
      };
}
