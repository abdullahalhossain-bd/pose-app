import 'dart:math' as math;

class SquatLandmarkMetrics {
  final double? rightKneeAngle;
  final double? kneeAlignment;
  final double? torsoLean;

  const SquatLandmarkMetrics({this.rightKneeAngle, this.kneeAlignment, this.torsoLean});

  factory SquatLandmarkMetrics.fromPose(dynamic pose) {
    dynamic point(dynamic type) {
      try { return pose.getLandmark(type); } catch (_) { return null; }
    }
    double? xy(dynamic p, String axis) {
      if (p == null) return null;
      try { return (axis == 'x' ? p.x : p.y as num).toDouble(); } catch (_) { return null; }
    }
    final lh = point(LandmarkType.leftHip), lk = point(LandmarkType.leftKnee), la = point(LandmarkType.leftAnkle);
    final rh = point(LandmarkType.rightHip), rk = point(LandmarkType.rightKnee), ra = point(LandmarkType.rightAnkle);
    final rightAngle = (rh != null && rk != null && ra != null) ? _angle(rh, rk, ra, xy) : null;
    double? alignment;
    if (lk != null && la != null && lh != null) {
      final dx = (xy(lk, 'x')! - xy(la, 'x')!).abs();
      final span = (xy(lh, 'x')! - xy(la, 'x')!).abs().clamp(.05, 2.0);
      alignment = (100 - (dx / span) * 180).clamp(0, 100);
    }
    double? torso;
    final ls = point(LandmarkType.leftShoulder), rs = point(LandmarkType.rightShoulder);
    if (ls != null && rs != null && lh != null && rh != null) {
      final sx = (xy(ls, 'x')! + xy(rs, 'x')!) / 2;
      final sy = (xy(ls, 'y')! + xy(rs, 'y')!) / 2;
      final hx = (xy(lh, 'x')! + xy(rh, 'x')!) / 2;
      final hy = (xy(lh, 'y')! + xy(rh, 'y')!) / 2;
      torso = math.atan2((sx - hx).abs(), (sy - hy).abs()) * 180 / math.pi;
    }
    return SquatLandmarkMetrics(rightKneeAngle: rightAngle, kneeAlignment: alignment, torsoLean: torso);
  }

  static double _angle(dynamic a, dynamic b, dynamic c, double? Function(dynamic, String) xy) {
    final abx = xy(a, 'x')! - xy(b, 'x')!, aby = xy(a, 'y')! - xy(b, 'y')!;
    final cbx = xy(c, 'x')! - xy(b, 'x')!, cby = xy(c, 'y')! - xy(b, 'y')!;
    final den = math.sqrt(abx * abx + aby * aby) * math.sqrt(cbx * cbx + cby * cby);
    if (den == 0) return 180;
    return math.acos(((abx * cbx + aby * cby) / den).clamp(-1.0, 1.0)) * 180 / math.pi;
  }
}
