import 'package:flutter/material.dart';
import '../../pose/domain/entities/pose_sample.dart';
import '../../pose/domain/enums/pose_landmark_type.dart';
import '../config/guidance_config.dart';
import '../domain/entities/pose_quality_result.dart';
import '../domain/enums/guidance_enums.dart';
import '../utils/pose_geometry.dart';

/// Computes geometric pose metrics and detects issues. Pure function
/// of (PoseSample, GuidanceConfig) → PoseQualityResult.
///
/// The scorer is intentionally rule-based, not learned:
///  - Deterministic, explainable, debuggable
///  - Trivially testable with fixture poses
///  - Tunable via [GuidanceConfig] without code changes
///
/// Day 14+ may layer a learned scorer on top as a second pass — the
/// rule-based output stays as the baseline / fallback.
class PoseQualityScorer {
  PoseQualityScorer(this.config);

  final GuidanceConfig config;

  PoseQualityResult evaluate(PoseSample pose) {
    final metrics = <PoseMetric>[];
    final issues = <PoseIssue>[];

    // ── Head ──────────────────────────────────────────────────────
    _evaluateHead(pose, metrics, issues);
    // ── Shoulders ─────────────────────────────────────────────────
    _evaluateShoulders(pose, metrics, issues);
    // ── Hips ──────────────────────────────────────────────────────
    _evaluateHips(pose, metrics, issues);
    // ── Body rotation ─────────────────────────────────────────────
    _evaluateBodyRotation(pose, metrics, issues);
    // ── Arms ──────────────────────────────────────────────────────
    _evaluateArms(pose, metrics, issues);
    // ── Legs ──────────────────────────────────────────────────────
    _evaluateLegs(pose, metrics, issues);
    // ── Framing ───────────────────────────────────────────────────
    _evaluateFraming(pose, metrics, issues);

    // Sort issues by priority, then severity.
    issues.sort((a, b) {
      final p = a.priority.index.compareTo(b.priority.index);
      if (p != 0) return p;
      return b.severity.compareTo(a.severity);
    });

    final overallScore = _computeOverallScore(metrics);
    final confidence = _computeEvaluationConfidence(pose);

    return PoseQualityResult(
      metrics: metrics,
      issues: issues,
      overallScore: overallScore,
      confidence: confidence,
    );
  }

  // ── Head ────────────────────────────────────────────────────────
  void _evaluateHead(
      PoseSample p,
      List<PoseMetric> metrics,
      List<PoseIssue> issues,
      ) {
    final tilt = PoseGeometry.signedTiltDeg(
      p,
      PoseLandmarkType.leftEar,
      PoseLandmarkType.rightEar,
    );
    if (tilt != null) {
      final within = tilt.abs() < config.headTiltThresholdDeg;
      metrics.add(PoseMetric(
        name: 'head_tilt_deg',
        value: tilt,
        unit: 'deg',
        isWithinThreshold: within,
      ));
      if (!within) {
        issues.add(PoseIssue(
          kind: tilt > 0 ? PoseIssueKind.headTiltedLeft : PoseIssueKind.headTiltedRight,
          priority: GuidancePriority.medium,
          severity: (tilt.abs() / 30).clamp(0.0, 1.0),
          confidence: PoseGeometry.averageConfidence(p, [
            PoseLandmarkType.leftEar,
            PoseLandmarkType.rightEar,
          ]),
          rule: 'head_tilt',
          targetLandmark: PoseLandmarkType.nose,
        ));
      }
    }

    // Chin height: nose Y vs shoulder midpoint Y. Lower nose → lower chin.
    final nose = PoseGeometry.get(p, PoseLandmarkType.nose);
    final ls = PoseGeometry.get(p, PoseLandmarkType.leftShoulder);
    final rs = PoseGeometry.get(p, PoseLandmarkType.rightShoulder);
    if (nose != null && ls != null && rs != null) {
      final shoulderY = (ls.y + rs.y) / 2;
      final chinOffset = shoulderY - nose.y; // positive = nose above shoulders
      // Healthy chin offset ~0.10–0.20 of frame height.
      if (chinOffset < 0.06) {
        issues.add(PoseIssue(
          kind: PoseIssueKind.chinTooLow,
          priority: GuidancePriority.high,
          severity: ((0.06 - chinOffset) / 0.06).clamp(0.0, 1.0),
          confidence: nose.likelihood,
          rule: 'chin_too_low',
          targetLandmark: PoseLandmarkType.nose,
          suggestedDirection: GuidanceDirection.up,
        ));
      } else if (chinOffset > 0.25) {
        issues.add(PoseIssue(
          kind: PoseIssueKind.chinTooHigh,
          priority: GuidancePriority.medium,
          severity: ((chinOffset - 0.25) / 0.10).clamp(0.0, 1.0),
          confidence: nose.likelihood,
          rule: 'chin_too_high',
          targetLandmark: PoseLandmarkType.nose,
          suggestedDirection: GuidanceDirection.down,
        ));
      }
    }
  }

