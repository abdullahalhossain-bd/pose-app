import 'dart:convert';

class WorkoutSession {
  final String exercise;
  final int reps;
  final int averageScore;
  final int bestScore;
  final List<int> repScores;
  final DateTime completedAt;
  final int durationSeconds;

  const WorkoutSession({
    required this.exercise,
    required this.reps,
    required this.averageScore,
    required this.bestScore,
    required this.repScores,
    required this.completedAt,
    required this.durationSeconds,
  });

  Map<String, dynamic> toJson() => {
        'exercise': exercise,
        'reps': reps,
        'averageScore': averageScore,
        'bestScore': bestScore,
        'repScores': repScores,
        'completedAt': completedAt.toIso8601String(),
        'durationSeconds': durationSeconds,
      };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(
        exercise: json['exercise'] as String? ?? 'squat',
        reps: (json['reps'] as num?)?.toInt() ?? 0,
        averageScore: (json['averageScore'] as num?)?.toInt() ?? 0,
        bestScore: (json['bestScore'] as num?)?.toInt() ?? 0,
        repScores: (json['repScores'] as List<dynamic>?)
                ?.whereType<num>()
                .map((v) => v.toInt())
                .toList() ??
            const [],
        completedAt: DateTime.tryParse(json['completedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      );

  String encode() => jsonEncode(toJson());
  factory WorkoutSession.decode(String value) =>
      WorkoutSession.fromJson(jsonDecode(value) as Map<String, dynamic>);
}
