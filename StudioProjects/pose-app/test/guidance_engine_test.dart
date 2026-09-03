import 'package:flutter_test/flutter_test.dart';
import 'package:ai_visual_director/features/guidance/application/guidance_engine.dart';
import 'package:ai_visual_director/features/guidance/domain/guidance_message.dart';
import 'package:ai_visual_director/features/pose/domain/pose_landmark_data.dart';

Landmark _lm(LandmarkType type, double x, double y, {double likelihood = 0.9}) {
  return Landmark(type: type, x: x, y: y, likelihood: likelihood);
}

/// A well-framed, centered, level pose — the baseline "everything is
/// fine" frame used across several tests below.
PoseFrame _goodPose() {
  return PoseFrame(
    landmarks: {
      LandmarkType.nose: _lm(LandmarkType.nose, 0.5, 0.3),
      LandmarkType.leftShoulder: _lm(LandmarkType.leftShoulder, 0.45, 0.45),
      LandmarkType.rightShoulder: _lm(LandmarkType.rightShoulder, 0.55, 0.45),
      LandmarkType.leftHip: _lm(LandmarkType.leftHip, 0.48, 0.6),
      LandmarkType.leftAnkle: _lm(LandmarkType.leftAnkle, 0.48, 0.9),
    },
    confidence: 0.9,
  );
}

PoseFrame _leftOfCenterPose() {
  return PoseFrame(
    landmarks: {
      LandmarkType.nose: _lm(LandmarkType.nose, 0.25, 0.3),
      LandmarkType.leftShoulder: _lm(LandmarkType.leftShoulder, 0.2, 0.4),
      LandmarkType.rightShoulder: _lm(LandmarkType.rightShoulder, 0.3, 0.4),
      LandmarkType.leftHip: _lm(LandmarkType.leftHip, 0.22, 0.6),
    },
    confidence: 0.9,
  );
}

PoseFrame _rightOfCenterPose() {
  return PoseFrame(
    landmarks: {
      LandmarkType.nose: _lm(LandmarkType.nose, 0.75, 0.3),
      LandmarkType.leftShoulder: _lm(LandmarkType.leftShoulder, 0.7, 0.4),
      LandmarkType.rightShoulder: _lm(LandmarkType.rightShoulder, 0.8, 0.4),
      LandmarkType.leftHip: _lm(LandmarkType.leftHip, 0.72, 0.6),
    },
    confidence: 0.9,
  );
}

