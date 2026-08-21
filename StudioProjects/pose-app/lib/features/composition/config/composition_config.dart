import 'package:flutter/foundation.dart';

import '../domain/enums/composition_enums.dart';

/// Visual grid overlays the user can toggle in the camera screen.
enum GridOverlayType {
  none,
  ruleOfThirds,
  goldenRatio,
  center,
  horizon,
  safeMargins,
}

/// All tunable knobs for composition analysis. Override via
/// Riverpod (`compositionConfigProvider`).
@immutable
class CompositionConfig {
  const CompositionConfig({
    // ── Factor weights (normalized at runtime) ──────────────────
    this.weightSubjectPlacement = 0.25,
    this.weightRuleOfThirds = 0.20,
    this.weightSymmetry = 0.15,
    this.weightHorizon = 0.15,
    this.weightHeadroom = 0.10,
    this.weightSubjectSize = 0.10,
    this.weightNegativeSpace = 0.05,

    // ── Rule of thirds ──────────────────────────────────────────
    this.thirdsProximityThreshold = 0.08, // dist to nearest intersection
    this.thirdsIdealThreshold = 0.04,

    // ── Symmetry ────────────────────────────────────────────────
    this.symmetryTolerance = 0.10, // |leftWeight - rightWeight| / total

    // ── Horizon ─────────────────────────────────────────────────
    this.horizonTiltThresholdDeg = 2.5,
    this.horizonDetectionMinConfidence = 0.45,

    // ── Headroom / footroom ─────────────────────────────────────
    this.headroomMin = 0.08,
    this.headroomMax = 0.30,
    this.footroomMin = 0.05,

    // ── Subject size ────────────────────────────────────────────
    this.subjectSizeIdealMin = 0.20,
    this.subjectSizeIdealMax = 0.60,
    this.subjectSizeTooSmall = 0.10,
    this.subjectSizeTooLarge = 0.85,

    // ── Negative space ──────────────────────────────────────────
    this.negativeSpaceMin = 0.15,
    this.negativeSpaceMax = 0.55,

    // ── Recommendation stability ────────────────────────────────
    this.confirmationFrames = 4,
    this.cooldownFrames = 6,
    this.minConfidenceToDisplay = 0.5,

    // ── Scene classification ────────────────────────────────────
    this.selfieFrontCameraFrameRatio = 0.45, // subject occupies > 45% + front camera
    this.coupleProximityRatio = 0.30, // bbox centers within 30% of frame width
    this.groupMinPersons = 3,
  });

  // Factor weights
  final double weightSubjectPlacement;
  final double weightRuleOfThirds;
  final double weightSymmetry;
  final double weightHorizon;
  final double weightHeadroom;
  final double weightSubjectSize;
  final double weightNegativeSpace;

  Map<CompositionFactor, double> get normalizedWeights {
    final raw = {
      CompositionFactor.subjectPlacement: weightSubjectPlacement,
      CompositionFactor.ruleOfThirds: weightRuleOfThirds,
      CompositionFactor.symmetry: weightSymmetry,
      CompositionFactor.horizon: weightHorizon,
      CompositionFactor.headroom: weightHeadroom,
      CompositionFactor.subjectSize: weightSubjectSize,
      CompositionFactor.negativeSpace: weightNegativeSpace,
    };
    final sum = raw.values.fold(0.0, (a, b) => a + b);
    if (sum == 0) return raw.map((k, _) => MapEntry(k, 0.0));
    return raw.map((k, v) => MapEntry(k, v / sum));
  }

  // Thresholds
  final double thirdsProximityThreshold;
  final double thirdsIdealThreshold;
  final double symmetryTolerance;
  final double horizonTiltThresholdDeg;
  final double horizonDetectionMinConfidence;
  final double headroomMin;
  final double headroomMax;
  final double footroomMin;
  final double subjectSizeIdealMin;
  final double subjectSizeIdealMax;
  final double subjectSizeTooSmall;
  final double subjectSizeTooLarge;
  final double negativeSpaceMin;
  final double negativeSpaceMax;

