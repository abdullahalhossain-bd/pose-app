import 'package:flutter/material.dart';

/// Material 3 typography scale.
///
/// We use the default Material 3 type system, but expose named styles
/// through [TextTheme] for widgets. For custom display weights / letter
/// spacing, see [AppTypographyExtension] (added to ThemeData in
/// `app_theme.dart`).
class AppTypography {
  const AppTypography._();

  /// Default font family. Override per-platform if needed.
  static const String fontFamily = 'Roboto';

  static TextTheme buildTextTheme(Brightness brightness) {
    return Typography.material2021().textTheme.resolve(brightness);
  }
}
