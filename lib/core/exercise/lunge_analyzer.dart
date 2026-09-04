import 'dart:math' as math;
import 'package:pose/core/pose/pose_landmark.dart';
import 'exercise_definition.dart';

class LungeAnalyzer implements ExerciseAnalyzer {
  ExercisePhase _phase = ExercisePhase.ready;
  bool _reachedBottom = false;
  int _bottomFrames = 0;
  int _upFrames = 0;

  @override String get id => 'lunge';
  @override String get displayName => 'Lunge';
  @override List<String> get setupTips => const [
    'Use a side view and keep your whole body visible.',
    'Leave space in front of and behind your feet.',
    'Move slowly so both knees stay visible.'
  ];

  @override
  ExerciseFeedback analyze(List<PosePoint> p) {
    final hip = _find(p, 'leftHip');
    final knee = _find(p, 'leftKnee');
    final ankle = _find(p, 'leftAnkle');
    final shoulder = _find(p, 'leftShoulder');
    if ([hip, knee, ankle, shoulder].any((x) => x == null)) {
      return const ExerciseFeedback(phase: ExercisePhase.ready, validRep: false, score: 0, scoreLabel: 'Need full body');
    }
    final angle = PoseMath.angle(hip!, knee!, ankle!);
    final torso = _torsoLean(shoulder!, hip);
    final score = ((100 - (angle - 90).abs() * 1.4).clamp(0, 100) * .7 + (100 - math.max(0, torso - 15) * 3).clamp(0, 100) * .3).round().clamp(0, 100);
    var valid = false;

    if (angle > 155) {
      if (_phase == ExercisePhase.ascending && _reachedBottom) {
        valid = true;
        _reachedBottom = false;
      }
      _phase = ExercisePhase.ready;
    } else if (_phase == ExercisePhase.ready && angle < 145) {
      _phase = ExercisePhase.descending;
    } else if (_phase == ExercisePhase.descending) {
      if (angle <= 105) {
        _bottomFrames++;
        if (_bottomFrames >= 2) {
          _reachedBottom = true;
          _phase = ExercisePhase.bottom;
          _bottomFrames = 0;
        }
      }
    } else if (_phase == ExercisePhase.bottom) {
      if (angle >= 120) {
        _upFrames++;
        if (_upFrames >= 2) {
          _phase = ExercisePhase.ascending;
          _upFrames = 0;
        }
      } else { _upFrames = 0; }
    }

    final message = torso > 25
        ? 'Keep your torso controlled and tall.'
        : angle <= 105
            ? 'Good depth — drive back up with control.'
            : 'Lower smoothly and keep your front knee controlled.';
    return ExerciseFeedback(phase: _phase, validRep: valid, score: score, scoreLabel: _label(score), messages: [message]);
  }

  double _torsoLean(PosePoint shoulder, PosePoint hip) {
    final dx = shoulder.x - hip.x;
    final dy = shoulder.y - hip.y;
    return (math.atan2(dx.abs(), dy.abs()) * 180 / math.pi);
  }
  PosePoint? _find(List<PosePoint> p, String name) { for (final x in p) { if (x.name == name && x.confidence >= .55) return x; } return null; }
  String _label(int s) => s >= 90 ? 'Excellent' : s >= 75 ? 'Good' : s >= 55 ? 'Needs work' : 'Adjust form';
  @override void reset() { _phase = ExercisePhase.ready; _reachedBottom = false; _bottomFrames = 0; _upFrames = 0; }
}
