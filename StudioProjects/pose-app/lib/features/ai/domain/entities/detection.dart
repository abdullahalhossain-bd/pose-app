import 'dart:ui' show Offset, Size;

import 'package:flutter/foundation.dart';

/// Normalized coordinate [0..1] relative to the input frame.
@immutable
class NormalizedPoint {
  const NormalizedPoint(this.x, this.y);
  final double x;
  final double y;

  Offset toOffset(Size size) => Offset(x * size.width, y * size.height);

  static const zero = NormalizedPoint(0, 0);
}

/// Generic bounding box. Coordinates are normalized [0..1].
@immutable
class BoundingBox {
  const BoundingBox({
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
}

/// A single keypoint (joint, eye, landmark). Indices follow the
/// model's own convention (e.g. COCO 17 for MoveNet).
@immutable
class Keypoint {
  const Keypoint({
    required this.x,
    required this.y,
    required this.confidence,
    this.label,
  });

  final double x;
  final double y;
  final double confidence;
  final String? label;
}

/// Pair of keypoint indices connected by a line — e.g. (5, 7) for
/// the left shoulder → left elbow.
@immutable
class PoseConnection {
  const PoseConnection(this.a, this.b);
  final int a;
  final int b;
}

/// Generic detection result. Specialized models (pose, scene, face)
/// extend this — the pipeline never breaks the Liskov substitution.
@immutable
class DetectionResult {
  const DetectionResult({
    required this.kind,
    required this.confidence,
    this.boundingBox,
    this.keypoints = const [],
    this.label,
    this.metadata = const {},
    this.timestamp = 0,
  });

  /// E.g. 'person', 'face', 'scene/outdoor'.
  final String kind;
  final double confidence;
  final BoundingBox? boundingBox;
  final List<Keypoint> keypoints;
  final String? label;
  final Map<String, Object?> metadata;
  final int timestamp;

  bool get isReliable => confidence >= 0.3;
}
