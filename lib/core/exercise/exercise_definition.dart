import 'package:pose/core/pose/pose_landmark.dart';

enum ExercisePhase { ready, descending, bottom, ascending, holding }

class ExerciseFeedback {
  final ExercisePhase phase;
  final bool validRep;
  final int score;
  final String scoreLabel;
  final List<String> messages;

  const ExerciseFeedback({
    required this.phase,
    required this.validRep,
    required this.score,
    required this.scoreLabel,
    this.messages = const [],
  });
}

abstract class ExerciseAnalyzer {
  String get id;
  String get displayName;
  List<String> get setupTips;

  ExerciseFeedback analyze(List<PosePoint> landmarks);
  void reset();
}
