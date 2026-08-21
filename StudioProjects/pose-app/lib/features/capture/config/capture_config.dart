import 'package:flutter/foundation.dart';

import '../domain/enums/capture_enums.dart';

/// Sensitivity presets the user can pick from in Settings. Higher
/// sensitivity = lower threshold = more eager to capture (but more
/// false positives). Lower sensitivity = stricter.
enum CaptureSensitivity {
  conservative, // 0.85 threshold
  balanced,     // 0.75 threshold
  eager,        // 0.65 threshold
}

/// All tunable knobs for the Capture Decision Engine. Override via
/// Riverpod (`captureConfigProvider`) — never read these from widgets.
@immutable
class CaptureConfig {
  const CaptureConfig({
    // ── Factor weights (must sum to ~1.0; engine normalizes anyway) ──
    this.weightPose = 0.30,
    this.weightStability = 0.25,
    this.weightFace = 0.15,
    this.weightComposition = 0.15,
    this.weightFraming = 0.10,
    this.weightConfidence = 0.05,

    // ── Thresholds ──────────────────────────────────────────────
    this.captureThreshold = 0.75,
    this.hardSuppressThreshold = 0.35,
    this.stableFrameRequirement = 8,
    this.emaAlpha = 0.35,

    // ── Stability ───────────────────────────────────────────────
    this.poseDeltaSuppressDeg = 8.0,
    this.cameraMotionSuppressPx = 24.0,
    this.stabilityWindowFrames = 10,

    // ── Countdown ───────────────────────────────────────────────
    this.defaultCountdownSeconds = 3,
    this.minCountdownSeconds = 0, // 0 = instant capture
    this.maxCountdownSeconds = 10,
    this.countdownCancelDropThreshold = 0.15,

    // ── Retry ───────────────────────────────────────────────────
    this.maxRetryAttempts = 1,
    this.retryCooldownMs = 1500,

    // ── Edge cases ──────────────────────────────────────────────
    this.maxPersonsForAutoCapture = 1,
    this.minFaceVisibility = 0.6,
    this.minEyeOpenness = 0.5,
    this.suppressInLowLight = true,

    // ── UX ──────────────────────────────────────────────────────
    this.showResultCardMs = 2500,
    this.celebrationAnimationMs = 800,
  });

  /// Per-preset factory.
  factory CaptureConfig.forSensitivity(CaptureSensitivity s) {
    return switch (s) {
      CaptureSensitivity.conservative => const CaptureConfig(
          captureThreshold: 0.85,
          stableFrameRequirement: 12,
          emaAlpha: 0.25,
        ),
      CaptureSensitivity.balanced => const CaptureConfig(),
      CaptureSensitivity.eager => const CaptureConfig(
          captureThreshold: 0.65,
          stableFrameRequirement: 5,
          emaAlpha: 0.45,
        ),
    };
  }

  // ── Factor weights ────────────────────────────────────────────
  final double weightPose;
  final double weightStability;
  final double weightFace;
  final double weightComposition;
  final double weightFraming;
  final double weightConfidence;

  /// Normalized weight map. Engine uses this so unbalanced configs
  /// still produce scores in [0..1].
  Map<CaptureFactor, double> get normalizedWeights {
    final raw = {
      CaptureFactor.pose: weightPose,
      CaptureFactor.stability: weightStability,
      CaptureFactor.face: weightFace,
      CaptureFactor.composition: weightComposition,
      CaptureFactor.framing: weightFraming,
      CaptureFactor.confidence: weightConfidence,
    };
    final sum = raw.values.fold(0.0, (a, b) => a + b);
    if (sum == 0) return raw.map((k, _) => MapEntry(k, 0.0));
    return raw.map((k, v) => MapEntry(k, v / sum));
  }

  // ── Thresholds ────────────────────────────────────────────────
  final double captureThreshold;
  final double hardSuppressThreshold;
  final int stableFrameRequirement;
  final double emaAlpha;

