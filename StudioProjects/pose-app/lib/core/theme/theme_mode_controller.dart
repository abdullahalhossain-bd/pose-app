import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Persists the user's [ThemeMode] choice.
class ThemeModeController extends ChangeNotifier {
  ThemeModeController(this._prefs);

  final SharedPreferences _prefs;
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final raw = _prefs.getString(AppConstants.themeModeKey) ?? 'system';
    _mode = _parse(raw);
    _loaded = true;
    notifyListeners();
  }

  Future<void> set(ThemeMode mode) async {
    _mode = mode;
    await _prefs.setString(AppConstants.themeModeKey, _stringify(mode));
    notifyListeners();
  }

  static ThemeMode _parse(String s) => switch (s) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static String _stringify(ThemeMode m) => switch (m) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
}
