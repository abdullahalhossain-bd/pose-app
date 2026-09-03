import 'package:flutter_test/flutter_test.dart';
import 'package:pose/core/pose/pose_landmark.dart';
import 'package:pose/core/pose/squat_analyzer.dart';

PosePoint p(String name, double x, double y) => PosePoint(name: name, x: x, y: y);

void main() {
  test('angle calculation returns 90 degrees', () {
    expect(PoseMath.angle(p('a', 0, 1), p('b', 0, 0), p('c', 1, 0)), closeTo(90, 0.001));
  });

  test('squat analyzer reaches bottom and returns to standing as a rep', () {
    final analyzer = SquatAnalyzer();
    analyzer.analyze(hip: p('hip', 0, 0), knee: p('knee', 0, 1), ankle: p('ankle', 0, 2));
    analyzer.analyze(hip: p('hip', 0, 0), knee: p('knee', 0, 1), ankle: p('ankle', 1.5, 0.8));
    analyzer.analyze(hip: p('hip', 0, 0), knee: p('knee', 0, 1), ankle: p('ankle', 1, 0));
    final result = analyzer.analyze(hip: p('hip', 0, 0), knee: p('knee', 0, 1), ankle: p('ankle', 0.1, 2));
    expect(result.phase, SquatPhase.standing);
    expect(result.validRep, isTrue);
  });
}
