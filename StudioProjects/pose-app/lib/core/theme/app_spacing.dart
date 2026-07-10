import 'package:flutter/material.dart';

/// 4-pt spacing grid. Every layout in the app should use these tokens.
///
/// Exposed via [AppSpacingExtension] so widgets write
/// `context.spacing.md` instead of raw numbers.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Content edge padding (sides of every screen body).
  static const double screenHorizontal = md;
  static const double screenVertical = lg;
}

/// Standard radii for rounded corners.
class AppRadius {
  const AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 9999;
}
