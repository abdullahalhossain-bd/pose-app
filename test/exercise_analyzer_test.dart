import 'package:flutter_test/flutter_test.dart';
import 'package:pose/core/exercise/lunge_analyzer.dart';
import 'package:pose/core/exercise/push_up_analyzer.dart';
import 'package:pose/core/pose/pose_landmark.dart';

PosePoint p(String name, double x, double y) =>
    PosePoint(name: name, x: x, y: y, confidence: 1);

List<PosePoint> pushUp(double elbowY) => [
      p('leftShoulder', 0, 0),
      p('leftElbow', 0, elbowY),
      p('leftWrist', 0, 2 * elbowY),
      p('leftHip', 1, 0.8),
      p('leftAnkle', 2, 0.8),
    ];

List<PosePoint> lunge(double kneeX) => [
      p('leftShoulder', 0, -1),
      p('leftHip', 0, 0),
      p('leftKnee', kneeX, 1),
      p('leftAnkle', 0, 2),
    ];

void main() {
  test('push-up analyzer rejects incomplete landmarks', () {
    final result = PushUpAnalyzer().analyze([p('leftShoulder', 0, 0)]);
    expect(result.validRep, isFalse);
    expect(result.score, 0);
  });

  test('push-up analyzer requires a bottom before counting a rep', () {
    final analyzer = PushUpAnalyzer();
    analyzer.analyze(pushUp(0.5));
    analyzer.analyze(pushUp(0.9));
    analyzer.analyze(pushUp(0.9));
    analyzer.analyze(pushUp(0.6));
    analyzer.analyze(pushUp(0.6));
    final result = analyzer.analyze(pushUp(0.5));
    expect(result.validRep, isTrue);
  });

  test('lunge analyzer rejects incomplete landmarks', () {
    final result = LungeAnalyzer().analyze([p('leftHip', 0, 0)]);
    expect(result.validRep, isFalse);
    expect(result.score, 0);
  });

  test('analyzers reset their rep state', () {
    final analyzer = PushUpAnalyzer();
    analyzer.analyze(pushUp(0.5));
    analyzer.reset();
    final result = analyzer.analyze(pushUp(0.5));
    expect(result.validRep, isFalse);
  });
}
