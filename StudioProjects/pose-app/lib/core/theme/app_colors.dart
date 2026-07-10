import 'package:flutter/material.dart';

/// Brand-agnostic semantic color tokens for the app.
///
/// We deliberately do NOT expose hex values outside this file. Every
/// widget reads from [ColorScheme] or [AppColorsExtension] so the entire
/// app can be re-skinned (dark mode, future brand changes, dynamic color)
/// by changing one place.
///
/// The seed color drives Material 3 tonal palette generation.
class AppColors {
  const AppColors._();

  /// Seed used by Material 3 to generate the tonal palette.
  /// A refined indigo — photography-appropriate, premium, accessible.
  static const Color seed = Color(0xFF3D5AFE);

  /// Static brand accents kept off [ColorScheme] because they should not
  /// be subject to tonal palette generation.
  static const Color brandAccent = Color(0xFFFF6B6B);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
}
