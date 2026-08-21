import 'package:flutter/foundation.dart';

import '../domain/enums/lighting_enums.dart';

/// All tunable knobs for lighting analysis. Override via Riverpod
/// (`lightingConfigProvider`) — never read from widgets directly.
@immutable
class LightingConfig {
  const LightingConfig({
    // ── Factor weights (normalized at runtime) ──────────────────
    this.weightBrightness = 0.25,
    this.weightExposure = 0.25,
    this.weightContrast = 0.15,
    this.weightDynamicRange = 0.10,
    this.weightFaceLighting = 0.15,
    this.weightShadowSoftness = 0.10,

    // ── Exposure thresholds (0..255 luminance) ──────────────────
    this.underexposedThreshold = 60,
    this.overexposedThreshold = 200,
    this.balancedMin = 90,
    this.balancedMax = 180,
    this.clippingHighlightPct = 0.05,  // 5% pixels > 245
    this.clippingShadowPct = 0.10,     // 10% pixels < 15

    // ── Contrast & dynamic range ────────────────────────────────
    this.lowContrastThreshold = 40,    // p90 - p10
    this.highContrastThreshold = 160,
    this.goodDynamicRangeMin = 80,

    // ── Color temperature (R/B ratio) ───────────────────────────
    this.coolRBRatio = 0.85,    // R/B < 0.85 → cool
    this.warmRBRatio = 1.20,    // R/B > 1.20 → warm

    // ── Light source detection ──────────────────────────────────
    this.lightSourceGradientThreshold = 15.0,  // brightness delta
    this.backlightSubjectDeltaThreshold = 30,  // subject darker than bg
    this.frontlightSubjectDeltaThreshold = -20, // subject brighter than bg

    // ── Shadow analysis ─────────────────────────────────────────
    this.harshShadowVarianceThreshold = 800,
    this.softShadowVarianceThreshold = 200,
    this.shadowDarknessThreshold = 60,

    // ── Golden hour ─────────────────────────────────────────────
    this.goldenHourStartOffsetMin = -60,  // minutes before sunset
    this.goldenHourEndOffsetMin = 30,     // minutes after sunset
    this.blueHourStartOffsetMin = -90,
    this.blueHourEndOffsetMin = -60,

    // ── Recommendation stability ────────────────────────────────
    this.confirmationFrames = 4,
    this.cooldownFrames = 8,
    this.minConfidenceToDisplay = 0.55,
    this.maxRecommendationPerMinute = 10,

    // ── Sampling (perf) ─────────────────────────────────────────
    this.histogramBuckets = 64,
    this.sampleStride = 4,  // sample every Nth pixel
  });

  // Factor weights
  final double weightBrightness;
  final double weightExposure;
  final double weightContrast;
  final double weightDynamicRange;
  final double weightFaceLighting;
  final double weightShadowSoftness;

  Map<LightingFactor, double> get normalizedWeights {
    final raw = {
      LightingFactor.brightness: weightBrightness,
      LightingFactor.exposure: weightExposure,
      LightingFactor.contrast: weightContrast,
      LightingFactor.dynamicRange: weightDynamicRange,
      LightingFactor.faceLighting: weightFaceLighting,
      LightingFactor.shadowSoftness: weightShadowSoftness,
    };
    final sum = raw.values.fold(0.0, (a, b) => a + b);
    if (sum == 0) return raw.map((k, _) => MapEntry(k, 0.0));
    return raw.map((k, v) => MapEntry(k, v / sum));
  }

  // Exposure thresholds
  final int underexposedThreshold;
  final int overexposedThreshold;
  final int balancedMin;
  final int balancedMax;
  final double clippingHighlightPct;
  final double clippingShadowPct;

  // Contrast & dynamic range
  final int lowContrastThreshold;
  final int highContrastThreshold;
  final int goodDynamicRangeMin;

  // Color temperature
  final double coolRBRatio;
  final double warmRBRatio;

  // Light source
  final double lightSourceGradientThreshold;
  final int backlightSubjectDeltaThreshold;
  final int frontlightSubjectDeltaThreshold;

  // Shadow
  final double harshShadowVarianceThreshold;
  final double softShadowVarianceThreshold;
  final int shadowDarknessThreshold;

  // Golden hour
  final int goldenHourStartOffsetMin;
  final int goldenHourEndOffsetMin;
  final int blueHourStartOffsetMin;
  final int blueHourEndOffsetMin;

