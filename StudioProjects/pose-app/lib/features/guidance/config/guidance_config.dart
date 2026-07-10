import 'package:flutter/foundation.dart';

/// All tunable knobs for the guidance engine live here. Override via
/// Riverpod (`guidanceConfigProvider`) — never read these from widgets
/// directly.
@immutable
class GuidanceConfig {
  const GuidanceConfig({
    // ── Stability ───────────────────────────────────────────────
    this.confirmationFrames = 5,
    this.cooldownFrames = 8,
    this.minConfidenceToDisplay = 0.55,
    this.maxInstructionPerMinute = 30,

    // ── Pose quality thresholds ─────────────────────────────────
    this.headTiltThresholdDeg = 12.0,
    this.shoulderTiltThresholdDeg = 8.0,
    this.shoulderRotationThresholdDeg = 18.0,
    this.hipTiltThresholdDeg = 10.0,
    this.bodyRotationThresholdDeg = 25.0,
    this.armExtensionMinDeg = 20.0,
    this.armCrossedThresholdDeg = 30.0,
    this.legStanceTooNarrowRatio = 0.15,
    this.legStanceTooWideRatio = 0.55,

    // ── Framing ─────────────────────────────────────────────────
    this.subjectTooCloseMargin = 0.06,
    this.subjectTooFarMargin = 0.35,
    this.subjectOffCenterThreshold = 0.18,
    this.headRoomMin = 0.08,
    this.headRoomMax = 0.30,

    // ── Confidence weights ──────────────────────────────────────
    this.minLandmarksForGuidance = 11,
    this.minAggregateConfidence = 0.55,

    // ── UX ──────────────────────────────────────────────────────
    this.showConfidenceMeter = true,
    this.showStatusBadge = true,
    this.overlayFadeMs = 250,
    this.audioEnabled = false,
    this.hapticEnabled = true,
  });

  // ── Stability ───────────────────────────────────────────────
  final int confirmationFrames;
  final int cooldownFrames;
  final double minConfidenceToDisplay;
  final int maxInstructionPerMinute;

  // ── Pose quality thresholds ─────────────────────────────────
  final double headTiltThresholdDeg;
  final double shoulderTiltThresholdDeg;
  final double shoulderRotationThresholdDeg;
  final double hipTiltThresholdDeg;
  final double bodyRotationThresholdDeg;
  final double armExtensionMinDeg;
  final double armCrossedThresholdDeg;
  final double legStanceTooNarrowRatio;
  final double legStanceTooWideRatio;

  // ── Framing ─────────────────────────────────────────────────
  final double subjectTooCloseMargin;
  final double subjectTooFarMargin;
  final double subjectOffCenterThreshold;
  final double headRoomMin;
  final double headRoomMax;

  // ── Confidence weights ──────────────────────────────────────
  final int minLandmarksForGuidance;
  final double minAggregateConfidence;

  // ── UX ──────────────────────────────────────────────────────
  final bool showConfidenceMeter;
  final bool showStatusBadge;
  final int overlayFadeMs;
  final bool audioEnabled;
  final bool hapticEnabled;

  GuidanceConfig copyWith({
    int? confirmationFrames,
    int? cooldownFrames,
    double? minConfidenceToDisplay,
    int? maxInstructionPerMinute,
    double? headTiltThresholdDeg,
    double? shoulderTiltThresholdDeg,
    double? shoulderRotationThresholdDeg,
    double? hipTiltThresholdDeg,
    double? bodyRotationThresholdDeg,
    double? armExtensionMinDeg,
    double? armCrossedThresholdDeg,
    double? legStanceTooNarrowRatio,
    double? legStanceTooWideRatio,
    double? subjectTooCloseMargin,
    double? subjectTooFarMargin,
    double? subjectOffCenterThreshold,
    double? headRoomMin,
    double? headRoomMax,
    int? minLandmarksForGuidance,
    double? minAggregateConfidence,
    bool? showConfidenceMeter,
    bool? showStatusBadge,
    int? overlayFadeMs,
    bool? audioEnabled,
    bool? hapticEnabled,
  }) {
    return GuidanceConfig(
      confirmationFrames: confirmationFrames ?? this.confirmationFrames,
      cooldownFrames: cooldownFrames ?? this.cooldownFrames,
      minConfidenceToDisplay:
          minConfidenceToDisplay ?? this.minConfidenceToDisplay,
      maxInstructionPerMinute:
          maxInstructionPerMinute ?? this.maxInstructionPerMinute,
      headTiltThresholdDeg:
          headTiltThresholdDeg ?? this.headTiltThresholdDeg,
      shoulderTiltThresholdDeg:
          shoulderTiltThresholdDeg ?? this.shoulderTiltThresholdDeg,
      shoulderRotationThresholdDeg: shoulderRotationThresholdDeg ??
          this.shoulderRotationThresholdDeg,
      hipTiltThresholdDeg: hipTiltThresholdDeg ?? this.hipTiltThresholdDeg,
      bodyRotationThresholdDeg:
          bodyRotationThresholdDeg ?? this.bodyRotationThresholdDeg,
      armExtensionMinDeg: armExtensionMinDeg ?? this.armExtensionMinDeg,
      armCrossedThresholdDeg:
          armCrossedThresholdDeg ?? this.armCrossedThresholdDeg,
      legStanceTooNarrowRatio:
          legStanceTooNarrowRatio ?? this.legStanceTooNarrowRatio,
      legStanceTooWideRatio:
          legStanceTooWideRatio ?? this.legStanceTooWideRatio,
      subjectTooCloseMargin:
          subjectTooCloseMargin ?? this.subjectTooCloseMargin,
      subjectTooFarMargin:
          subjectTooFarMargin ?? this.subjectTooFarMargin,
      subjectOffCenterThreshold:
          subjectOffCenterThreshold ?? this.subjectOffCenterThreshold,
      headRoomMin: headRoomMin ?? this.headRoomMin,
      headRoomMax: headRoomMax ?? this.headRoomMax,
      minLandmarksForGuidance:
          minLandmarksForGuidance ?? this.minLandmarksForGuidance,
      minAggregateConfidence:
          minAggregateConfidence ?? this.minAggregateConfidence,
      showConfidenceMeter: showConfidenceMeter ?? this.showConfidenceMeter,
      showStatusBadge: showStatusBadge ?? this.showStatusBadge,
      overlayFadeMs: overlayFadeMs ?? this.overlayFadeMs,
      audioEnabled: audioEnabled ?? this.audioEnabled,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
    );
  }
}
