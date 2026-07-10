import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/composition_config.dart';

/// পার্সিস্টেড ব্যবহারকারী প্রিফারেন্স যা কোন গ্রিড ওভারলে (বা একাধিক) প্রদর্শিত হবে
/// তা নিয়ন্ত্রণ করে।
@immutable
class CompositionPrefs {
  const CompositionPrefs({
    this.enabledGrid = GridOverlayType.none,
    this.showCompositionHints = true,
    this.schemaVersion = currentSchemaVersion,
  });

  static const int currentSchemaVersion = 1;

  final GridOverlayType enabledGrid;
  final bool showCompositionHints;
  final int schemaVersion;

  CompositionPrefs copyWith({
    GridOverlayType? enabledGrid,
    bool? showCompositionHints,
  }) {
    return CompositionPrefs(
      enabledGrid: enabledGrid ?? this.enabledGrid,
      showCompositionHints: showCompositionHints ?? this.showCompositionHints,
    );
  }

  static const _kPrefix = 'avd_composition_';
  static const _kVersion = '${_kPrefix}__schema_version';
  static const _kGrid = '${_kPrefix}grid_type';
  static const _kHints = '${_kPrefix}show_hints';

  static Future<CompositionPrefs> load(SharedPreferences prefs) async {
    final version = prefs.getInt(_kVersion) ?? 0;
    if (version < currentSchemaVersion) {
      await prefs.setInt(_kVersion, currentSchemaVersion);
    }
    return CompositionPrefs(
      enabledGrid: GridOverlayType
          .values[_prefsGetInt(prefs, _kGrid, 0)],
      showCompositionHints: prefs.getBool(_kHints) ?? true,
    );
  }

  Future<void> save(SharedPreferences prefs) async {
    await prefs.setInt(_kVersion, currentSchemaVersion);
    await prefs.setInt(_kGrid, enabledGrid.index);
    await prefs.setBool(_kHints, showCompositionHints);
  }

  static int _prefsGetInt(SharedPreferences p, String key, int fallback) {
    return p.getInt(key) ?? fallback;
  }
}
