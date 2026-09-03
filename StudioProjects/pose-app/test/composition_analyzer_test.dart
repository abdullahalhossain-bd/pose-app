import 'package:flutter_test/flutter_test.dart';
import 'package:ai_visual_director/features/composition/application/composition_analyzer.dart';
import 'package:ai_visual_director/features/composition/domain/composition_message.dart';
import 'package:ai_visual_director/features/pose/domain/pose_landmark_data.dart';

Landmark _lm(LandmarkType type, double x, double y) {
  return Landmark(type: type, x: x, y: y, likelihood: 0.9);
}

PoseFrame _poseWithNoseY(double y) {
  return PoseFrame(
    landmarks: {LandmarkType.nose: _lm(LandmarkType.nose, 0.5, y)},
    confidence: 0.9,
  );
}

void main() {
  group('CompositionAnalyzer.headroomOf', () {
    test('returns the nose y-coordinate as the headroom proxy', () {
      const analyzer = CompositionAnalyzer();
      final pose = _poseWithNoseY(0.15);
      expect(analyzer.headroomOf(pose), 0.15);
    });

    test('returns null when nose was not detected', () {
      const analyzer = CompositionAnalyzer();
      final result = analyzer.headroomOf(PoseFrame.empty);
      expect(result, isNull);
    });
  });

  group('CompositionEngine classification', () {
    test('unknown when nose is missing', () {
      final engine = CompositionEngine();
      final result = engine.classify(PoseFrame.empty);
      expect(result.condition, CompositionCondition.unknown);
    });

    test('good for headroom comfortably within range', () {
      final engine = CompositionEngine();
      final result = engine.classify(_poseWithNoseY(0.15));
      expect(result.condition, CompositionCondition.good);
    });

    test('insufficientHeadroom when the head is very close to the top edge', () {
      final engine = CompositionEngine();
      final result = engine.classify(_poseWithNoseY(0.01));
      expect(result.condition, CompositionCondition.insufficientHeadroom);
    });

    test('excessiveHeadroom when there is far too much space above the head', () {
      final engine = CompositionEngine();
      final result = engine.classify(_poseWithNoseY(0.35));
      expect(result.condition, CompositionCondition.excessiveHeadroom);
    });

    test('hysteresis: does not clear insufficientHeadroom until past the wider clear threshold', () {
      final engine = CompositionEngine();
      engine.classify(_poseWithNoseY(0.01)); // insufficient

      // Just above the raw enter threshold (0.04) but below the clear
      // threshold (0.06) should still read as insufficient.
      final stillBad = engine.classify(_poseWithNoseY(0.05));
      expect(stillBad.condition, CompositionCondition.insufficientHeadroom);

      final cleared = engine.classify(_poseWithNoseY(0.10));
      expect(cleared.condition, CompositionCondition.good);
    });

    test('reset() clears hysteresis state', () {
      final engine = CompositionEngine();
      engine.classify(_poseWithNoseY(0.01));
      engine.reset();
      final result = engine.classify(_poseWithNoseY(0.05));
      // Without prior "insufficient" state, 0.05 is above the enter
      // threshold (0.04) so it should read as good directly.
      expect(result.condition, CompositionCondition.good);
    });
  });
}
