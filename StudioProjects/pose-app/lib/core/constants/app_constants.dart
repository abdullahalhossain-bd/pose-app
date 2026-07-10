/// Top-level application constants.
///
/// Centralized so no magic values are scattered across the codebase.
/// Anything user-configurable belongs in `AppConfig`, not here.
class AppConstants {
  const AppConstants._();

  /// Storage key prefixes. Always namespace to avoid collisions.
  static const String storagePrefix = 'avd_';
  static const String sessionKey = '${storagePrefix}session';
  static const String onboardingCompleteKey =
      '${storagePrefix}onboarding_complete';
  static const String themeModeKey = '${storagePrefix}theme_mode';

  /// Animation durations (Material 3 motion tokens).
  static const Duration durationShort = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 300);
  static const Duration durationLong = Duration(milliseconds: 450);

  /// UI spacing scale — kept here for non-widget code that needs raw values.
  /// In widgets, use `AppSpacing` from the theme layer instead.
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double spacingXxl = 48;

  /// Camera defaults (used by Day 5 camera module).
  static const double defaultZoom = 1.0;
  static const double minZoom = 1.0;
  static const double maxZoom = 8.0;
  static const double gridLineOpacity = 0.45;
}
