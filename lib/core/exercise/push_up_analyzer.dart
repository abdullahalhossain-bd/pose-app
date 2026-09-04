import 'dart:math' as math;
import 'package:pose/core/pose/pose_landmark.dart';
import 'exercise_definition.dart';

class PushUpAnalyzer implements ExerciseAnalyzer {
  ExercisePhase _phase = ExercisePhase.ready;
  bool _reachedBottom = false;
  int _bottomFrames = 0;
  int _upFrames = 0;

  @override
  String get id => 'push_up';
  @override
  String get displayName => 'Push-up';
  @override
  List<String> get setupTips => const [
        'Use a side view with your whole body visible.',
        'Keep your hands and feet inside the frame.',
        'Keep your body in a straight line.'
      ];

  @override
  ExerciseFeedback analyze(List<PosePoint> p) {
    final shoulder = _find(p, 'leftShoulder');
    final elbow = _find(p, 'leftElbow');
    final wrist = _find(p, 'leftWrist');
    final hip = _find(p, 'leftHip');
    final ankle = _find(p, 'leftAnkle');
    if ([shoulder, elbow, wrist, hip, ankle].any((x) => x == null)) {
      return const ExerciseFeedback(phase: ExercisePhase.ready, validRep: false, score: 0, scoreLabel: 'Need full body');
    }

    final elbowAngle = PoseMath.angle(shoulder!, elbow!, wrist!);
    final bodyLine = _lineAngle(shoulder, hip!, ankle!);
    final score = _score(elbowAngle, bodyLine);
    var valid = false;

    if (elbowAngle > 150) {
      if (_phase == ExercisePhase.ascending && _reachedBottom) {
        valid = true;
        _reachedBottom = false;
      }
      _phase = ExercisePhase.ready;
    } else if (_phase == ExercisePhase.ready && elbowAngle < 145) {
      _phase = ExercisePhase.descending;
    } else if (_phase == ExercisePhase.descending) {
      if (elbowAngle <= 100) {
        _bottomFrames++;
        if (_bottomFrames >= 2) {
          _reachedBottom = true;
          _phase = ExercisePhase.bottom;
          _bottomFrames = 0;
        }
      }
    } else if (_phase == ExercisePhase.bottom) {
      if (elbowAngle >= 115) {
        _upFrames++;
        if (_upFrames >= 2) {
          _phase = ExercisePhase.ascending;
          _upFrames = 0;
        }
      } else {
        _upFrames = 0;
      }
    }

    final message = bodyLine > 18
        ? 'Keep your hips and shoulders in a straighter line.'
        : elbowAngle > 145
            ? 'Lower with control.'
            : elbowAngle <= 100
                ? 'Good depth — press up smoothly.'
                : 'Keep your elbows controlled.';
    return ExerciseFeedback(phase: _phase, validRep: valid, score: score, scoreLabel: _label(score), messages: [message]);
  }

  int _score(double elbow, double bodyLine) {
    final depth = (100 - (elbow - 90).abs() * 1.7).clamp(0, 100);
    final alignment = (100 - math.max(0, bodyLine - 8) * 4).clamp(0, 100);
    return (depth * .65 + alignment * .35).round().clamp(0, 100);
  }

  String _label(int s) => s >= 90 ? 'Excellent' : s >= 75 ? 'Good' : s >= 55 ? 'Needs work' : 'Adjust form';

  double _lineAngle(PosePoint a, PosePoint b, PosePoint c) {
    final ab = math.atan2(b.y - a.y, b.x - a.x);
    final bc = math.atan2(c.y - b.y, c.x - b.x);
    return (ab - bc).abs() * 180 / math.pi;
  }

  PosePoint? _find(List<PosePoint> p, String name) {
    for (final x in p) { if (x.name == name && x.confidence >= .55) return x; }
    return null;
  }

  @override
  void reset() {
    _phase = ExercisePhase.ready;
    _reachedBottom = false;
    _bottomFrames = 0;
    _upFrames = 0;
  }
}
