import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/ai_frame.dart';
import '../entities/detection.dart';

/// Contract for any inference backend — TFLite, MLKit, MediaPipe,
/// cloud REST, even a deterministic stub for tests.
///
/// Day 9+ adds concrete implementations:
///   - `TfLiteInferenceBackend` (on-device)
///   - `MlKitInferenceBackend` (Google MLKit)
///   - `RestInferenceBackend` (cloud fallback for low-end devices)
///
/// The pipeline depends on this interface ONLY, so swapping backends
/// never touches the pipeline.
abstract class InferenceBackend {
  /// Human-readable identifier — used in logs + debug overlay.
  String get identifier;

  /// Whether inference runs off the UI isolate.
  bool get runsOnIsolate;

  /// Initialize model / interpreter. Called once at pipeline start.
  Future<Either<Failure, void>> initialize();

  /// Run inference on a single preprocessed frame. MUST be thread-safe
  /// if the pipeline calls it concurrently (it shouldn't — the pipeline
  /// serializes calls — but backends must not assume single-threading).
  Future<Either<Failure, List<DetectionResult>>> infer(AiFrame frame);

  /// Release native resources. Idempotent.
  Future<void> dispose();
}

/// What the backend reports after `initialize()`.
class InferenceCapabilities {
  const InferenceCapabilities({
    required this.supportsKeypoints,
    required this.supportsBoundingBoxes,
    required this.supportsClassification,
    this.maxDetections = 5,
  });

  final bool supportsKeypoints;
  final bool supportsBoundingBoxes;
  final bool supportsClassification;
  final int maxDetections;
}