  // ── Shoulders ──────────────────────────────────────────────────
  void _evaluateShoulders(
      PoseSample p,
      List<PoseMetric> metrics,
      List<PoseIssue> issues,
      ) {
    final tilt = PoseGeometry.signedTiltDeg(
      p,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
    );
    if (tilt != null) {
      final within = tilt.abs() < config.shoulderTiltThresholdDeg;
      metrics.add(PoseMetric(
        name: 'shoulder_tilt_deg',
        value: tilt,
        unit: 'deg',
        isWithinThreshold: within,
      ));
      if (!within) {
        issues.add(PoseIssue(
          kind: PoseIssueKind.shouldersTilted,
          priority: GuidancePriority.high,
          severity: (tilt.abs() / 25).clamp(0.0, 1.0),
          confidence: PoseGeometry.averageConfidence(p, [
            PoseLandmarkType.leftShoulder,
            PoseLandmarkType.rightShoulder,
          ]),
          rule: 'shoulder_tilt',
        ));
      }
    }

    // Body rotation proxy: horizontal distance between shoulders
    // shrinks as the body rotates. Small shoulder distance + visible
    // ear on one side = rotated.
    final ls = PoseGeometry.get(p, PoseLandmarkType.leftShoulder);
    final rs = PoseGeometry.get(p, PoseLandmarkType.rightShoulder);
    final lh = PoseGeometry.get(p, PoseLandmarkType.leftHip);
    final rh = PoseGeometry.get(p, PoseLandmarkType.rightHip);
    if (ls != null && rs != null && lh != null && rh != null) {
      final shoulderW = (ls.x - rs.x).abs();
      final hipW = (lh.x - rh.x).abs();
      if (shoulderW < hipW * 0.55) {
        // Determine direction: if left shoulder is to the right of right
        // shoulder (mirrored), the body is rotated. We use the relative
        // position of the nose vs shoulder midpoint to guess direction.
        final nose = PoseGeometry.get(p, PoseLandmarkType.nose);
        final shoulderMidX = (ls.x + rs.x) / 2;
        final direction = nose != null && nose.x < shoulderMidX
            ? PoseIssueKind.bodyRotatedLeft
            : PoseIssueKind.bodyRotatedRight;
        issues.add(PoseIssue(
          kind: direction,
          priority: GuidancePriority.high,
          severity: 0.7,
          confidence: 0.7,
          rule: 'shoulder_rotation_proxy',
        ));
      }
    }
  }

  // ── Hips ────────────────────────────────────────────────────────
  void _evaluateHips(
      PoseSample p,
      List<PoseMetric> metrics,
      List<PoseIssue> issues,
      ) {
    final tilt = PoseGeometry.signedTiltDeg(
      p,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
    );
    if (tilt != null) {
      final within = tilt.abs() < config.hipTiltThresholdDeg;
      metrics.add(PoseMetric(
        name: 'hip_tilt_deg',
        value: tilt,
        unit: 'deg',
        isWithinThreshold: within,
      ));
      if (!within) {
        issues.add(PoseIssue(
          kind: PoseIssueKind.hipsNotLevel,
          priority: GuidancePriority.medium,
          severity: (tilt.abs() / 20).clamp(0.0, 1.0),
          confidence: PoseGeometry.averageConfidence(p, [
            PoseLandmarkType.leftHip,
            PoseLandmarkType.rightHip,
          ]),
          rule: 'hip_tilt',
        ));
      }
    }
  }

