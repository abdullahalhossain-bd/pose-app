import 'dart:math' as math;
import 'dart:typed_data';

import '../../pose/domain/entities/pose_sample.dart';
import '../../pose/domain/enums/pose_landmark_type.dart';

/// Detects motion across consecutive frames using two signals:
/// 1. **Subject motion** — average displacement of reliable landmarks.
/// 2. **Camera shake** — pixel-level frame differencing on the
///    luminance plane (cheap; no RGB conversion).
///
/// Outputs a stability score [0..1] where 1 = rock-solid and 0 = lots
/// of motion. The capture engine multiplies this into its overall
/// score via the `weightStability` factor.
class StabilityDetector {
  StabilityDetector({
    required this.poseDeltaSuppressDeg,
    required this.cameraMotionSuppressPx,
    required this.windowFrames,
  });

  final double poseDeltaSuppressDeg;
  final double cameraMotionSuppressPx;
  final int windowFrames;

  // Rolling window of per-frame stability scores.
  final List<double> _window = [];

  // Previous landmark positions for delta computation.
  final Map<PoseLandmarkType, (double, double)> _prevLandmarks = {};

  // Previous luminance plane bytes for pixel-diff.
  Uint8List? _prevLuma;

  /// Process a frame. [luma] is the Y plane of the camera image
  /// (downsampled is fine — we only need a motion estimate).
  double process({
    PoseSample? pose,
    Uint8List? luma,
    int width = 0,
    int height = 0,
  }) {
    final poseStability = _poseStability(pose);
    final cameraStability = _cameraStability(luma, width, height);

    // Combine: take the minimum so either signal can veto capture.
    final combined = math.min(poseStability, cameraStability);

    _window.add(combined);
    if (_window.length > windowFrames) {
      _window.removeRange(0, _window.length - windowFrames);
    }

    // Average over the window — a single bad frame shouldn't kill
    // the score, but sustained motion should.
    return _window.isEmpty
        ? 0
        : _window.reduce((a, b) => a + b) / _window.length;
  }

  double _poseStability(PoseSample? pose) {
    if (pose == null) {
      _prevLandmarks.clear();
      return 0.3; // no pose → mildly unstable (don't fully veto)
    }

    double totalDelta = 0;
    int count = 0;
    for (final lm in pose.landmarks) {
      if (!lm.isReliable) continue;
      final prev = _prevLandmarks[lm.type];
      if (prev != null) {
        final dx = lm.x - prev.$1;
        final dy = lm.y - prev.$2;
        totalDelta += math.sqrt(dx * dx + dy * dy);
        count++;
      }
      _prevLandmarks[lm.type] = (lm.x, lm.y);
    }

    if (count == 0) return 1.0; // no comparable landmarks → assume stable

    final avgDelta = totalDelta / count;
    // Convert to a 0..1 score: 0 delta → 1.0, delta >= suppressDeg → 0.0
    final normalizedDelta = avgDelta / (poseDeltaSuppressDeg / 180);
    return (1.0 - normalizedDelta).clamp(0.0, 1.0);
  }

  double _cameraStability(Uint8List? luma, int width, int height) {
    if (luma == null || width == 0 || height == 0 || _prevLuma == null) {
      _prevLuma = luma;
      return 1.0; // first frame — assume stable
    }

    // Sample 8×8 grid for cheap diff.
    const gridSize = 8;
    final cellW = width ~/ gridSize;
    final cellH = height ~/ gridSize;
    if (cellW == 0 || cellH == 0) return 1.0;

    double totalDiff = 0;
    int samples = 0;
    for (var gy = 0; gy < gridSize; gy++) {
      for (var gx = 0; gx < gridSize; gx++) {
        final x = gx * cellW + cellW ~/ 2;
        final y = gy * cellH + cellH ~/ 2;
        if (y >= height || x >= width) continue;
        final idx = y * width + x;
        if (idx >= luma.length || idx >= _prevLuma!.length) continue;
        totalDiff += (luma[idx] - _prevLuma![idx]).abs().toDouble();
        samples++;
      }
    }

    _prevLuma = luma;

    if (samples == 0) return 1.0;
    final avgDiff = totalDiff / samples;
    // Map [0..cameraMotionSuppressPx] → [1..0]
    return (1.0 - avgDiff / cameraMotionSuppressPx).clamp(0.0, 1.0);
  }

  void reset() {
    _window.clear();
    _prevLandmarks.clear();
    _prevLuma = null;
  }
}
