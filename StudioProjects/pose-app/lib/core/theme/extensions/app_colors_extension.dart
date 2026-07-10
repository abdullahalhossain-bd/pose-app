import 'package:flutter/material.dart';

/// Semantic brand colors that aren't part of Material 3's [ColorScheme]
/// but the app needs globally (success, warning, brand accent, etc.).
///
/// Access in widgets:
/// ```dart
/// final brand = Theme.of(context).extension<AppColorsExtension>()!;
/// color: brand.success;
/// ```
@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.brandAccent,
    required this.success,
    required this.successContainer,
    required this.onSuccess,
    required this.warning,
    required this.warningContainer,
    required this.onWarning,
    required this.danger,
    required this.dangerContainer,
    required this.onDanger,
    required this.skeletonBase,
    required this.skeletonHighlight,
  });

  final Color brandAccent;

  final Color success;
  final Color successContainer;
  final Color onSuccess;

  final Color warning;
  final Color warningContainer;
  final Color onWarning;

  final Color danger;
  final Color dangerContainer;
  final Color onDanger;

  /// Shimmer base for skeleton loaders.
  final Color skeletonBase;
  final Color skeletonHighlight;

  factory AppColorsExtension.light() => const AppColorsExtension(
        brandAccent: Color(0xFFFF6B6B),
        success: Color(0xFF22C55E),
        successContainer: Color(0xFFD1FAE5),
        onSuccess: Color(0xFFFFFFFF),
        warning: Color(0xFFF59E0B),
        warningContainer: Color(0xFFFEF3C7),
        onWarning: Color(0xFF111111),
        danger: Color(0xFFEF4444),
        dangerContainer: Color(0xFFFEE2E2),
        onDanger: Color(0xFFFFFFFF),
        skeletonBase: Color(0xFFE5E7EB),
        skeletonHighlight: Color(0xFFF3F4F6),
      );

  factory AppColorsExtension.dark() => const AppColorsExtension(
        brandAccent: Color(0xFFFF8585),
        success: Color(0xFF4ADE80),
        successContainer: Color(0xFF14532D),
        onSuccess: Color(0xFF000000),
        warning: Color(0xFFFBBF24),
        warningContainer: Color(0xFF78350F),
        onWarning: Color(0xFF000000),
        danger: Color(0xFFF87171),
        dangerContainer: Color(0xFF7F1D1D),
        onDanger: Color(0xFFFFFFFF),
        skeletonBase: Color(0xFF1F2937),
        skeletonHighlight: Color(0xFF374151),
      );

  @override
  AppColorsExtension copyWith({
    Color? brandAccent,
    Color? success,
    Color? successContainer,
    Color? onSuccess,
    Color? warning,
    Color? warningContainer,
    Color? onWarning,
    Color? danger,
    Color? dangerContainer,
    Color? onDanger,
    Color? skeletonBase,
    Color? skeletonHighlight,
  }) {
    return AppColorsExtension(
      brandAccent: brandAccent ?? this.brandAccent,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarning: onWarning ?? this.onWarning,
      danger: danger ?? this.danger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      onDanger: onDanger ?? this.onDanger,
      skeletonBase: skeletonBase ?? this.skeletonBase,
      skeletonHighlight: skeletonHighlight ?? this.skeletonHighlight,
    );
  }

  @override
  AppColorsExtension lerp(AppColorsExtension? other, double t) {
    if (other == null) return this;
    return AppColorsExtension(
      brandAccent: Color.lerp(brandAccent, other.brandAccent, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer:
          Color.lerp(successContainer, other.successContainer, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer:
          Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerContainer:
          Color.lerp(dangerContainer, other.dangerContainer, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      skeletonBase: Color.lerp(skeletonBase, other.skeletonBase, t)!,
      skeletonHighlight:
          Color.lerp(skeletonHighlight, other.skeletonHighlight, t)!,
    );
  }
}