  // ── Body rotation (alternative signal) ─────────────────────────
  void _evaluateBodyRotation(
      PoseSample p,
      List<PoseMetric> metrics,
      List<PoseIssue> issues,
      ) {
    // Visibility asymmetry: when body rotates, the far-side shoulder
    // becomes less visible. ML Kit reports likelihood per landmark.
    final ls = PoseGeometry.get(p, PoseLandmarkType.leftShoulder);
    final rs = PoseGeometry.get(p, PoseLandmarkType.rightShoulder);
    if (ls != null && rs != null) {
      final asymmetry = (ls.likelihood - rs.likelihood).abs();
      metrics.add(PoseMetric(
        name: 'shoulder_visibility_asymmetry',
        value: asymmetry,
        unit: '',
        isWithinThreshold: asymmetry < 0.25,
      ));
      if (asymmetry > 0.35 && !issues.any((i) => i.kind == PoseIssueKind.bodyRotatedLeft || i.kind == PoseIssueKind.bodyRotatedRight)) {
        final direction = ls.likelihood > rs.likelihood
            ? PoseIssueKind.bodyRotatedRight
            : PoseIssueKind.bodyRotatedLeft;
        issues.add(PoseIssue(
          kind: direction,
          priority: GuidancePriority.medium,
          severity: asymmetry.clamp(0.0, 1.0),
          confidence: 0.6,
          rule: 'visibility_asymmetry',
        ));
      }
    }
  }

  // ── Arms ────────────────────────────────────────────────────────
  void _evaluateArms(
      PoseSample p,
      List<PoseMetric> metrics,
      List<PoseIssue> issues,
      ) {
    // Elbow angle: <30 deg suggests arm crossed; >170 = locked.
    final leftElbow = PoseGeometry.angleAt(
      p,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.leftWrist,
    );
    final rightElbow = PoseGeometry.angleAt(
      p,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.rightWrist,
    );

    if (leftElbow != null) {
      metrics.add(PoseMetric(
        name: 'left_elbow_angle',
        value: leftElbow,
        unit: 'deg',
        isWithinThreshold: leftElbow > 30 && leftElbow < 170,
      ));
    }
    if (rightElbow != null) {
      metrics.add(PoseMetric(
        name: 'right_elbow_angle',
        value: rightElbow,
        unit: 'deg',
        isWithinThreshold: rightElbow > 30 && rightElbow < 170,
      ));
    }

    // Arms crossed detection: wrists close to opposite shoulder.
    final lw = PoseGeometry.get(p, PoseLandmarkType.leftWrist);
    final rw = PoseGeometry.get(p, PoseLandmarkType.rightWrist);
    final ls = PoseGeometry.get(p, PoseLandmarkType.leftShoulder);
    final rs = PoseGeometry.get(p, PoseLandmarkType.rightShoulder);
    if (lw != null && rw != null && ls != null && rs != null) {
      final lwToRight = (Offset(lw.x, lw.y) - Offset(rs.x, rs.y)).distance;
      final rwToLeft = (Offset(rw.x, rw.y) - Offset(ls.x, ls.y)).distance;
      if (lwToRight < 0.15 || rwToLeft < 0.15) {
        issues.add(PoseIssue(
          kind: PoseIssueKind.armsCrossed,
          priority: GuidancePriority.medium,
          severity: 0.6,
          confidence: 0.7,
          rule: 'arms_crossed',
        ));
      }
    }
  }

  // ── Legs ────────────────────────────────────────────────────────
  void _evaluateLegs(
      PoseSample p,
      List<PoseMetric> metrics,
      List<PoseIssue> issues,
      ) {
    final ratio = PoseGeometry.horizontalRatio(
      p,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
    );
    if (ratio != null) {
      metrics.add(PoseMetric(
        name: 'stance_to_shoulder_ratio',
        value: ratio,
        unit: '',
        isWithinThreshold: ratio >= config.legStanceTooNarrowRatio &&
            ratio <= config.legStanceTooWideRatio,
      ));
      if (ratio < config.legStanceTooNarrowRatio) {
        issues.add(PoseIssue(
          kind: PoseIssueKind.stanceTooNarrow,
          priority: GuidancePriority.low,
          severity: ((config.legStanceTooNarrowRatio - ratio) / 0.15).clamp(0.0, 1.0),
          confidence: 0.7,
          rule: 'stance_narrow',
        ));
      } else if (ratio > config.legStanceTooWideRatio) {
        issues.add(PoseIssue(
          kind: PoseIssueKind.stanceTooWide,
          priority: GuidancePriority.low,
          severity: ((ratio - config.legStanceTooWideRatio) / 0.20).clamp(0.0, 1.0),
          confidence: 0.7,
          rule: 'stance_wide',
        ));
      }
    }
  }

