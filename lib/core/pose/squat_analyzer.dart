import 'pose_landmark.dart';

enum SquatPhase { standing, descending, bottom, ascending }

class SquatFeedback {
  final SquatPhase phase;
  final bool validRep;
  final List<String> messages;
  final double kneeAngle;

  const SquatFeedback({required this.phase, required this.validRep, required this.messages, required this.kneeAngle});
}

class SquatAnalyzer {
  SquatPhase _phase = SquatPhase.standing;
  bool _wentDown = false;

  SquatFeedback analyze({required PosePoint hip, required PosePoint knee, required PosePoint ankle}) {
    final angle = PoseMath.angle(hip, knee, ankle);
    final messages = <String>[];

    if (angle > 155) {
      if (_phase == SquatPhase.ascending || _phase == SquatPhase.bottom) {
        final completed = _wentDown;
        _phase = SquatPhase.standing;
        _wentDown = false;
        return SquatFeedback(phase: _phase, validRep: completed, messages: const [], kneeAngle: angle);
      }
      _phase = SquatPhase.standing;
    } else if (angle > 110) {
      _phase = _phase == SquatPhase.bottom ? SquatPhase.ascending : SquatPhase.descending;
      _wentDown = true;
    } else {
      _phase = SquatPhase.bottom;
      _wentDown = true;
      messages.add('Good depth — keep your chest controlled.');
    }

    if (angle < 70) messages.add('Avoid collapsing too deep; keep the movement controlled.');
    return SquatFeedback(phase: _phase, validRep: false, messages: messages, kneeAngle: angle);
  }

  void reset() {
    _phase = SquatPhase.standing;
    _wentDown = false;
  }
}