  // Recommendation stability
  final int confirmationFrames;
  final int cooldownFrames;
  final double minConfidenceToDisplay;

  // Scene classification
  final double selfieFrontCameraFrameRatio;
  final double coupleProximityRatio;
  final int groupMinPersons;

  CompositionConfig copyWith({
    double? weightSubjectPlacement,
    double? weightRuleOfThirds,
    double? weightSymmetry,
    double? weightHorizon,
    double? weightHeadroom,
    double? weightSubjectSize,
    double? weightNegativeSpace,
    double? thirdsProximityThreshold,
    double? thirdsIdealThreshold,
    double? symmetryTolerance,
    double? horizonTiltThresholdDeg,
    double? horizonDetectionMinConfidence,
    double? headroomMin,
    double? headroomMax,
    double? footroomMin,
    double? subjectSizeIdealMin,
    double? subjectSizeIdealMax,
    double? subjectSizeTooSmall,
    double? subjectSizeTooLarge,
    double? negativeSpaceMin,
    double? negativeSpaceMax,
    int? confirmationFrames,
    int? cooldownFrames,
    double? minConfidenceToDisplay,
    double? selfieFrontCameraFrameRatio,
    double? coupleProximityRatio,
    int? groupMinPersons,
  }) {
    return CompositionConfig(
      weightSubjectPlacement: weightSubjectPlacement ?? this.weightSubjectPlacement,
      weightRuleOfThirds: weightRuleOfThirds ?? this.weightRuleOfThirds,
      weightSymmetry: weightSymmetry ?? this.weightSymmetry,
      weightHorizon: weightHorizon ?? this.weightHorizon,
      weightHeadroom: weightHeadroom ?? this.weightHeadroom,
      weightSubjectSize: weightSubjectSize ?? this.weightSubjectSize,
      weightNegativeSpace: weightNegativeSpace ?? this.weightNegativeSpace,
      thirdsProximityThreshold: thirdsProximityThreshold ?? this.thirdsProximityThreshold,
      thirdsIdealThreshold: thirdsIdealThreshold ?? this.thirdsIdealThreshold,
      symmetryTolerance: symmetryTolerance ?? this.symmetryTolerance,
      horizonTiltThresholdDeg: horizonTiltThresholdDeg ?? this.horizonTiltThresholdDeg,
      horizonDetectionMinConfidence: horizonDetectionMinConfidence ?? this.horizonDetectionMinConfidence,
      headroomMin: headroomMin ?? this.headroomMin,
      headroomMax: headroomMax ?? this.headroomMax,
      footroomMin: footroomMin ?? this.footroomMin,
      subjectSizeIdealMin: subjectSizeIdealMin ?? this.subjectSizeIdealMin,
      subjectSizeIdealMax: subjectSizeIdealMax ?? this.subjectSizeIdealMax,
      subjectSizeTooSmall: subjectSizeTooSmall ?? this.subjectSizeTooSmall,
      subjectSizeTooLarge: subjectSizeTooLarge ?? this.subjectSizeTooLarge,
      negativeSpaceMin: negativeSpaceMin ?? this.negativeSpaceMin,
      negativeSpaceMax: negativeSpaceMax ?? this.negativeSpaceMax,
      confirmationFrames: confirmationFrames ?? this.confirmationFrames,
      cooldownFrames: cooldownFrames ?? this.cooldownFrames,
      minConfidenceToDisplay: minConfidenceToDisplay ?? this.minConfidenceToDisplay,
      selfieFrontCameraFrameRatio: selfieFrontCameraFrameRatio ?? this.selfieFrontCameraFrameRatio,
      coupleProximityRatio: coupleProximityRatio ?? this.coupleProximityRatio,
      groupMinPersons: groupMinPersons ?? this.groupMinPersons,
    );
  }
}
