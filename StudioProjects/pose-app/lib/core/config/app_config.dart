/// The environment (flavor) the app is running under.
///
/// Determined at build/run time via `--dart-define=ENV=<value>`
/// (see `AppConfig.load` in `app_config.dart`).
enum AppEnv {
  dev,
  staging,
  prod;

  /// Parses a string (e.g. from `--dart-define=ENV=prod`) into an [AppEnv].
  /// Falls back to [AppEnv.dev] if the value is unrecognized or empty.
  static AppEnv parse(String value) {
    switch (value.toLowerCase().trim()) {
      case 'prod':
      case 'production':
        return AppEnv.prod;
      case 'staging':
      case 'stage':
        return AppEnv.staging;
      case 'dev':
      case 'development':
      default:
        return AppEnv.dev;
    }
  }

  /// Whether verbose logging should be enabled by default for this env.
  bool get enablesLogging => this != AppEnv.prod;

  /// Short label useful for display/debug purposes.
  String get label => switch (this) {
    AppEnv.dev => 'Development',
    AppEnv.staging => 'Staging',
    AppEnv.prod => 'Production',
  };

  @override
  String toString() => name;
}

/// Application-level configuration.
///
/// Resolved at startup from `--dart-define` flags and the bundled
/// `.env` files. Exposed via Riverpod (`appConfigProvider`).
class AppConfig {
  const AppConfig({
    required this.env,
    this.apiBaseUrl = '',
    this.sentryDsn = '',
    this.showDebugOverlay = false,
  });

  /// Build an [AppConfig] from `--dart-define` flags.
  ///
  /// Recognized keys:
  /// - `ENV`            → [AppEnv] (dev/staging/prod)
  /// - `API_BASE_URL`   → backend base URL
  /// - `SENTRY_DSN`     → Sentry / Crashlytics DSN (optional)
  /// - `SHOW_DEBUG_HUD` → 'true' / 'false'
  factory AppConfig.load() {
    const env = String.fromEnvironment('ENV', defaultValue: 'dev');
    const apiUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    const sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');
    const debugHud =
        String.fromEnvironment('SHOW_DEBUG_HUD', defaultValue: 'false');

    return AppConfig(
      env: AppEnv.parse(env),
      apiBaseUrl: apiUrl,
      sentryDsn: sentryDsn,
      showDebugOverlay: debugHud.toLowerCase() == 'true',
    );
  }

  final AppEnv env;
  final String apiBaseUrl;
  final String sentryDsn;
  final bool showDebugOverlay;

  bool get isDev => env == AppEnv.dev;
  bool get isStaging => env == AppEnv.staging;
  bool get isProd => env == AppEnv.prod;

  /// Alias mirroring common Flutter convention.
  bool get isProduction => isProd;

  /// Human-readable app name surfaced in [MaterialApp.title].
  String get appName => 'AI Visual Director';

  /// App version string (mirrors the value in `pubspec.yaml`).
  /// Surfaced in the Settings screen alongside the env label.
  String get version => '0.1.0';
}