  // ── Framing ─────────────────────────────────────────────────────
  void _evaluateFraming(
      PoseSample p,
      List<PoseMetric> metrics,
      List<PoseIssue> issues,
      ) {
    final box = p.boundingBox;
    if (box == null) return;

    final tooClose = box.area > 1 - config.subjectTooCloseMargin;
    final tooFar = box.area < config.subjectTooFarMargin;
    metrics.add(PoseMetric(
      name: 'subject_area_ratio',
      value: box.area,
      unit: '',
      isWithinThreshold: !tooClose && !tooFar,
    ));

    if (tooClose) {
      issues.add(PoseIssue(
        kind: PoseIssueKind.tooCloseToCamera,
        priority: GuidancePriority.critical,
        severity: ((box.area - (1 - config.subjectTooCloseMargin)) / 0.10).clamp(0.0, 1.0),
        confidence: 0.9,
        rule: 'framing_too_close',
        suggestedDirection: GuidanceDirection.down,
      ));
    } else if (tooFar) {
      issues.add(PoseIssue(
        kind: PoseIssueKind.tooFarFromCamera,
        priority: GuidancePriority.high,
        severity: ((config.subjectTooFarMargin - box.area) / 0.15).clamp(0.0, 1.0),
        confidence: 0.9,
        rule: 'framing_too_far',
        suggestedDirection: GuidanceDirection.up,
      ));
    }

    // Centering.
    final centerX = box.left + box.width / 2;
    final offBy = (centerX - 0.5).abs();
    metrics.add(PoseMetric(
      name: 'subject_off_center',
      value: offBy,
      unit: '',
      isWithinThreshold: offBy < config.subjectOffCenterThreshold,
    ));
    if (offBy > config.subjectOffCenterThreshold) {
      issues.add(PoseIssue(
        kind: centerX < 0.5
            ? PoseIssueKind.offCenterLeft
            : PoseIssueKind.offCenterRight,
        priority: GuidancePriority.medium,
        severity: (offBy / 0.30).clamp(0.0, 1.0),
        confidence: 0.8,
        rule: 'framing_off_center',
        suggestedDirection: centerX < 0.5
            ? GuidanceDirection.right
            : GuidanceDirection.left,
      ));
    }

    // Head room: distance from nose Y to top of frame.
    final nose = PoseGeometry.get(p, PoseLandmarkType.nose);
    if (nose != null) {
      final headRoom = nose.y;
      metrics.add(PoseMetric(
        name: 'head_room',
        value: headRoom,
        unit: '',
        isWithinThreshold: headRoom >= config.headRoomMin &&
            headRoom <= config.headRoomMax,
      ));
      if (headRoom < config.headRoomMin) {
        issues.add(PoseIssue(
          kind: PoseIssueKind.insufficientHeadRoom,
          priority: GuidancePriority.high,
          severity: ((config.headRoomMin - headRoom) / 0.05).clamp(0.0, 1.0),
          confidence: 0.8,
          rule: 'framing_head_room_low',
          suggestedDirection: GuidanceDirection.down,
        ));
      } else if (headRoom > config.headRoomMax) {
        issues.add(PoseIssue(
          kind: PoseIssueKind.tooMuchHeadRoom,
          priority: GuidancePriority.low,
          severity: ((headRoom - config.headRoomMax) / 0.10).clamp(0.0, 1.0),
          confidence: 0.7,
          rule: 'framing_head_room_high',
          suggestedDirection: GuidanceDirection.up,
        ));
      }
    }
  }

  // ── Aggregates ─────────────────────────────────────────────────
  double _computeOverallScore(List<PoseMetric> metrics) {
    if (metrics.isEmpty) return 0;
    final passing = metrics.where((m) => m.isWithinThreshold).length;
    return passing / metrics.length;
  }

  double _computeEvaluationConfidence(PoseSample p) {
    // Confidence in our evaluation = how many key landmarks are visible.
    const keyLandmarks = [
      PoseLandmarkType.nose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
    ];
    return PoseGeometry.averageConfidence(p, keyLandmarks);
  }
}
