import 'dart:typed_data';

import '../../pose/domain/entities/pose_sample.dart';
import '../config/lighting_config.dart';
import '../domain/entities/lighting_score.dart';
import '../domain/enums/lighting_enums.dart';
import '../utils/lighting_geometry.dart';

/// Computes lighting metrics from the camera's YUV planes + subject
/// bounding box. Pure function of (luma, chroma, pose, config) →
/// LightingScore.
///
/// Day 13 implementation is histogram + gradient based. Day 14+ may
/// plug in a learned white-balance / shadow classifier behind the
/// same interface.
class LightingAnalyzer {
  LightingAnalyzer(this.config);

  final LightingConfig config;

  LightingScore analyze({
    required Uint8List? luma,
    required int lumaWidth,
    required int lumaHeight,
    required Uint8List? uPlane,
    required Uint8List? vPlane,
    required PoseSample? pose,
  }) {
    final factors = <LightingFactorScore>[];
    final issues = <LightingIssue>[];

    final avgLum = LightingGeometry.averageLuminance(
      luma, lumaWidth, lumaHeight, stride: config.sampleStride,
    );
    final p10 = LightingGeometry.percentile(
      luma, lumaWidth, lumaHeight, 10, stride: config.sampleStride,
    );
    final p90 = LightingGeometry.percentile(
      luma, lumaWidth, lumaHeight, 90, stride: config.sampleStride,
    );
    final highlightClip = LightingGeometry.fractionAbove(
      luma, lumaWidth, lumaHeight, 245, stride: config.sampleStride,
    );
    final shadowClip = LightingGeometry.fractionBelow(
      luma, lumaWidth, lumaHeight, 15, stride: config.sampleStride,
    );
    final subjectLum = LightingGeometry.regionAverageLuminance(
      luma, lumaWidth, lumaHeight, pose?.boundingBox,
      stride: config.sampleStride,
    );
    final subjectVar = LightingGeometry.regionVariance(
      luma, lumaWidth, lumaHeight, pose?.boundingBox,
      stride: config.sampleStride,
    );
    final rbRatio = LightingGeometry.estimateRBRatio(
      uPlane: uPlane, vPlane: vPlane,
    );

    // ── 1. Brightness ─────────────────────────────────────────────
    final brightnessScore = _brightness(avgLum, issues);
    factors.add(LightingFactorScore(
      factor: LightingFactor.brightness,
      score: brightnessScore,
      weight: config.normalizedWeights[LightingFactor.brightness]!,
      note: '${avgLum.round()}',
    ));

    // ── 2. Exposure ───────────────────────────────────────────────
    final exposureState = _classifyExposure(avgLum, highlightClip, shadowClip, issues);
    final exposureScore = _exposureScore(exposureState);
    factors.add(LightingFactorScore(
      factor: LightingFactor.exposure,
      score: exposureScore,
      weight: config.normalizedWeights[LightingFactor.exposure]!,
      note: exposureState.name,
    ));

    // ── 3. Contrast ───────────────────────────────────────────────
    final contrast = (p90 - p10).round();
    final contrastScore = _contrast(contrast, issues);
    factors.add(LightingFactorScore(
      factor: LightingFactor.contrast,
      score: contrastScore,
      weight: config.normalizedWeights[LightingFactor.contrast]!,
      note: '$contrast',
    ));

    // ── 4. Dynamic range ──────────────────────────────────────────
    final dynRange = (p90 - p10).round();
    final dynRangeScore = _dynamicRange(dynRange, issues);
    factors.add(LightingFactorScore(
      factor: LightingFactor.dynamicRange,
      score: dynRangeScore,
      weight: config.normalizedWeights[LightingFactor.dynamicRange]!,
    ));

    // ── 5. Face lighting (subject region brightness) ─────────────
    final faceScore = _faceLighting(subjectLum, avgLum, issues);
    factors.add(LightingFactorScore(
      factor: LightingFactor.faceLighting,
      score: faceScore,
      weight: config.normalizedWeights[LightingFactor.faceLighting]!,
      note: '${subjectLum.round()}',
    ));

    // ── 6. Shadow softness ────────────────────────────────────────
    final shadowStatus = _classifyShadows(subjectVar, subjectLum);
    final shadowScore = _shadowSoftness(shadowStatus, issues);
    factors.add(LightingFactorScore(
      factor: LightingFactor.shadowSoftness,
      score: shadowScore,
      weight: config.normalizedWeights[LightingFactor.shadowSoftness]!,
    ));

    // ── Light source detection ────────────────────────────────────
    final centroid = LightingGeometry.brightnessCentroid(
      luma, lumaWidth, lumaHeight, stride: 8,
    );
    final lightDirection = _detectDirection(centroid, pose);
    final lightType = _detectType(lightDirection, exposureState, avgLum);
    final colorTemp = _classifyColorTemp(rbRatio);

    // Golden hour check.
    final now = DateTime.now();
    final goldenHour = _isGoldenHour(now);
    final blueHour = _isBlueHour(now);

    // Sort issues by priority then severity.
    issues.sort((a, b) {
      final p = a.priority.index.compareTo(b.priority.index);
      if (p != 0) return p;
      return b.severity.compareTo(a.severity);
    });

    final overall = factors.fold<double>(0, (s, f) => s + f.contribution);

    return LightingScore(
      factors: factors,
      issues: issues,
      overallScore: overall.clamp(0.0, 1.0),
      exposureState: exposureState,
      lightDirection: lightDirection,
      lightType: lightType,
      colorTemp: colorTemp,
      shadowStatus: shadowStatus,
      avgLuminance: avgLum,
      timestamp: now.microsecondsSinceEpoch,
      goldenHourActive: goldenHour,
      blueHourActive: blueHour,
    );
  }

