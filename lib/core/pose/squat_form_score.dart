class SquatFormScore {
  final int score;
  final int depthScore;
  final String label;
  final String feedback;

  const SquatFormScore({required this.score, required this.depthScore, required this.label, required this.feedback});

  factory SquatFormScore.fromKneeAngle(double angle) {
    final depth = angle >= 85 && angle <= 110
        ? 100
        : angle > 110
            ? (100 - ((angle - 110) * 1.5)).clamp(0, 100).round()
            : (100 - ((85 - angle) * 2.0)).clamp(0, 100).round();
    final score = depth;
    final label = score >= 90 ? 'Excellent' : score >= 75 ? 'Good' : score >= 55 ? 'Needs work' : 'Adjust form';
    final feedback = angle > 125
        ? 'Go a little deeper while keeping your movement controlled.'
        : angle < 70
            ? 'You are going very deep — keep the squat controlled.'
            : score >= 90
                ? 'Great depth. Keep this controlled movement.'
                : 'Aim for a consistent, controlled squat depth.';
    return SquatFormScore(score: score, depthScore: depth, label: label, feedback: feedback);
  }
}
