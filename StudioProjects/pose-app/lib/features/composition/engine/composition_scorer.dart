import 'dart:typed_data';

import '../../pose/domain/entities/pose_sample.dart';
import '../config/composition_config.dart';
import '../domain/entities/composition_score.dart';
import '../domain/enums/composition_enums.dart';
import '../utils/composition_geometry.dart';

/// Computes composition metrics from a [PoseSample] + luminance plane.
/// Pure function of (PoseSample, luma, config) → CompositionScore.
///
/// Rule-based for Day 12 — deterministic, explainable, testable.
/// Day 14+ may layer a learned scorer behind the same interface.
class CompositionScorer {
  CompositionScorer(this.config);

  final CompositionConfig config;

  CompositionScore evaluate({
    required PoseSample? pose,
    required Uint8List? luma,
    required int lumaWidth,
    required int lumaHeight,
  }) {
    final factors = <CompositionFactorScore>[];
    final issues = <CompositionIssue>[];

    final center = CompositionGeometry.subjectCenter(pose);
    final frameRatio = CompositionGeometry.subjectFrameRatio(pose);
    final headroom = CompositionGeometry.headroom(pose);
    final footroom = CompositionGeometry.footroom(pose);
    final horizonTilt = CompositionGeometry.detectHorizonTiltDeg(luma, lumaWidth, lumaHeight);
    final asymmetry = CompositionGeometry.symmetryAsymmetry(luma, lumaWidth, lumaHeight);
    final negSpace = CompositionGeometry.negativeSpaceRatio(
      luma: luma,
      width: lumaWidth,
      height: lumaHeight,
      pose: pose,
    );

    // ── 1. Subject placement ─────────────────────────────────────
    final placementScore = _subjectPlacement(center, issues);
    factors.add(CompositionFactorScore(
      factor: CompositionFactor.subjectPlacement,
      score: placementScore,
      weight: config.normalizedWeights[CompositionFactor.subjectPlacement]!,
    ));

    // ── 2. Rule of thirds ────────────────────────────────────────
    final thirdsScore = _ruleOfThirds(center, issues);
    factors.add(CompositionFactorScore(
      factor: CompositionFactor.ruleOfThirds,
      score: thirdsScore,
      weight: config.normalizedWeights[CompositionFactor.ruleOfThirds]!,
    ));

    // ── 3. Symmetry ──────────────────────────────────────────────
    final symmetryScore = _symmetry(asymmetry, issues);
    factors.add(CompositionFactorScore(
      factor: CompositionFactor.symmetry,
      score: symmetryScore,
      weight: config.normalizedWeights[CompositionFactor.symmetry]!,
    ));

    // ── 4. Horizon ───────────────────────────────────────────────
    final horizonScore = _horizon(horizonTilt, issues);
    factors.add(CompositionFactorScore(
      factor: CompositionFactor.horizon,
      score: horizonScore,
      weight: config.normalizedWeights[CompositionFactor.horizon]!,
    ));

    // ── 5. Headroom ──────────────────────────────────────────────
    final headroomScore = _headroom(headroom, footroom, issues);
    factors.add(CompositionFactorScore(
      factor: CompositionFactor.headroom,
      score: headroomScore,
      weight: config.normalizedWeights[CompositionFactor.headroom]!,
    ));

    // ── 6. Subject size ──────────────────────────────────────────
    final sizeScore = _subjectSize(frameRatio, issues);
    factors.add(CompositionFactorScore(
      factor: CompositionFactor.subjectSize,
      score: sizeScore,
      weight: config.normalizedWeights[CompositionFactor.subjectSize]!,
    ));

    // ── 7. Negative space ────────────────────────────────────────
    final negSpaceScore = _negativeSpace(negSpace, issues);
    factors.add(CompositionFactorScore(
      factor: CompositionFactor.negativeSpace,
      score: negSpaceScore,
      weight: config.normalizedWeights[CompositionFactor.negativeSpace]!,
    ));

    // Sort issues by priority then severity.
    issues.sort((a, b) {
      final p = a.priority.index.compareTo(b.priority.index);
      if (p != 0) return p;
      return b.severity.compareTo(a.severity);
    });

    final overall = factors.fold<double>(0, (s, f) => s + f.contribution);

    return CompositionScore(
      factors: factors,
      issues: issues,
      overallScore: overall.clamp(0.0, 1.0),
      horizonAngleDeg: horizonTilt,
      timestamp: DateTime.now().microsecondsSinceEpoch,
    );
  }

