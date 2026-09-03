import 'package:flutter_test/flutter_test.dart';
import 'package:ai_visual_director/features/guidance/application/attention_engine.dart';
import 'package:ai_visual_director/features/guidance/domain/guidance_message.dart';
import 'package:ai_visual_director/features/pose/domain/pose_landmark_data.dart';

PoseFrame _poseWithEars(double leftLikelihood, double rightLikelihood) {
  return PoseFrame(
    landmarks: {
      LandmarkType.leftEar: Landmark(
        type: LandmarkType.leftEar,
        x: 0.4,
        y: 0.3,
        likelihood: leftLikelihood,
      ),
      LandmarkType.rightEar: Landmark(
        type: LandmarkType.rightEar,
        x: 0.6,
        y: 0.3,
        likelihood: rightLikelihood,
      ),
    },
    confidence: 0.9,
  );
}

void main() {
  group('AttentionEngine — facing the camera (balanced ears)', () {
    test('returns null when both ears are equally visible', () {
      final engine = AttentionEngine();
      final result = engine.evaluate(_poseWithEars(0.85, 0.82));
      expect(result, isNull);
    });

    test('returns null when ear landmarks are missing entirely (no guess)', () {
      final engine = AttentionEngine();
      final result = engine.evaluate(PoseFrame.empty);
      expect(result, isNull);
    });
  });

  group('AttentionEngine — turned-away detection', () {
    test('does not flag on a single asymmetric frame (persistence required)', () {
      final engine = AttentionEngine();
      final result = engine.evaluate(_poseWithEars(0.9, 0.1));
      expect(result, isNull);
    });

    test('flags "face the camera" once asymmetry persists for the enter window', () {
      final engine = AttentionEngine();
      GuidanceMessage? result;
      for (var i = 0; i < 4; i++) {
        result = engine.evaluate(_poseWithEars(0.9, 0.1));
      }
      expect(result, isNotNull);
      expect(result!.category, GuidanceCategory.attention);
      expect(result.textEn, 'Face the camera');
    });

    test('keeps flagging while turned away, does not need to re-accumulate persistence', () {
      final engine = AttentionEngine();
      for (var i = 0; i < 4; i++) {
        engine.evaluate(_poseWithEars(0.9, 0.1));
      }
      final stillFlagged = engine.evaluate(_poseWithEars(0.9, 0.1));
      expect(stillFlagged, isNotNull);
    });

    test('clears only after balance persists for the clear window, not on a single good frame', () {
      final engine = AttentionEngine();
      for (var i = 0; i < 4; i++) {
        engine.evaluate(_poseWithEars(0.9, 0.1));
      }
      final firstGoodFrame = engine.evaluate(_poseWithEars(0.85, 0.82));
      expect(firstGoodFrame, isNotNull,
          reason: 'a single balanced frame should not immediately clear the flag');

      final secondGoodFrame = engine.evaluate(_poseWithEars(0.85, 0.82));
      expect(secondGoodFrame, isNull);
    });
  });

  group('AttentionEngine.reset()', () {
    test('reset() clears an active flag and persistence counters', () {
      final engine = AttentionEngine();
      for (var i = 0; i < 4; i++) {
        engine.evaluate(_poseWithEars(0.9, 0.1));
      }
      engine.reset();
      final result = engine.evaluate(_poseWithEars(0.9, 0.1));
      expect(result, isNull, reason: 'needs to re-accumulate persistence after reset');
    });
  });
}
