import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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

/// Theme extension exposing the [AppSpacing] / [AppRadius] constants
/// to widgets via `Theme.of(context).extension<AppSpacingExtension>()!`.
///
/// Convenience accessors mirror the static fields so widget code can
/// read them off the theme without importing [AppSpacing] directly.
@immutable
class AppSpacingExtension extends ThemeExtension<AppSpacingExtension> {
  const AppSpacingExtension({
    this.xs = AppSpacing.xs,
    this.sm = AppSpacing.sm,
    this.md = AppSpacing.md,
    this.lg = AppSpacing.lg,
    this.xl = AppSpacing.xl,
    this.xxl = AppSpacing.xxl,
    this.screenHorizontal = AppSpacing.screenHorizontal,
    this.screenVertical = AppSpacing.screenVertical,
    this.radiusSm = AppRadius.sm,
    this.radiusMd = AppRadius.md,
    this.radiusLg = AppRadius.lg,
    this.radiusXl = AppRadius.xl,
  });

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;

  final double screenHorizontal;
  final double screenVertical;

  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double radiusXl;

  @override
  AppSpacingExtension copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
    double? screenHorizontal,
    double? screenVertical,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? radiusXl,
  }) {
    return AppSpacingExtension(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
      screenHorizontal: screenHorizontal ?? this.screenHorizontal,
      screenVertical: screenVertical ?? this.screenVertical,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      radiusXl: radiusXl ?? this.radiusXl,
    );
  }

  @override
  AppSpacingExtension lerp(AppSpacingExtension? other, double t) {
    if (other == null) return this;
    return AppSpacingExtension(
      xs: lerpDouble(xs, other.xs, t) ?? xs,
      sm: lerpDouble(sm, other.sm, t) ?? sm,
      md: lerpDouble(md, other.md, t) ?? md,
      lg: lerpDouble(lg, other.lg, t) ?? lg,
      xl: lerpDouble(xl, other.xl, t) ?? xl,
      xxl: lerpDouble(xxl, other.xxl, t) ?? xxl,
      screenHorizontal:
          lerpDouble(screenHorizontal, other.screenHorizontal, t) ??
              screenHorizontal,
      screenVertical:
          lerpDouble(screenVertical, other.screenVertical, t) ??
              screenVertical,
      radiusSm: lerpDouble(radiusSm, other.radiusSm, t) ?? radiusSm,
      radiusMd: lerpDouble(radiusMd, other.radiusMd, t) ?? radiusMd,
      radiusLg: lerpDouble(radiusLg, other.radiusLg, t) ?? radiusLg,
      radiusXl: lerpDouble(radiusXl, other.radiusXl, t) ?? radiusXl,
    );
  }
}
