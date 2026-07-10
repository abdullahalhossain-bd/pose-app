import 'dart:math' as math;
import 'dart:typed_data';

import '../../pose/domain/entities/pose_sample.dart';

/// Pure geometry helpers for composition analysis. Stateless and
/// side-effect free — every function is trivially unit-testable.
class CompositionGeometry {
  const CompositionGeometry._();

  /// The four rule-of-thirds intersection points in normalized [0..1] space.
  static const List<({double x, double y})> thirdsIntersections = [
    (x: 1 / 3, y: 1 / 3),
    (x: 2 / 3, y: 1 / 3),
    (x: 1 / 3, y: 2 / 3),
    (x: 2 / 3, y: 2 / 3),
  ];

  /// Distance from a point to the nearest thirds intersection.
  static double distanceToNearestThirds(double x, double y) {
    var minDist = double.infinity;
    for (final p in thirdsIntersections) {
      final dx = x - p.x;
      final dy = y - p.y;
      final d = math.sqrt(dx * dx + dy * dy);
      if (d < minDist) minDist = d;
    }
    return minDist;
  }

  /// Subject center from a bounding box.
  static ({double x, double y})? subjectCenter(PoseSample? pose) {
    final b = pose?.boundingBox;
    if (b == null) return null;
    return (x: b.left + b.width / 2, y: b.top + b.height / 2);
  }

  /// Subject frame ratio (area of bbox / 1.0). Returns 0 if no bbox.
  static double subjectFrameRatio(PoseSample? pose) =>
      pose?.boundingBox?.area ?? 0;

  /// Headroom: distance from top of bbox to top of frame.
  static double headroom(PoseSample? pose) =>
      pose?.boundingBox?.top ?? 0;

  /// Footroom: distance from bottom of bbox to bottom of frame.
  static double footroom(PoseSample? pose) {
    final b = pose?.boundingBox;
    if (b == null) return 0;
    return 1 - b.bottom;
  }

  /// Left/right visual weight asymmetry. Returns |leftWeight - rightWeight| / total.
  /// Approximates by splitting the frame at x=0.5 and counting pixel
  /// energy (luminance variance) on each side.
  static double symmetryAsymmetry(Uint8List? luma, int width, int height) {
    if (luma == null || width == 0 || height == 0) return 0;

    final midX = width ~/ 2;
    double leftSum = 0, rightSum = 0;
    int leftCount = 0, rightCount = 0;

    // Sample every 4th pixel for speed.
    for (var y = 0; y < height; y += 4) {
      for (var x = 0; x < width; x += 4) {
        final idx = y * width + x;
        if (idx >= luma.length) continue;
        final v = luma[idx].toDouble();
        if (x < midX) {
          leftSum += v;
          leftCount++;
        } else {
          rightSum += v;
          rightCount++;
        }
      }
    }

    if (leftCount == 0 || rightCount == 0) return 0;
    final leftAvg = leftSum / leftCount;
    final rightAvg = rightSum / rightCount;
    final total = leftAvg + rightAvg;
    if (total == 0) return 0;
    return (leftAvg - rightAvg).abs() / total;
  }

