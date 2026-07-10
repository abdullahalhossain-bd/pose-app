import 'dart:math' as math;
import 'dart:ui';

import '../../pose/domain/entities/pose_sample.dart';
import '../../pose/domain/enums/pose_landmark_type.dart';

/// Pure geometry helpers for pose analysis. Stateless and side-effect
/// free — every function is trivially unit-testable.
class PoseGeometry {
  const PoseGeometry._();

  /// Look up a landmark; returns null if missing or below 0 likelihood.
  static PoseLandmark? get(PoseSample pose, PoseLandmarkType type) {
    final l = pose[type];
    if (l == null || l.likelihood <= 0) return null;
    return l;
  }

  /// Angle at point [b] formed by [a] → [b] → [c], in degrees [0..360].
  /// Returns null if any point is missing.
  static double? angleAt(PoseSample p, PoseLandmarkType a, PoseLandmarkType b, PoseLandmarkType c) {
    final pa = get(p, a);
    final pb = get(p, b);
    final pc = get(p, c);
    if (pa == null || pb == null || pc == null) return null;

    final v1 = Offset(pa.x - pb.x, pa.y - pb.y);
    final v2 = Offset(pc.x - pb.x, pc.y - pb.y);
    final dot = v1.dx * v2.dx + v1.dy * v2.dy;
    final mag1 = v1.distance;
    final mag2 = v2.distance;
    if (mag1 == 0 || mag2 == 0) return null;
    final cos = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
    return math.acos(cos) * 180 / math.pi;
  }

  /// Signed tilt angle of the line a→b relative to horizontal, in
  /// degrees. Positive = left side higher (counterclockwise).
  static double? signedTiltDeg(PoseSample p, PoseLandmarkType left, PoseLandmarkType right) {
    final l = get(p, left);
    final r = get(p, right);
    if (l == null || r == null) return null;
    final dx = r.x - l.x;
    final dy = r.y - l.y;
    if (dx == 0) return null;
    // Negative dy = right is higher = positive tilt when left low.
    return -math.atan2(dy, dx) * 180 / math.pi;
  }

  /// Horizontal distance ratio: |x_left - x_right| / shoulder_distance.
  /// Used for stance width analysis.
  static double? horizontalRatio(
    PoseSample p,
    PoseLandmarkType left,
    PoseLandmarkType right,
    PoseLandmarkType refLeft,
    PoseLandmarkType refRight,
  ) {
    final l = get(p, left);
    final r = get(p, right);
    final rl = get(p, refLeft);
    final rr = get(p, refRight);
    if (l == null || r == null || rl == null || rr == null) return null;
    final refDist = (Offset(rl.x, rl.y) - Offset(rr.x, rr.y)).distance;
    if (refDist == 0) return null;
    return (l.x - r.x).abs() / refDist;
  }

  /// Distance between two landmarks, normalized by torso length
  /// (shoulder midpoint to hip midpoint).
  static double? normalizedDistance(
    PoseSample p,
    PoseLandmarkType a,
    PoseLandmarkType b,
  ) {
    final pa = get(p, a);
    final pb = get(p, b);
    final ls = get(p, PoseLandmarkType.leftShoulder);
    final rs = get(p, PoseLandmarkType.rightShoulder);
    final lh = get(p, PoseLandmarkType.leftHip);
    final rh = get(p, PoseLandmarkType.rightHip);
    if (pa == null || pb == null || ls == null || rs == null || lh == null || rh == null) {
      return null;
    }
    final shoulderMid = Offset((ls.x + rs.x) / 2, (ls.y + rs.y) / 2);
    final hipMid = Offset((lh.x + rh.x) / 2, (lh.y + rh.y) / 2);
    final torso = (shoulderMid - hipMid).distance;
    if (torso == 0) return null;
    return (Offset(pa.x, pa.y) - Offset(pb.x, pb.y)).distance / torso;
  }

  /// Average likelihood of the supplied landmarks — used to gate
  /// guidance emission when too few joints are reliably visible.
  static double averageConfidence(PoseSample p, List<PoseLandmarkType> types) {
    double sum = 0;
    int count = 0;
    for (final t in types) {
      final l = p[t];
      if (l != null) {
        sum += l.likelihood;
        count++;
      }
    }
    return count == 0 ? 0 : sum / count;
  }

  /// Bounding box from a list of landmarks (normalized).
  static (double minX, double minY, double maxX, double maxY)? bounds(
    PoseSample p,
    List<PoseLandmarkType> types,
  ) {
    double? minX, minY, maxX, maxY;
    for (final t in types) {
      final l = get(p, t);
      if (l == null) continue;
      minX = minX == null || l.x < minX ? l.x : minX;
      minY = minY == null || l.y < minY ? l.y : minY;
      maxX = maxX == null || l.x > maxX ? l.x : maxX;
      maxY = maxY == null || l.y > maxY ? l.y : maxY;
    }
    if (minX == null) return null;
    return (minX!, minY!, maxX!, maxY!);
  }
}