  // ── Factor implementations ─────────────────────────────────────

  double _brightness(double avg, List<LightingIssue> issues) {
    // Ideal: 90..180. Below 60 = under, above 200 = over.
    if (avg < config.underexposedThreshold) {
      return (avg / config.underexposedThreshold).clamp(0.0, 1.0);
    }
    if (avg > config.overexposedThreshold) {
      return (1.0 - (avg - config.overexposedThreshold) / 55).clamp(0.0, 1.0);
    }
    // Within ideal range — peak at 135.
    final dist = (avg - 135).abs();
    return (1.0 - dist / 90).clamp(0.5, 1.0);
  }

  ExposureState _classifyExposure(
    double avg,
    double highlightClip,
    double shadowClip,
    List<LightingIssue> issues,
  ) {
    if (avg < config.underexposedThreshold / 2 || shadowClip > 0.4) {
      issues.add(LightingIssue(
        kind: LightingIssueKind.underexposed,
        priority: LightingPriority.critical,
        severity: 0.9,
        confidence: 0.9,
        rule: 'exposure_severe_under',
      ));
      if (shadowClip > config.clippingShadowPct) {
        issues.add(LightingIssue(
          kind: LightingIssueKind.shadowClipping,
          priority: LightingPriority.high,
          severity: shadowClip.clamp(0.0, 1.0),
          confidence: 0.85,
          rule: 'shadow_clipping',
        ));
      }
      return ExposureState.severelyUnderexposed;
    }
    if (avg < config.underexposedThreshold) {
      issues.add(LightingIssue(
        kind: LightingIssueKind.underexposed,
        priority: LightingPriority.high,
        severity: ((config.underexposedThreshold - avg) / 30).clamp(0.0, 1.0),
        confidence: 0.85,
        rule: 'exposure_under',
      ));
      return ExposureState.underexposed;
    }
    if (avg > config.overexposedThreshold + 30 || highlightClip > 0.3) {
      issues.add(LightingIssue(
        kind: LightingIssueKind.overexposed,
        priority: LightingPriority.critical,
        severity: 0.9,
        confidence: 0.9,
        rule: 'exposure_severe_over',
      ));
      if (highlightClip > config.clippingHighlightPct) {
        issues.add(LightingIssue(
          kind: LightingIssueKind.highlightClipping,
          priority: LightingPriority.high,
          severity: highlightClip.clamp(0.0, 1.0),
          confidence: 0.85,
          rule: 'highlight_clipping',
        ));
      }
      return ExposureState.severelyOverexposed;
    }
    if (avg > config.overexposedThreshold) {
      issues.add(LightingIssue(
        kind: LightingIssueKind.overexposed,
        priority: LightingPriority.high,
        severity: ((avg - config.overexposedThreshold) / 30).clamp(0.0, 1.0),
        confidence: 0.85,
        rule: 'exposure_over',
      ));
      return ExposureState.overexposed;
    }
    return ExposureState.balanced;
  }