  // ── Factor implementations ─────────────────────────────────────

  double _subjectCenter(
      ({double x, double y})? center, List<CompositionIssue> issues) {
    return 0;
  }

  double _subjectPlacement(
      ({double x, double y})? center, List<CompositionIssue> issues) {
    if (center == null) return 0.5;
    final dx = (center.x - 0.5).abs();
    final dy = (center.y - 0.5).abs();
    final off = dx + dy;

    if (dx > 0.20) {
      issues.add(CompositionIssue(
        kind: center.x < 0.5
            ? CompositionIssueKind.subjectOffCenterLeft
            : CompositionIssueKind.subjectOffCenterRight,
        priority: CompositionPriority.high,
        severity: (dx / 0.30).clamp(0.0, 1.0),
        confidence: 0.85,
        rule: 'placement_x',
      ));
    }
    if (dy > 0.20) {
      issues.add(CompositionIssue(
        kind: center.y < 0.5
            ? CompositionIssueKind.subjectTooHigh
            : CompositionIssueKind.subjectTooLow,
        priority: CompositionPriority.medium,
        severity: (dy / 0.30).clamp(0.0, 1.0),
        confidence: 0.7,
        rule: 'placement_y',
      ));
    }
    return (1.0 - off).clamp(0.0, 1.0);
  }

  double _ruleOfThirds(
      ({double x, double y})? center, List<CompositionIssue> issues) {
    if (center == null) return 0.5;
    final dist = CompositionGeometry.distanceToNearestThirds(center.x, center.y);
    if (dist > config.thirdsProximityThreshold) {
      issues.add(CompositionIssue(
        kind: CompositionIssueKind.notOnThirdsIntersection,
        priority: CompositionPriority.low,
        severity: ((dist - config.thirdsProximityThreshold) / 0.20).clamp(0.0, 1.0),
        confidence: 0.6,
        rule: 'thirds_proximity',
      ));
    }
    // Score: 1.0 at intersection, decays with distance.
    return (1.0 - dist / 0.30).clamp(0.0, 1.0);
  }

  double _symmetry(double asymmetry, List<CompositionIssue> issues) {
    if (asymmetry > config.symmetryTolerance) {
      issues.add(CompositionIssue(
        kind: CompositionIssueKind.asymmetricalBalance,
        priority: CompositionPriority.low,
        severity: ((asymmetry - config.symmetryTolerance) / 0.20).clamp(0.0, 1.0),
        confidence: 0.5,
        rule: 'symmetry',
      ));
    }
    return (1.0 - asymmetry / 0.40).clamp(0.0, 1.0);
  }

  double _horizon(double? tiltDeg, List<CompositionIssue> issues) {
    if (tiltDeg == null) return 0.7; // no horizon detected — neutral
    final absTilt = tiltDeg.abs();
    if (absTilt > config.horizonTiltThresholdDeg) {
      issues.add(CompositionIssue(
        kind: tiltDeg > 0
            ? CompositionIssueKind.horizonTiltedRight
            : CompositionIssueKind.horizonTiltedLeft,
        priority: CompositionPriority.high,
        severity: (absTilt / 10).clamp(0.0, 1.0),
        confidence: 0.8,
        rule: 'horizon_tilt',
      ));
    }
    return (1.0 - absTilt / 8).clamp(0.0, 1.0);
  }

