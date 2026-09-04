import 'package:flutter_test/flutter_test.dart';
import 'package:pose/core/data/session_model.dart';

void main() {
  test('WorkoutSession round trips through JSON', () {
    final original = WorkoutSession(
      exercise: 'squat',
      reps: 8,
      averageScore: 84,
      bestScore: 92,
      repScores: [80, 84, 87, 82, 89, 92, 81, 78],
      completedAt: DateTime.parse('2026-09-04T10:00:00.000Z'),
      durationSeconds: 480,
    );

    final decoded = WorkoutSession.decode(original.encode());

    expect(decoded.exercise, 'squat');
    expect(decoded.reps, 8);
    expect(decoded.averageScore, 84);
    expect(decoded.bestScore, 92);
    expect(decoded.repScores, original.repScores);
    expect(decoded.completedAt, original.completedAt);
    expect(decoded.durationSeconds, 480);
  });

  test('WorkoutSession tolerates missing optional persisted fields', () {
    final session = WorkoutSession.fromJson({'exercise': 'squat', 'reps': 3});

    expect(session.exercise, 'squat');
    expect(session.reps, 3);
    expect(session.averageScore, 0);
    expect(session.bestScore, 0);
    expect(session.repScores, isEmpty);
  });
}
