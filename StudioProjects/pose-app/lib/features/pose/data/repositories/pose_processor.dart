import '../../domain/entities/pose_sample.dart';
import '../../domain/entities/pose_state.dart';

/// Filters and classifies incoming pose detections, applying all
/// edge-case rules in one place so the pipeline stage stays thin.
///
/// Pure functions where possible — easy to unit test.
class PoseProcessor {
  PoseProcessor({
    this.minReliableLandmarks = 8,
    this.minConfidence = 0.5,
    this.tooCloseBoxArea = 0.85,
    this.tooFarBoxArea = 0.05,
    this.occludedRatio = 0.4,
  });

  /// Minimum number of reliable landmarks to consider a pose usable.
  /// 8 = shoulders + hips + knees + nose (roughly the visible upper body).
  final int minReliableLandmarks;

  /// Below this aggregate confidence, the pose is "low confidence".
  final double minConfidence;

  /// If the bounding box occupies more than this fraction of the frame,
  /// the subject is too close.
  final double tooCloseBoxArea;

  /// If less than this fraction, the subject is too far.
  final double tooFarBoxArea;

  /// If reliable landmarks < this fraction of total, the body is
  /// considered partially occluded.
  final double occludedRatio;

  /// Pick the best pose (highest confidence) from a batch.
  /// Returns null if the batch is empty.
  PoseSample? pickPrimary(List<PoseSample> poses) {
    if (poses.isEmpty) return null;
    final sorted = List<PoseSample>.from(poses)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    return sorted.first;
  }

  /// Compute edge-case context for a pose batch.
  PoseContext classify({
    required List<PoseSample> poses,
    required bool lowLight,
  }) {
    final primary = pickPrimary(poses);
    if (primary == null) {
      return PoseContext(
        multiplePeople: poses.length > 1,
        lowLight: lowLight,
      );
    }

    final reliable = primary.reliableCount;
    final total = primary.landmarks.length;
    final boxArea = primary.boundingBox?.area ?? 0;

    return PoseContext(
      tooClose: boxArea > tooCloseBoxArea,
      tooFar: boxArea < tooFarBoxArea && boxArea > 0,
      partialBody: reliable < minReliableLandmarks,
      occluded: total > 0 && reliable / total < occludedRatio,
      multiplePeople: poses.length > 1,
      lowLight: lowLight,
    );
  }

  /// Decide the next [PoseState] from the processed batch.
  PoseState decide({
    required List<PoseSample> tracked,
    required PoseContext context,
    required bool wasTracking,
  }) {
    if (tracked.isEmpty) {
      return wasTracking
          ? PoseLostTracking(
              sinceEpoch: DateTime.now().millisecondsSinceEpoch,
            )
          : const PoseNoPerson();
    }

    final primary = pickPrimary(tracked)!;

    if (context.partialBody || primary.confidence < minConfidence) {
      return PoseLowConfidence(confidence: primary.confidence);
    }

    if (wasTracking && primary.id >= 0) {
      return context.isOk
          ? PoseReady(
              trackId: primary.id,
              confidence: primary.confidence,
            )
          : PoseTracking(
              trackId: primary.id,
              confidence: primary.confidence,
            );
    }

    return PosePersonFound(confidence: primary.confidence);
  }
}
