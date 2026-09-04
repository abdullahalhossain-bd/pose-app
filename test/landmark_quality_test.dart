import 'package:flutter_test/flutter_test.dart';
import 'package:pose/core/pose/landmark_quality.dart';

class _Point {
  final double confidence;
  _Point(this.confidence);
}

class _Pose {
  final List<_Point> points;
  _Pose(this.points);
  List<_Point> getVisibleLandmarks({double threshold = .55}) => points.where((p) => p.confidence >= threshold).toList();
}

void main() {
  test('rejects incomplete body visibility', () {
    final quality = LandmarkQuality.fromPose(_Pose(List.generate(7, (_) => _Point(.95))));
    expect(quality.acceptable, isFalse);
    expect(quality.message, contains('whole body'));
  });

  test('accepts visible body and reports confidence', () {
    final quality = LandmarkQuality.fromPose(_Pose(List.generate(10, (_) => _Point(.85))));
    expect(quality.acceptable, isTrue);
    expect(quality.confidence, closeTo(.85, .001));
    expect(quality.message, 'Body detected');
  });
}