  /// Detect horizon tilt angle in degrees. Returns null if no clear
  /// horizontal edge found.
  ///
  /// Algorithm: compute the average row-wise luminance gradient, find
  /// the row with the strongest horizontal edge, then estimate tilt
  /// by comparing edge position in the left half vs right half.
  static double? detectHorizonTiltDeg(Uint8List? luma, int width, int height) {
    if (luma == null || width < 16 || height < 16) return null;

    // Find the row with maximum horizontal gradient (likely the horizon).
    final rowGradients = List<double>.filled(height, 0);
    for (var y = 1; y < height - 1; y++) {
      double sum = 0;
      for (var x = 0; x < width; x += 4) {
        final idx = y * width + x;
        if (idx + width >= luma.length || idx - width < 0) continue;
        sum += (luma[idx + width] - luma[idx - width]).abs().toDouble();
      }
      rowGradients[y] = sum;
    }

    // Find peak row.
    int peakRow = 0;
    double peakVal = 0;
    for (var y = 0; y < height; y++) {
      if (rowGradients[y] > peakVal) {
        peakVal = rowGradients[y];
        peakRow = y;
      }
    }

    if (peakVal < width * 2) return null; // too weak — no clear horizon

    // Estimate tilt by finding the peak row separately in left/right halves.
    final leftHalf = List<double>.filled(height, 0);
    final rightHalf = List<double>.filled(height, 0);
    for (var y = 1; y < height - 1; y++) {
      double lSum = 0, rSum = 0;
      for (var x = 0; x < width ~/ 2; x += 4) {
        final idx = y * width + x;
        if (idx + width >= luma.length || idx - width < 0) continue;
        lSum += (luma[idx + width] - luma[idx - width]).abs().toDouble();
      }
      for (var x = width ~/ 2; x < width; x += 4) {
        final idx = y * width + x;
        if (idx + width >= luma.length || idx - width < 0) continue;
        rSum += (luma[idx + width] - luma[idx - width]).abs().toDouble();
      }
      leftHalf[y] = lSum;
      rightHalf[y] = rSum;
    }

    int leftPeak = 0;
    double leftPeakVal = 0;
    for (var y = 0; y < height; y++) {
      if (leftHalf[y] > leftPeakVal) {
        leftPeakVal = leftHalf[y];
        leftPeak = y;
      }
    }
    int rightPeak = 0;
    double rightPeakVal = 0;
    for (var y = 0; y < height; y++) {
      if (rightHalf[y] > rightPeakVal) {
        rightPeakVal = rightHalf[y];
        rightPeak = y;
      }
    }

    // If either half's peak is too weak, no horizon.
    if (leftPeakVal < width * 0.5 || rightPeakVal < width * 0.5) return null;

    // Tilt angle: arctan(dy / dx). dx = half frame width.
    final dy = (rightPeak - leftPeak).toDouble();
    final dx = (width ~/ 2).toDouble();
    return math.atan2(dy, dx) * 180 / math.pi;
  }

  /// Negative space: fraction of the frame that is "empty" (low
  /// variance). Approximated by counting pixels far from the subject
  /// bbox with low local variance.
  static double negativeSpaceRatio({
    required Uint8List? luma,
    required int width,
    required int height,
    required PoseSample? pose,
  }) {
    if (luma == null || width == 0 || height == 0) return 0.3; // neutral

    final b = pose?.boundingBox;
    // Sample 8x8 grid outside the subject bbox.
    const grid = 8;
    final cellW = width ~/ grid;
    final cellH = height ~/ grid;
    if (cellW == 0 || cellH == 0) return 0.3;

    int emptyCells = 0;
    int totalCells = 0;
    for (var gy = 0; gy < grid; gy++) {
      for (var gx = 0; gx < grid; gx++) {
        final cx = (gx + 0.5) / grid;
        final cy = (gy + 0.5) / grid;
        // Skip cells inside the subject bbox.
        if (b != null &&
            cx >= b.left &&
            cx <= b.right &&
            cy >= b.top &&
            cy <= b.bottom) {
          continue;
        }
        totalCells++;
        // Compute local variance.
        final x0 = gx * cellW;
        final y0 = gy * cellH;
        double sum = 0, sumSq = 0;
        int count = 0;
        for (var y = y0; y < y0 + cellH && y < height; y += 2) {
          for (var x = x0; x < x0 + cellW && x < width; x += 2) {
            final idx = y * width + x;
            if (idx >= luma.length) continue;
            final v = luma[idx].toDouble();
            sum += v;
            sumSq += v * v;
            count++;
          }
        }
        if (count == 0) continue;
        final mean = sum / count;
        final variance = sumSq / count - mean * mean;
        // Low variance → "empty" cell.
        if (variance < 100) emptyCells++;
      }
    }

    if (totalCells == 0) return 0.3;
    return emptyCells / totalCells;
  }
}
