/// The subset of body landmarks we currently reason about for guidance.
///
/// Deliberately a small, stable enum rather than exposing ML Kit's full
/// 33-point set directly to the UI/guidance layers — this is the seam
/// that lets us swap pose-detection backends later (e.g. a lighter model
/// for low-end devices) without touching guidance logic.
enum LandmarkType {
  nose,
  leftEye,
  rightEye,
  leftEar,
  rightEar,
  leftShoulder,
  rightShoulder,
  leftHip,
  rightHip,
  leftKnee,
  rightKnee,
  leftAnkle,
  rightAnkle,
}

/// A single landmark position, normalized to the 0..1 range of the
/// camera preview frame (not raw pixel coordinates) so downstream
/// consumers never need to know frame resolution.
class Landmark {
  final LandmarkType type;
  final double x;
  final double y;

  /// ML Kit's per-landmark detection confidence, 0..1.
  final double likelihood;

  const Landmark({
    required this.type,
    required this.x,
    required this.y,
    required this.likelihood,
  });
}

/// One detected person's full pose for a single frame.
class PoseFrame {
  final Map<LandmarkType, Landmark> landmarks;

  /// Overall confidence heuristic (mean of key-landmark likelihoods).
  /// Guidance logic treats anything below [GuidanceEngine.minConfidence]
  /// as "not confident enough to instruct" per the product's trust
  /// principle: never guess when uncertain.
  final double confidence;

  const PoseFrame({required this.landmarks, required this.confidence});

  Landmark? get(LandmarkType type) => landmarks[type];

  bool has(LandmarkType type) => landmarks.containsKey(type);

  static const PoseFrame empty = PoseFrame(landmarks: {}, confidence: 0);
}
