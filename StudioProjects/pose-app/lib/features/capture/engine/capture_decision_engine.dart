import 'dart:typed_data' show Uint8List;

import '../../guidance/domain/entities/pose_quality_result.dart';
import '../../guidance/engine/guidance_engine.dart';
import '../../pose/domain/entities/pose_sample.dart';
import '../../pose/domain/enums/pose_landmark_type.dart';
import '../config/capture_config.dart';
import '../domain/entities/capture_score.dart';
import '../domain/enums/capture_enums.dart';
import 'stability_detector.dart';

/// Combines every AI signal into a single [CaptureScore]. Pure function
/// of (PoseSample, PoseQualityResult, GuidanceSignal, stability) →
/// CaptureScore.
///
/// The engine is intentionally rule-free. Adding a new factor is
/// additive: implement a sub-score, add a weight to [CaptureConfig],
/// include it in the weighted sum.
///
/// EMA smoothing: rather than emit a noisy per-frame score, we keep
/// an exponential moving average so a single bad frame doesn't veto
/// capture. The caller still sees `stableForFrames` so it can require
/// "N consecutive good frames" before triggering countdown.
class CaptureDecisionEngine {
  CaptureDecisionEngine({
    required this.config,
    required this.stability,
    required this.guidanceEngine,
  });

  final CaptureConfig config;
  final StabilityDetector stability;
  final GuidanceEngine guidanceEngine;

  double _emaScore = 0;
  int _stableForFrames = 0;
  CaptureSuppressReason _currentSuppress = CaptureSuppressReason.none;

  /// Evaluate this frame's capture readiness.
  CaptureScore evaluate({
    required PoseSample? pose,
    required PoseQualityResult? quality,
    required int personCount,
    required bool faceVisible,
    required bool eyesOpen,
    required bool lowLight,
    required Uint8List? luma,
    required int lumaWidth,
    required int lumaHeight,
    double? compositionOverride,
  }) {
    final factors = <FactorScore>[];
    var suppressReason = CaptureSuppressReason.none;

    // ── 1. Pose factor ────────────────────────────────────────────
    final poseScore = _poseScore(quality);
    factors.add(FactorScore(
      factor: CaptureFactor.pose,
      score: poseScore,
      weight: config.normalizedWeights[CaptureFactor.pose]!,
      note: quality == null ? 'no pose' : 'score ${(quality.overallScore * 100).round()}%',
    ));

    // ── 2. Stability factor ──────────────────────────────────────
    final stabilityScore = stability.process(
      pose: pose,
      luma: luma,
      width: lumaWidth,
      height: lumaHeight,
    );
    factors.add(FactorScore(
      factor: CaptureFactor.stability,
      score: stabilityScore,
      weight: config.normalizedWeights[CaptureFactor.stability]!,
      note: '${(stabilityScore * 100).round()}%',
    ));

    // ── 3. Face factor (Day 12+ plugs real face detection in) ────
    final faceScore = _faceScore(faceVisible, eyesOpen);
    factors.add(FactorScore(
      factor: CaptureFactor.face,
      score: faceScore,
      weight: config.normalizedWeights[CaptureFactor.face]!,
      note: faceVisible ? 'visible' : 'no face',
    ));

    // ── 4. Composition factor ────────────────────────────────────
    // Day 12: real CompositionScorer output is forwarded via
    // [compositionOverride]. Falls back to a cheap stub when not
    // provided (e.g. in unit tests).
    final compositionScore = compositionOverride ?? _compositionStub(pose);
    factors.add(FactorScore(
      factor: CaptureFactor.composition,
      score: compositionScore,
      weight: config.normalizedWeights[CaptureFactor.composition]!,
      note: compositionOverride != null ? 'live' : 'stub',
    ));

    // ── 5. Framing factor ────────────────────────────────────────
    final framingScore = _framingScore(pose);
    factors.add(FactorScore(
      factor: CaptureFactor.framing,
      score: framingScore,
      weight: config.normalizedWeights[CaptureFactor.framing]!,
    ));

    // ── 6. Confidence factor ─────────────────────────────────────
    final confidenceScore = pose?.confidence ?? 0;
    factors.add(FactorScore(
      factor: CaptureFactor.confidence,
      score: confidenceScore,
      weight: config.normalizedWeights[CaptureFactor.confidence]!,
    ));

    // ── Weighted aggregate ───────────────────────────────────────
    final rawScore = factors.fold<double>(
        0, (sum, f) => sum + f.contribution);

    // EMA smoothing.
    _emaScore = _emaScore == 0
        ? rawScore
        : config.emaAlpha * rawScore + (1 - config.emaAlpha) * _emaScore;

    // ── Suppress reasons (checked in priority order) ─────────────
    if (personCount > config.maxPersonsForAutoCapture) {
      suppressReason = CaptureSuppressReason.multiplePeople;
    } else if (!faceVisible) {
      suppressReason = CaptureSuppressReason.noFace;
    } else if (!eyesOpen) {
      suppressReason = CaptureSuppressReason.closedEyes;
    } else if (lowLight && config.suppressInLowLight) {
      suppressReason = CaptureSuppressReason.lowLight;
    } else if (stabilityScore < 0.4) {
      suppressReason = stabilityScore < 0.2
          ? CaptureSuppressReason.cameraShake
          : CaptureSuppressReason.subjectMoving;
    } else if (pose == null) {
      suppressReason = CaptureSuppressReason.userExited;
    } else if ((pose.confidence) < 0.5) {
      suppressReason = CaptureSuppressReason.lowConfidence;
    }

    // ── Stability counter ────────────────────────────────────────
    if (suppressReason == CaptureSuppressReason.none &&
        _emaScore >= config.captureThreshold) {
      _stableForFrames++;
    } else {
      _stableForFrames = 0;
    }

    _currentSuppress = suppressReason;

    return CaptureScore(
      factors: factors,
      overall: _emaScore,
      suppressReason: suppressReason,
      stableForFrames: _stableForFrames,
      timestamp: DateTime.now().microsecondsSinceEpoch,
    );
  }