  // ── Stability ─────────────────────────────────────────────────
  final double poseDeltaSuppressDeg;
  final double cameraMotionSuppressPx;
  final int stabilityWindowFrames;

  // ── Countdown ─────────────────────────────────────────────────
  final int defaultCountdownSeconds;
  final int minCountdownSeconds;
  final int maxCountdownSeconds;
  final double countdownCancelDropThreshold;

  // ── Retry ─────────────────────────────────────────────────────
  final int maxRetryAttempts;
  final int retryCooldownMs;

  // ── Edge cases ────────────────────────────────────────────────
  final int maxPersonsForAutoCapture;
  final double minFaceVisibility;
  final double minEyeOpenness;
  final bool suppressInLowLight;

  // ── UX ────────────────────────────────────────────────────────
  final int showResultCardMs;
  final int celebrationAnimationMs;

  CaptureConfig copyWith({
    double? weightPose,
    double? weightStability,
    double? weightFace,
    double? weightComposition,
    double? weightFraming,
    double? weightConfidence,
    double? captureThreshold,
    double? hardSuppressThreshold,
    int? stableFrameRequirement,
    double? emaAlpha,
    double? poseDeltaSuppressDeg,
    double? cameraMotionSuppressPx,
    int? stabilityWindowFrames,
    int? defaultCountdownSeconds,
    int? minCountdownSeconds,
    int? maxCountdownSeconds,
    double? countdownCancelDropThreshold,
    int? maxRetryAttempts,
    int? retryCooldownMs,
    int? maxPersonsForAutoCapture,
    double? minFaceVisibility,
    double? minEyeOpenness,
    bool? suppressInLowLight,
    int? showResultCardMs,
    int? celebrationAnimationMs,
  }) {
    return CaptureConfig(
      weightPose: weightPose ?? this.weightPose,
      weightStability: weightStability ?? this.weightStability,
      weightFace: weightFace ?? this.weightFace,
      weightComposition: weightComposition ?? this.weightComposition,
      weightFraming: weightFraming ?? this.weightFraming,
      weightConfidence: weightConfidence ?? this.weightConfidence,
      captureThreshold: captureThreshold ?? this.captureThreshold,
      hardSuppressThreshold: hardSuppressThreshold ?? this.hardSuppressThreshold,
      stableFrameRequirement: stableFrameRequirement ?? this.stableFrameRequirement,
      emaAlpha: emaAlpha ?? this.emaAlpha,
      poseDeltaSuppressDeg: poseDeltaSuppressDeg ?? this.poseDeltaSuppressDeg,
      cameraMotionSuppressPx: cameraMotionSuppressPx ?? this.cameraMotionSuppressPx,
      stabilityWindowFrames: stabilityWindowFrames ?? this.stabilityWindowFrames,
      defaultCountdownSeconds: defaultCountdownSeconds ?? this.defaultCountdownSeconds,
      minCountdownSeconds: minCountdownSeconds ?? this.minCountdownSeconds,
      maxCountdownSeconds: maxCountdownSeconds ?? this.maxCountdownSeconds,
      countdownCancelDropThreshold: countdownCancelDropThreshold ?? this.countdownCancelDropThreshold,
      maxRetryAttempts: maxRetryAttempts ?? this.maxRetryAttempts,
      retryCooldownMs: retryCooldownMs ?? this.retryCooldownMs,
      maxPersonsForAutoCapture: maxPersonsForAutoCapture ?? this.maxPersonsForAutoCapture,
      minFaceVisibility: minFaceVisibility ?? this.minFaceVisibility,
      minEyeOpenness: minEyeOpenness ?? this.minEyeOpenness,
      suppressInLowLight: suppressInLowLight ?? this.suppressInLowLight,
      showResultCardMs: showResultCardMs ?? this.showResultCardMs,
      celebrationAnimationMs: celebrationAnimationMs ?? this.celebrationAnimationMs,
    );
  }
}
