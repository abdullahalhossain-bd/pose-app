import 'package:flutter/material.dart';

/// Design tokens for AI Visual Director.
///
/// Principles (see product spec): minimal, premium, cinematic, calm,
/// intelligent, trustworthy. The camera is the hero — chrome stays out
/// of the way, guidance text is confident but never shouty.
class AppColors {
  AppColors._();

  // Base — near-black, not pure black, so camera footage never looks
  // like it's floating on a void.
  static const Color background = Color(0xFF0A0B0D);
  static const Color surface = Color(0xFF141518);
  static const Color surfaceRaised = Color(0xFF1D1F23);

  // Text
  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textDisabled = Color(0xFF52525B);

  // Accent — a single restrained accent, used sparingly for AI
  // presence (guidance chip, capture-ready ring). Not decorative.
  static const Color accent = Color(0xFF5EEAD4);
  static const Color accentDim = Color(0xFF2DD4BF);

  // Semantic
  static const Color success = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFF87171);

  // Overlay scrims for guidance UI atop live camera feed.
  static const Color scrimTop = Color(0xB3000000);
  static const Color scrimBottom = Color(0xCC000000);
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double pill = 999;
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        surface: AppColors.background,
        primary: AppColors.accent,
        secondary: AppColors.accentDim,
        error: AppColors.error,
      ),
      textTheme: base.textTheme
          .apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
          )
          .copyWith(
            headlineMedium: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
            titleMedium: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
            bodyLarge: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
            bodyMedium: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            labelLarge: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.background,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      ),
    );
  }
}
