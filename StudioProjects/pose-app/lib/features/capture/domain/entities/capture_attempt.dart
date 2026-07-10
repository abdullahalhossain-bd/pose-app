import 'package:flutter/foundation.dart';

import '../../../guidance/domain/enums/guidance_enums.dart';
import '../../../pose/domain/entities/pose_sample.dart';
import '../enums/capture_enums.dart';
import 'capture_score.dart';

/// One capture attempt — success or failure. Persisted for analytics
/// (Day 14) and replay debugging.
@immutable
class CaptureAttempt {
  const CaptureAttempt({
    required this.id,
    required this.timestamp,
    required this.score,
    required this.success,
    required this.failureReason,
    required this.imagePath,
    required this.pose,
    required this.guidanceSignal,
    required this.tip,
  });

  final String id;
  final int timestamp; // microseconds since epoch
  final CaptureScore score;
  final bool success;
  final CaptureFailureReason failureReason;
  final String? imagePath;
  final PoseSample? pose;
  final GuidanceSignal? guidanceSignal;
  final String? tip;

  /// Convenience for the UI: human-friendly label of why it failed.
  String get failureLabel => switch (failureReason) {
        CaptureFailureReason.none => '',
        CaptureFailureReason.motionBlur => 'Slight motion blur',
        CaptureFailureReason.closedEyes => 'Eyes were closed',
        CaptureFailureReason.lostTracking => 'Lost tracking',
        CaptureFailureReason.lowConfidence => 'Low AI confidence',
        CaptureFailureReason.encoderError => 'Save failed',
        CaptureFailureReason.unknown => 'Capture failed',
      };

  /// Best-effort improvement tip for the next attempt.
  static String? tipForFailure(CaptureFailureReason reason) => switch (reason) {
        CaptureFailureReason.none => null,
        CaptureFailureReason.motionBlur => 'Hold still a moment longer next time.',
        CaptureFailureReason.closedEyes => 'Try the 3-2-1 countdown so you can time your blink.',
        CaptureFailureReason.lostTracking => 'Stay in frame — the AI lost your pose.',
        CaptureFailureReason.lowConfidence => 'Step into better light so the AI can see you clearly.',
        CaptureFailureReason.encoderError => 'Free up storage space and try again.',
        CaptureFailureReason.unknown => 'Give it another try.',
      };
}

/// Phase of the auto-capture lifecycle. Drives the UI state machine.
sealed class CaptureState {
  const CaptureState();

  String get label;
  bool get showsCountdown => false;
  bool get showsResultCard => false;
}

class CaptureIdle extends CaptureState {
  const CaptureIdle();
  @override
  String get label => 'Idle';
}

class CaptureSearching extends CaptureState {
  const CaptureSearching({required this.currentScore});
  final double currentScore;
  @override
  String get label => 'Looking for the right moment…';
}

class CaptureReady extends CaptureState {
  const CaptureReady({required this.score});
  final CaptureScore score;
  @override
  String get label => 'Ready';
}

class CaptureCountdown extends CaptureState {
  const CaptureCountdown({
    required this.remainingMs,
    required this.score,
  });
  final int remainingMs;
  final CaptureScore score;

  int get remainingSeconds => (remainingMs / 1000).ceil();

  @override
  bool get showsCountdown => true;
  @override
  String get label => 'Capturing in $remainingSeconds…';
}

class CaptureCapturing extends CaptureState {
  const CaptureCapturing();
  @override
  String get label => 'Capturing…';
}

class CaptureReviewing extends CaptureState {
  const CaptureReviewing({required this.attempt});
  final CaptureAttempt attempt;

  @override
  bool get showsResultCard => true;
  @override
  String get label => attempt.success ? 'Captured!' : 'Retrying…';
}

class CaptureSuppressed extends CaptureState {
  const CaptureSuppressed({required this.reason});
  final CaptureSuppressReason reason;
  @override
  String get label => 'Waiting — ${_reasonLabel(reason)}';

  static String _reasonLabel(CaptureSuppressReason r) => switch (r) {
        CaptureSuppressReason.none => '',
        CaptureSuppressReason.userDisabled => 'auto capture off',
        CaptureSuppressReason.multiplePeople => 'multiple people',
        CaptureSuppressReason.noFace => 'no face visible',
        CaptureSuppressReason.closedEyes => 'eyes closed',
        CaptureSuppressReason.lowLight => 'low light',
        CaptureSuppressReason.subjectMoving => 'subject moving',
        CaptureSuppressReason.cameraShake => 'camera shake',
        CaptureSuppressReason.poseUnstable => 'pose unstable',
        CaptureSuppressReason.lowConfidence => 'low AI confidence',
        CaptureSuppressReason.userExited => 'subject left frame',
        CaptureSuppressReason.manualCancel => 'cancelled',
        CaptureSuppressReason.captureFailed => 'capture failed',
      };
}

class CaptureError extends CaptureState {
  const CaptureError({required this.message});
  final String message;
  @override
  String get label => 'Error: $message';
}