  double _exposureScore(ExposureState s) => switch (s) {
        ExposureState.balanced => 1.0,
        ExposureState.underexposed => 0.4,
        ExposureState.overexposed => 0.4,
        ExposureState.severelyUnderexposed => 0.1,
        ExposureState.severelyOverexposed => 0.1,
      };

  double _contrast(int contrast, List<LightingIssue> issues) {
    if (contrast < config.lowContrastThreshold) {
      issues.add(LightingIssue(
        kind: LightingIssueKind.lowContrast,
        priority: LightingPriority.medium,
        severity: ((config.lowContrastThreshold - contrast) / 40).clamp(0.0, 1.0),
        confidence: 0.7,
        rule: 'contrast_low',
      ));
      return (contrast / config.lowContrastThreshold).clamp(0.0, 1.0);
    }
    if (contrast > config.highContrastThreshold) {
      issues.add(LightingIssue(
        kind: LightingIssueKind.highContrast,
        priority: LightingPriority.medium,
        severity: ((contrast - config.highContrastThreshold) / 60).clamp(0.0, 1.0),
        confidence: 0.7,
        rule: 'contrast_high',
      ));
      return (1.0 - (contrast - config.highContrastThreshold) / 95).clamp(0.0, 1.0);
    }
    return 1.0;
  }

  double _dynamicRange(int range, List<LightingIssue> issues) {
    if (range < config.goodDynamicRangeMin) {
      issues.add(LightingIssue(
        kind: LightingIssueKind.narrowDynamicRange,
        priority: LightingPriority.low,
        severity: ((config.goodDynamicRangeMin - range) / 40).clamp(0.0, 1.0),
        confidence: 0.6,
        rule: 'dynrange_narrow',
      ));
      return (range / config.goodDynamicRangeMin).clamp(0.0, 1.0);
    }
    return 1.0;
  }

  double _faceLighting(double subjectLum, double avgLum, List<LightingIssue> issues) {
    // Subject should be at least as bright as the scene average.
    final delta = subjectLum - avgLum;
    if (delta < config.backlightSubjectDeltaThreshold) {
      issues.add(LightingIssue(
        kind: LightingIssueKind.backlight,
        priority: LightingPriority.high,
        severity: ((-delta) / 60).clamp(0.0, 1.0),
        confidence: 0.8,
        rule: 'face_backlit',
      ));
      return (0.3 + (subjectLum / 255) * 0.4).clamp(0.0, 1.0);
    }
    if (subjectLum < config.underexposedThreshold) {
      issues.add(LightingIssue(
        kind: LightingIssueKind.poorFaceLighting,
        priority: LightingPriority.high,
        severity: ((config.underexposedThreshold - subjectLum) / 30).clamp(0.0, 1.0),
        confidence: 0.8,
        rule: 'face_dark',
      ));
      return (subjectLum / config.underexposedThreshold).clamp(0.0, 1.0);
    }
    return 1.0;
  }

  ShadowStatus _classifyShadows(double variance, double subjectLum) {
    if (variance < config.softShadowVarianceThreshold) {
      return ShadowStatus.none;
    }
    if (variance > config.harshShadowVarianceThreshold &&
        subjectLum < 150) {
      return ShadowStatus.harsh;
    }
    if (variance > config.softShadowVarianceThreshold) {
      return ShadowStatus.soft;
    }
    return ShadowStatus.none;
  }

