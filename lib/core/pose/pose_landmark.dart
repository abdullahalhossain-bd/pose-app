import 'dart:math' as math;

class PosePoint {
  final String name;
  final double x;
  final double y;
  final double confidence;

  const PosePoint({required this.name, required this.x, required this.y, this.confidence = 1});
}

class PoseMath {
  static double angle(PosePoint a, PosePoint b, PosePoint c) {
    final abx = a.x - b.x;
    final aby = a.y - b.y;
    final cbx = c.x - b.x;
    final cby = c.y - b.y;
    final dot = abx * cbx + aby * cby;
    final mag = math.sqrt(abx * abx + aby * aby) * math.sqrt(cbx * cbx + cby * cby);
    if (mag == 0) return 180;
    final value = (dot / mag).clamp(-1.0, 1.0);
    return math.acos(value) * 180 / math.pi;
  }
}
