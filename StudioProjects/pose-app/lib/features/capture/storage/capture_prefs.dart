import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/capture_config.dart';

/// Persisted user preferences for Auto Capture. Versioned schema so
/// future migrations don't break existing installs.
///
/// Storage convention: every field is stored under
/// `avd_capture_<field>` with a single `__version` integer tracking
/// schema evolution. Migrations live in [CapturePrefs.migrate].
@immutable
class CapturePrefs {
  const CapturePrefs({
    this.autoCaptureEnabled = false,
    this.countdownSeconds = 3,
    this.voicePromptsEnabled = false,
    this.vibrationEnabled = true,
    this.sensitivity = CaptureSensitivity.balanced,
    this.schemaVersion = currentSchemaVersion,
  });

  static const int currentSchemaVersion = 1;

  final bool autoCaptureEnabled;
  final int countdownSeconds;
  final bool voicePromptsEnabled;
  final bool vibrationEnabled;
  final CaptureSensitivity sensitivity;
  final int schemaVersion;

  CapturePrefs copyWith({
    bool? autoCaptureEnabled,
    int? countdownSeconds,
    bool? voicePromptsEnabled,
    bool? vibrationEnabled,
    CaptureSensitivity? sensitivity,
  }) {
    return CapturePrefs(
      autoCaptureEnabled: autoCaptureEnabled ?? this.autoCaptureEnabled,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      voicePromptsEnabled: voicePromptsEnabled ?? this.voicePromptsEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      sensitivity: sensitivity ?? this.sensitivity,
    );
  }

  static const _kPrefix = 'avd_capture_';
  static const _kVersion = '${_kPrefix}__schema_version';
  static const _kAuto = '${_kPrefix}auto_enabled';
  static const _kCountdown = '${_kPrefix}countdown_seconds';
  static const _kVoice = '${_kPrefix}voice_enabled';
  static const _kVibration = '${_kPrefix}vibration_enabled';
  static const _kSensitivity = '${_kPrefix}sensitivity';

  static Future<CapturePrefs> load(SharedPreferences prefs) async {
    final version = prefs.getInt(_kVersion) ?? 0;
    if (version < currentSchemaVersion) {
      await _migrate(prefs, version);
    }
    return CapturePrefs(
      autoCaptureEnabled: prefs.getBool(_kAuto) ?? false,
      countdownSeconds: prefs.getInt(_kCountdown) ?? 3,
      voicePromptsEnabled: prefs.getBool(_kVoice) ?? false,
      vibrationEnabled: prefs.getBool(_kVibration) ?? true,
      sensitivity: CaptureSensitivity
          .values[_prefsGetInt(prefs, _kSensitivity, 1)],
    );
  }

  Future<void> save(SharedPreferences prefs) async {
    await prefs.setInt(_kVersion, currentSchemaVersion);
    await prefs.setBool(_kAuto, autoCaptureEnabled);
    await prefs.setInt(_kCountdown, countdownSeconds);
    await prefs.setBool(_kVoice, voicePromptsEnabled);
    await prefs.setBool(_kVibration, vibrationEnabled);
    await prefs.setInt(_kSensitivity, sensitivity.index);
  }

  static int _prefsGetInt(
      SharedPreferences p, String key, int fallback) {
    final v = p.getInt(key);
    return v ?? fallback;
  }

  static Future<void> _migrate(SharedPreferences p, int fromVersion) async {
    // Forward-only migrations. Each step upgrades by one schema version.
    var v = fromVersion;
    while (v < currentSchemaVersion) {
      switch (v) {
        case 0:
          // v0 → v1: nothing to do — defaults are safe for new fields.
          break;
      }
      v++;
    }
    await p.setInt(_kVersion, currentSchemaVersion);
  }
}
