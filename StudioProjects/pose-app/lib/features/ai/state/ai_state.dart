import 'package:flutter/foundation.dart';

import '../config/ai_config.dart';

/// Sealed AI state tree. Exhaustive `switch` is enforced by the
/// compiler — adding a new state forces every consumer to handle it.
///
/// Design rule: states are VALUES, not behaviors. Transitions live in
/// [AiStateController] so the state machine has one owner.
sealed class AiState {
  const AiState();

  /// Whether the UI should render the AI overlay at all.
  bool get rendersOverlay => false;

  /// Whether the user can capture right now.
  bool get canCapture => false;

  /// One-line label for accessibility / debug overlays.
  String get label;
}

/// Pipeline is not running. User hasn't opened the camera or has
/// paused AI features.
class AiIdle extends AiState {
  const AiIdle();
  @override
  String get label => 'Idle';
}

/// Loading model, allocating isolate, warming up.
class AiPreparing extends AiState {
  const AiPreparing({this.progress = 0.0});
  final double progress;
  @override
  String get label => 'Preparing… ${(progress * 100).round()}%';
}

/// Pipeline is live and currently running inference on a frame.
class AiDetecting extends AiState {
  const AiDetecting({required this.sinceEpoch});
  final int sinceEpoch;
  @override
  bool get rendersOverlay => true;
  @override
  String get label => 'Detecting';
}

/// Inference finished; results are being interpreted into feedback.
class AiAnalyzing extends AiState {
  const AiAnalyzing();
  @override
  bool get rendersOverlay => true;
  @override
  String get label => 'Analyzing';
}

/// Subject is being tracked across frames (e.g. a person moving).
class AiTracking extends AiState {
  const AiTracking({this.trackId});
  final int? trackId;
  @override
  bool get rendersOverlay => true;
  @override
  String get label => 'Tracking';
}

/// Subject is detected but conditions for capture aren't yet met.
class AiReady extends AiState {
  const AiReady({required this.feedback});
  final List<AiFeedback> feedback;
  @override
  bool get rendersOverlay => true;
  @override
  String get label => 'Ready';
}

/// All checks pass — the user can capture.
class AiCaptureReady extends AiState {
  const AiCaptureReady({required this.feedback});
  final List<AiFeedback> feedback;
  @override
  bool get rendersOverlay => true;
  @override
  bool get canCapture => true;
  @override
  String get label => 'Capture ready';
}

/// Recoverable or terminal error. See [AiErrorKind] for the
/// classification; the controller decides whether to retry.
class AiError extends AiState {
  const AiError({
    required this.kind,
    required this.message,
    this.canRetry = true,
  });
  final AiErrorKind kind;
  final String message;
  final bool canRetry;
  @override
  String get label => 'Error: $message';
}

/// Subject lost — e.g. user walked out of frame.
class AiNoSubject extends AiState {
  const AiNoSubject();
  @override
  bool get rendersOverlay => false;
  @override
  String get label => 'No subject';
}

/// Ambient light below [AiConfig.lowLightLuxThreshold]. The pipeline
/// pauses detection (won't waste cycles) but keeps the camera live.
class AiLowLight extends AiState {
  const AiLowLight({required this.lux});
  final double lux;
  @override
  bool get rendersOverlay => false;
  @override
  String get label => 'Low light';
}

/// Camera permission was revoked at runtime.
class AiPermissionMissing extends AiState {
  const AiPermissionMissing();
  @override
  String get label => 'Camera permission missing';
}

/// Classification of [AiError] — drives the recovery strategy.
enum AiErrorKind {
  cameraUnavailable,
  frameDrop,
  inferenceFailed,
  pluginFailure,
  lowMemory,
  permissionRevoked,
  thermalPause,
  unknown,
}

/// A single piece of advice the AI surfaces to the user. Rendered as
/// a label in the overlay.
@immutable
class AiFeedback {
  const AiFeedback({
    required this.id,
    required this.message,
    required this.severity,
    required this.confidence,
    this.positionX,
    this.positionY,
  });

  final String id;
  final String message;
  final AiFeedbackSeverity severity;
  final double confidence;

  /// Normalized [0,1] position relative to the preview. Null = center.
  final double? positionX;
  final double? positionY;
}

enum AiFeedbackSeverity { info, suggestion, warning, critical }