void main() {
  group('GuidanceEngine confidence / detection gating', () {
    test('reports searching (not lowConfidence) on the very first low-confidence frame', () {
      final engine = GuidanceEngine();
      final pose = PoseFrame(
        landmarks: {LandmarkType.nose: _lm(LandmarkType.nose, 0.5, 0.2)},
        confidence: 0.2,
      );
      final result = engine.evaluate(pose);
      expect(result.state, PoseTrackingState.searching);
    });

    test('reports searching (not noPerson/lowConfidence) on the very first empty frame', () {
      final engine = GuidanceEngine();
      final result = engine.evaluate(PoseFrame.empty);
      expect(result.state, PoseTrackingState.searching);
    });

    test('escalates to lowConfidence only after the grace period elapses', () {
      final engine = GuidanceEngine();
      // First establish a real detection so losing it afterwards counts
      // as "lost tracking", not "never found anyone".
      engine.evaluate(_goodPose());
      final lowConf = PoseFrame(
        landmarks: {LandmarkType.nose: _lm(LandmarkType.nose, 0.5, 0.2)},
        confidence: 0.2,
      );

      GuidanceMessage last = engine.evaluate(lowConf);
      expect(last.state, PoseTrackingState.searching,
          reason: 'first bad frame right after a good one should still be "searching"');

      // Keep feeding low-confidence frames until the grace window is
      // exceeded (searching for up to 4 frames, per the engine's own
      // _searchingGraceFrames constant).
      for (var i = 0; i < 5; i++) {
        last = engine.evaluate(lowConf);
      }
      expect(last.state, PoseTrackingState.lowConfidence);
    });

    test('a single dropped frame after sustained good tracking does not immediately reset to noPerson', () {
      final engine = GuidanceEngine();
      for (var i = 0; i < 6; i++) {
        engine.evaluate(_goodPose());
      }
      final result = engine.evaluate(PoseFrame.empty);
      expect(result.state, isNot(PoseTrackingState.noPerson));
      expect(result.state, PoseTrackingState.searching);
    });
  });

  group('GuidanceEngine framing', () {
    test('asks user to step closer when subject is too small in frame', () {
      final engine = GuidanceEngine();
      final pose = PoseFrame(
        landmarks: {
          LandmarkType.nose: _lm(LandmarkType.nose, 0.5, 0.40),
          LandmarkType.leftAnkle: _lm(LandmarkType.leftAnkle, 0.5, 0.55),
          LandmarkType.leftShoulder: _lm(LandmarkType.leftShoulder, 0.48, 0.45),
          LandmarkType.rightShoulder: _lm(LandmarkType.rightShoulder, 0.52, 0.45),
        },
        confidence: 0.9,
      );
      final result = engine.evaluate(pose);
      expect(result.textEn, 'Step closer');
      expect(result.state, PoseTrackingState.guidance);
    });

    test('asks user to step back when subject is too large in frame', () {
      final engine = GuidanceEngine();
      final pose = PoseFrame(
        landmarks: {
          LandmarkType.nose: _lm(LandmarkType.nose, 0.5, 0.05),
          LandmarkType.leftAnkle: _lm(LandmarkType.leftAnkle, 0.5, 0.95),
          LandmarkType.leftShoulder: _lm(LandmarkType.leftShoulder, 0.48, 0.2),
          LandmarkType.rightShoulder: _lm(LandmarkType.rightShoulder, 0.52, 0.2),
        },
        confidence: 0.9,
      );
      final result = engine.evaluate(pose);
      expect(result.textEn, 'Step back a little');
    });
  });

  group('GuidanceEngine centering', () {
    test('asks user to move right when subject is left of center', () {
      final engine = GuidanceEngine();
      final result = engine.evaluate(_leftOfCenterPose());
      expect(result.textEn, 'Move slightly right');
    });

    test('asks user to move left when subject is right of center', () {
      final engine = GuidanceEngine();
      final result = engine.evaluate(_rightOfCenterPose());
      expect(result.textEn, 'Move slightly left');
    });
  });

  group('GuidanceEngine shoulder level', () {
    test('flags tilted shoulders when centered and well-framed', () {
      final engine = GuidanceEngine();
      final pose = PoseFrame(
        landmarks: {
          LandmarkType.nose: _lm(LandmarkType.nose, 0.5, 0.3),
          LandmarkType.leftShoulder: _lm(LandmarkType.leftShoulder, 0.45, 0.42),
          LandmarkType.rightShoulder: _lm(LandmarkType.rightShoulder, 0.55, 0.55),
          LandmarkType.leftHip: _lm(LandmarkType.leftHip, 0.48, 0.65),
        },
        confidence: 0.9,
      );
      final result = engine.evaluate(pose);
      expect(result.category, GuidanceCategory.pose);
    });
  });

  group('GuidanceEngine happy path / hold', () {
    test('shows a transient "ready" before promoting to hold', () {
      final engine = GuidanceEngine();
      final first = engine.evaluate(_goodPose());
      expect(first.state, PoseTrackingState.ready);
    });

    test('promotes to hold only after several consecutive good frames', () {
      final engine = GuidanceEngine();
      GuidanceMessage? result;
      for (var i = 0; i < 4; i++) {
        result = engine.evaluate(_goodPose());
        expect(result.state, isNot(PoseTrackingState.hold),
            reason: 'should not hold before the debounce window elapses');
      }
      result = engine.evaluate(_goodPose());
      expect(result.state, PoseTrackingState.hold);
      expect(result.isConfirmation, true);
    });

    test('a single bad frame resets the hold streak', () {
      final engine = GuidanceEngine();
      for (var i = 0; i < 5; i++) {
        engine.evaluate(_goodPose());
      }
      // Now hold. A correction should reset the streak.
      engine.evaluate(_leftOfCenterPose());
      for (var i = 0; i < 4; i++) {
        final r = engine.evaluate(_goodPose());
        expect(r.state, isNot(PoseTrackingState.hold));
      }
    });
  });

  group('GuidanceEngine debounce (anti-flicker)', () {
    test('does not immediately switch from "move right" to "move left" on a single opposite frame', () {
      final engine = GuidanceEngine();
      final firstResult = engine.evaluate(_leftOfCenterPose());
      expect(firstResult.textEn, 'Move slightly right');

      // One single frame suggesting the opposite correction should NOT
      // flip the displayed message yet — this is the exact flicker bug
      // the debounce logic exists to prevent.
      final flickerResult = engine.evaluate(_rightOfCenterPose());
      expect(flickerResult.textEn, 'Move slightly right',
          reason: 'a single opposing frame must not flip guidance immediately');
    });

    test('does switch after the opposite correction persists for the debounce window', () {
      final engine = GuidanceEngine();
      engine.evaluate(_leftOfCenterPose());

      GuidanceMessage? last;
      for (var i = 0; i < 3; i++) {
        last = engine.evaluate(_rightOfCenterPose());
      }
      expect(last!.textEn, 'Move slightly left');
    });

    test('centered pose after a correction requires clearing the hysteresis band, not just the raw threshold', () {
      final engine = GuidanceEngine();
      engine.evaluate(_leftOfCenterPose());

      // A pose just inside the original 0.08 enter-threshold but outside
      // the tighter 0.05 clear-threshold should still show a correction
      // (hysteresis), not flip straight to "ready".
      final borderlinePose = PoseFrame(
        landmarks: {
          LandmarkType.nose: _lm(LandmarkType.nose, 0.435, 0.3),
          LandmarkType.leftShoulder: _lm(LandmarkType.leftShoulder, 0.4, 0.4),
          LandmarkType.rightShoulder: _lm(LandmarkType.rightShoulder, 0.47, 0.4),
          LandmarkType.leftHip: _lm(LandmarkType.leftHip, 0.42, 0.6),
        },
        confidence: 0.9,
      );
      final result = engine.evaluate(borderlinePose);
      expect(result.category, GuidanceCategory.position);
    });
  });

  group('GuidanceEngine error handling', () {
    test('onError() returns the error state and resets history', () {
      final engine = GuidanceEngine();
      for (var i = 0; i < 5; i++) {
        engine.evaluate(_goodPose());
      }
      final result = engine.onError();
      expect(result.state, PoseTrackingState.error);

      // History reset means the next good frame starts the hold streak
      // over, not resuming mid-streak.
      final afterError = engine.evaluate(_goodPose());
      expect(afterError.state, PoseTrackingState.ready);
    });
  });

  group('GuidanceEngine reset()', () {
    test('reset() clears hold streak and correction history', () {
      final engine = GuidanceEngine();
      for (var i = 0; i < 5; i++) {
        engine.evaluate(_goodPose());
      }
      engine.reset();
      final afterReset = engine.evaluate(_goodPose());
      expect(afterReset.state, PoseTrackingState.ready);
    });
  });
}
