import 'package:flutter/foundation.dart';

import '../enums/pose_landmark_type.dart';

/// A single detected body landmark.
///
/// Coordinates are normalized [0..1] relative to the AI input image.
/// Use [PoseCoordinateMapper] to convert to screen / overlay space —
/// widgets MUST NOT consume these raw values directly.
@immutable
class PoseLandmark {
  const PoseLandmark({
    required this.type,
    required this.x,
    required this.y,
    required this.z,
    required this.likelihood,
  });

  final PoseLandmarkType type;

  /// Normalized [0..1] horizontal position in AI input space.
  final double x;

  /// Normalized [0..1] vertical position in AI input space.
  final double y;

  /// Depth relative to hip midpoint (negative = towards camera).
  /// Only populated by ML Kit; other backends leave 0.
  final double z;

  /// ML Kit's per-landmark confidence [0..1]. Below 0.5 = unreliable.
  final double likelihood;

  bool get isReliable => likelihood >= 0.5;
}

/// A full body pose: 33 landmarks + an aggregate confidence score.
@immutable
class PoseSample {
  const PoseSample({
    required this.id,
    required this.landmarks,
    required this.confidence,
    required this.timestamp,
    this.boundingBox,
  });

  /// Track ID assigned by [PoseTracker]. -1 = untracked.
  final int id;

  final List<PoseLandmark> landmarks;

  /// Aggregate confidence: mean of reliable landmarks' likelihood.
  final double confidence;

  final int timestamp; // microseconds since epoch

  /// Normalized bounding box around all reliable landmarks.
  final PoseBoundingBox? boundingBox;

  bool get isEmpty => landmarks.isEmpty;

  /// Number of landmarks with likelihood >= 0.5.
  int get reliableCount =>
      landmarks.where((l) => l.isReliable).length;

  /// Lookup by type. Returns null if not present.
  PoseLandmark? operator [](PoseLandmarkType t) {
    for (final l in landmarks) {
      if (l.type == t) return l;
    }
    return null;
  }
}

@immutable
class PoseBoundingBox {
  const PoseBoundingBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  double get right => left + width;
  double get bottom => top + height;
  double get area => width * height;

  /// Intersection-over-Union with another box, used by the tracker.
  double iou(PoseBoundingBox other) {
    final x1 = left > other.left ? left : other.left;
    final y1 = top > other.top ? top : other.top;
    final x2 = right < other.right ? right : other.right;
    final y2 = bottom < other.bottom ? bottom : other.bottom;
    final interW = (x2 - x1).clamp(0.0, 1.0);
    final interH = (y2 - y1).clamp(0.0, 1.0);
    final inter = interW * interH;
    final union = area + other.area - inter;
    return union <= 0 ? 0 : inter / union;
  }
}