  double _headroom(double headroom, double footroom, List<CompositionIssue> issues) {
    var score = 1.0;
    if (headroom < config.headroomMin) {
      issues.add(CompositionIssue(
        kind: CompositionIssueKind.insufficientHeadroom,
        priority: CompositionPriority.high,
        severity: ((config.headroomMin - headroom) / 0.05).clamp(0.0, 1.0),
        confidence: 0.85,
        rule: 'headroom_low',
      ));
      score -= 0.4;
    } else if (headroom > config.headroomMax) {
      issues.add(CompositionIssue(
        kind: CompositionIssueKind.excessiveHeadroom,
        priority: CompositionPriority.low,
        severity: ((headroom - config.headroomMax) / 0.10).clamp(0.0, 1.0),
        confidence: 0.7,
        rule: 'headroom_high',
      ));
      score -= 0.2;
    }
    if (footroom < config.footroomMin) {
      issues.add(CompositionIssue(
        kind: CompositionIssueKind.croppedFeet,
        priority: CompositionPriority.critical,
        severity: ((config.footroomMin - footroom) / 0.05).clamp(0.0, 1.0),
        confidence: 0.9,
        rule: 'footroom_low',
      ));
      score -= 0.5;
    }
    return score.clamp(0.0, 1.0);
  }

  double _subjectSize(double frameRatio, List<CompositionIssue> issues) {
    if (frameRatio < config.subjectSizeTooSmall) {
      issues.add(CompositionIssue(
        kind: CompositionIssueKind.subjectTooSmall,
        priority: CompositionPriority.high,
        severity: ((config.subjectSizeTooSmall - frameRatio) / 0.10).clamp(0.0, 1.0),
        confidence: 0.9,
        rule: 'size_small',
      ));
      return (frameRatio / config.subjectSizeTooSmall).clamp(0.0, 1.0);
    }
    if (frameRatio > config.subjectSizeTooLarge) {
      issues.add(CompositionIssue(
        kind: CompositionIssueKind.subjectTooLarge,
        priority: CompositionPriority.critical,
        severity: ((frameRatio - config.subjectSizeTooLarge) / 0.15).clamp(0.0, 1.0),
        confidence: 0.9,
        rule: 'size_large',
      ));
      return (1.0 - (frameRatio - config.subjectSizeTooLarge) / 0.15).clamp(0.0, 1.0);
    }
    // Within ideal range → 1.0; linearly decay outside.
    if (frameRatio >= config.subjectSizeIdealMin &&
        frameRatio <= config.subjectSizeIdealMax) {
      return 1.0;
    }
    if (frameRatio < config.subjectSizeIdealMin) {
      return (frameRatio / config.subjectSizeIdealMin).clamp(0.0, 1.0);
    }
    return (1.0 - (frameRatio - config.subjectSizeIdealMax) / 0.25).clamp(0.0, 1.0);
  }

  double _negativeSpace(double ratio, List<CompositionIssue> issues) {
    if (ratio < config.negativeSpaceMin) {
      issues.add(CompositionIssue(
        kind: CompositionIssueKind.tooCluttered,
        priority: CompositionPriority.medium,
        severity: ((config.negativeSpaceMin - ratio) / 0.10).clamp(0.0, 1.0),
        confidence: 0.6,
        rule: 'negspace_low',
      ));
      return (ratio / config.negativeSpaceMin).clamp(0.0, 1.0);
    }
    if (ratio > config.negativeSpaceMax) {
      issues.add(CompositionIssue(
        kind: CompositionIssueKind.tooMuchEmptySpace,
        priority: CompositionPriority.low,
        severity: ((ratio - config.negativeSpaceMax) / 0.20).clamp(0.0, 1.0),
        confidence: 0.6,
        rule: 'negspace_high',
      ));
      return (1.0 - (ratio - config.negativeSpaceMax) / 0.45).clamp(0.0, 1.0);
    }
    return 1.0;
  }
}
