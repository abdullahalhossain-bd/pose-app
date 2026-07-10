/// Raw spacing and radius values used across the app.
///
/// These are plain constants — the theme extension (`AppSpacingExtension`)
/// wraps them so they can be looked up via `Theme.of(context)` and
/// lerp'd between themes if needed.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const double screenHorizontal = 16;
  static const double screenVertical = 24;
}

class AppRadius {
  const AppRadius._();

  static const double sm = 4;
  static const double md = 8;
  static const double lg = 16;
  static const double xl = 24;
}