  // ── Sub-score implementations ──────────────────────────────────

  double _poseScore(PoseQualityResult? quality) {
    if (quality == null) return 0;
    // Penalize critical/high issues heavily; medium linearly; low mildly.
    final criticalCount = quality.issues.where((i) =>
        i.priority.index == 0).length;
    final highCount = quality.issues.where((i) =>
        i.priority.index == 1).length;
    final mediumCount = quality.issues.where((i) =>
        i.priority.index == 2).length;
    final lowCount = quality.issues.where((i) =>
        i.priority.index == 3).length;

    final penalty = criticalCount * 0.5 +
        highCount * 0.25 +
        mediumCount * 0.10 +
        lowCount * 0.03;
    return (quality.overallScore - penalty).clamp(0.0, 1.0);
  }

  double _faceScore(bool faceVisible, bool eyesOpen) {
    if (!faceVisible) return 0.0;
    if (!eyesOpen) return 0.3;
    return 1.0;
  }

  /// Day 12 will replace this with real composition analysis
  /// (rule of thirds, leading space, symmetry).
  double _compositionStub(PoseSample? pose) {
    if (pose == null || pose.boundingBox == null) return 0.5;
    // Cheap proxy: subject roughly centered + reasonable size.
    final cx = pose.boundingBox!.left + pose.boundingBox!.width / 2;
    final centered = 1.0 - (cx - 0.5).abs() * 2;
    final sizeOk = pose.boundingBox!.area > 0.1 && pose.boundingBox!.area < 0.7
        ? 1.0
        : 0.5;
    return ((centered + sizeOk) / 2).clamp(0.0, 1.0);
  }

  double _framingScore(PoseSample? pose) {
    if (pose == null || pose.boundingBox == null) return 0.0;
    final area = pose.boundingBox!.area;
    // Ideal: subject occupies 20–60% of frame.
    if (area >= 0.20 && area <= 0.60) return 1.0;
    if (area < 0.20) return (area / 0.20).clamp(0.0, 1.0);
    return (1.0 - (area - 0.60) / 0.40).clamp(0.0, 1.0);
  }

  CaptureSuppressReason get currentSuppress => _currentSuppress;

  /// Reset EMA + stable counter (e.g. when user toggles Auto Capture
  /// off and back on, or when a new track ID is assigned).
  void reset() {
    _emaScore = 0;
    _stableForFrames = 0;
    _currentSuppress = CaptureSuppressReason.none;
    stability.reset();
  }
}