  // Recommendation stability
  final int confirmationFrames;
  final int cooldownFrames;
  final double minConfidenceToDisplay;
  final int maxRecommendationPerMinute;

  // Sampling
  final int histogramBuckets;
  final int sampleStride;

  LightingConfig copyWith({
    double? weightBrightness,
    double? weightExposure,
    double? weightContrast,
    double? weightDynamicRange,
    double? weightFaceLighting,
    double? weightShadowSoftness,
    int? underexposedThreshold,
    int? overexposedThreshold,
    int? balancedMin,
    int? balancedMax,
    double? clippingHighlightPct,
    double? clippingShadowPct,
    int? lowContrastThreshold,
    int? highContrastThreshold,
    int? goodDynamicRangeMin,
    double? coolRBRatio,
    double? warmRBRatio,
    double? lightSourceGradientThreshold,
    int? backlightSubjectDeltaThreshold,
    int? frontlightSubjectDeltaThreshold,
    double? harshShadowVarianceThreshold,
    double? softShadowVarianceThreshold,
    int? shadowDarknessThreshold,
    int? goldenHourStartOffsetMin,
    int? goldenHourEndOffsetMin,
    int? blueHourStartOffsetMin,
    int? blueHourEndOffsetMin,
    int? confirmationFrames,
    int? cooldownFrames,
    double? minConfidenceToDisplay,
    int? maxRecommendationPerMinute,
    int? histogramBuckets,
    int? sampleStride,
  }) {
    return LightingConfig(
      weightBrightness: weightBrightness ?? this.weightBrightness,
      weightExposure: weightExposure ?? this.weightExposure,
      weightContrast: weightContrast ?? this.weightContrast,
      weightDynamicRange: weightDynamicRange ?? this.weightDynamicRange,
      weightFaceLighting: weightFaceLighting ?? this.weightFaceLighting,
      weightShadowSoftness: weightShadowSoftness ?? this.weightShadowSoftness,
      underexposedThreshold: underexposedThreshold ?? this.underexposedThreshold,
      overexposedThreshold: overexposedThreshold ?? this.overexposedThreshold,
      balancedMin: balancedMin ?? this.balancedMin,
      balancedMax: balancedMax ?? this.balancedMax,
      clippingHighlightPct: clippingHighlightPct ?? this.clippingHighlightPct,
      clippingShadowPct: clippingShadowPct ?? this.clippingShadowPct,
      lowContrastThreshold: lowContrastThreshold ?? this.lowContrastThreshold,
      highContrastThreshold: highContrastThreshold ?? this.highContrastThreshold,
      goodDynamicRangeMin: goodDynamicRangeMin ?? this.goodDynamicRangeMin,
      coolRBRatio: coolRBRatio ?? this.coolRBRatio,
      warmRBRatio: warmRBRatio ?? this.warmRBRatio,
      lightSourceGradientThreshold: lightSourceGradientThreshold ?? this.lightSourceGradientThreshold,
      backlightSubjectDeltaThreshold: backlightSubjectDeltaThreshold ?? this.backlightSubjectDeltaThreshold,
      frontlightSubjectDeltaThreshold: frontlightSubjectDeltaThreshold ?? this.frontlightSubjectDeltaThreshold,
      harshShadowVarianceThreshold: harshShadowVarianceThreshold ?? this.harshShadowVarianceThreshold,
      softShadowVarianceThreshold: softShadowVarianceThreshold ?? this.softShadowVarianceThreshold,
      shadowDarknessThreshold: shadowDarknessThreshold ?? this.shadowDarknessThreshold,
      goldenHourStartOffsetMin: goldenHourStartOffsetMin ?? this.goldenHourStartOffsetMin,
      goldenHourEndOffsetMin: goldenHourEndOffsetMin ?? this.goldenHourEndOffsetMin,
      blueHourStartOffsetMin: blueHourStartOffsetMin ?? this.blueHourStartOffsetMin,
      blueHourEndOffsetMin: blueHourEndOffsetMin ?? this.blueHourEndOffsetMin,
      confirmationFrames: confirmationFrames ?? this.confirmationFrames,
      cooldownFrames: cooldownFrames ?? this.cooldownFrames,
      minConfidenceToDisplay: minConfidenceToDisplay ?? this.minConfidenceToDisplay,
      maxRecommendationPerMinute: maxRecommendationPerMinute ?? this.maxRecommendationPerMinute,
      histogramBuckets: histogramBuckets ?? this.histogramBuckets,
      sampleStride: sampleStride ?? this.sampleStride,
    );
  }
}
