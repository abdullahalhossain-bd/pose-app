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