  double _shadowSoftness(ShadowStatus s, List<LightingIssue> issues) {
    return switch (s) {
      ShadowStatus.none => 1.0,
      ShadowStatus.soft => 0.7,
      ShadowStatus.harsh => () {
          issues.add(LightingIssue(
            kind: LightingIssueKind.harshShadows,
            priority: LightingPriority.high,
            severity: 0.7,
            confidence: 0.75,
            rule: 'shadow_harsh',
          ));
          return 0.3;
        }(),
      ShadowStatus.racoonEyes => () {
          issues.add(LightingIssue(
            kind: LightingIssueKind.harshShadows,
            priority: LightingPriority.medium,
            severity: 0.6,
            confidence: 0.6,
            rule: 'shadow_eyes',
          ));
          return 0.4;
        }(),
    };
  }

  LightSourceDirection _detectDirection(
    ({double cx, double cy}) centroid,
    PoseSample? pose,
  ) {
    final subj = pose?.boundingBox == null
        ? (cx: 0.5, cy: 0.5)
        : (
            cx: pose!.boundingBox!.left + pose.boundingBox!.width / 2,
            cy: pose.boundingBox!.top + pose.boundingBox!.height / 2,
          );

    final dx = centroid.cx - subj.cx;  // + = light from right
    final dy = centroid.cy - subj.cy;  // + = light from below

    // Strong vertical dominance = overhead.
    if (dy.abs() > 0.15 && dy < 0) {
      return LightSourceDirection.overhead;
    }
    // Horizontal dominant.
    if (dx.abs() > dy.abs() && dx.abs() > 0.10) {
      return dx > 0 ? LightSourceDirection.rightSide : LightSourceDirection.leftSide;
    }
    // Subject is brighter than surroundings → front light.
    if (centroid.cx.abs() < 0.1 && centroid.cy.abs() < 0.1) {
      return LightSourceDirection.front;
    }
    // Subject significantly darker than brightness centroid → backlight.
    if ((centroid.cx - subj.cx).abs() > 0.20 ||
        (centroid.cy - subj.cy).abs() > 0.20) {
      return LightSourceDirection.back;
    }
    return LightSourceDirection.ambient;
  }

  LightSourceType _detectType(
    LightSourceDirection dir,
    ExposureState exposure,
    double avgLum,
  ) {
    if (exposure == ExposureState.severelyUnderexposed ||
        avgLum < 40) {
      return LightSourceType.lowLight;
    }
    if (_isGoldenHour(DateTime.now())) return LightSourceType.goldenHour;
    if (_isBlueHour(DateTime.now())) return LightSourceType.blueHour;
    if (dir == LightSourceDirection.front && avgLum > 100) {
      return LightSourceType.naturalDaylight;
    }
    if (avgLum < 80) return LightSourceType.artificialIndoor;
    return LightSourceType.unknown;
  }

  ColorTemperatureCategory _classifyColorTemp(double rbRatio) {
    if (rbRatio < config.coolRBRatio) return ColorTemperatureCategory.cool;
    if (rbRatio > config.warmRBRatio) return ColorTemperatureCategory.warm;
    return ColorTemperatureCategory.neutral;
  }

  bool _isGoldenHour(DateTime now) {
    // Heuristic: golden hour ≈ 1h before to 30min after sunset.
    // Day 14+ will plug in real GPS + sun position.
    // For now, use rough local-time estimate of sunset = 18:30.
    final sunset = DateTime(now.year, now.month, now.day, 18, 30);
    final diff = now.difference(sunset).inMinutes;
    return diff >= config.goldenHourStartOffsetMin &&
           diff <= config.goldenHourEndOffsetMin;
  }

  bool _isBlueHour(DateTime now) {
    final sunset = DateTime(now.year, now.month, now.day, 18, 30);
    final diff = now.difference(sunset).inMinutes;
    return diff >= config.blueHourStartOffsetMin &&
           diff <= config.blueHourEndOffsetMin;
  }
}
