import 'package:flutter/foundation.dart';

/// A single camera frame handed to the AI pipeline.
///
/// Domain layer is platform-agnostic — it does NOT depend on
/// `package:camera`. The data layer converts `CameraImage` → `AiFrame`.
@immutable
class AiFrame {
  const AiFrame({
    required this.id,
    required this.width,
    required this.height,
    required this.planes,
    required this.rotationDegrees,
    required this.timestamp,
    this.lux,
  });

  /// Monotonic sequence number assigned by the collector.
  final int id;

  final int width;
  final int height;

  /// Raw byte planes (YUV / NV21 / RGB depending on platform).
  final List<AiFramePlane> planes;

  /// Sensor rotation to apply before inference.
  final int rotationDegrees;

  /// Capture timestamp (microseconds since epoch).
  final int timestamp;

  /// Ambient light estimate, when available.
  final double? lux;

  bool get isEmpty => planes.isEmpty;
}

@immutable
class AiFramePlane {
  const AiFramePlane({required this.bytes, required this.width, required this.height, this.bytesPerPixel = 1});
  final Uint8List bytes;
  final int width;
  final int height;
  final int bytesPerPixel;
}
