class SquatFormScore {
  final int score;
  final int depthScore;
  final int kneeAlignmentScore;
  final int postureScore;
  final int symmetryScore;
  final String label;
  final String feedback;

  const SquatFormScore({
    required this.score,
    required this.depthScore,
    this.kneeAlignmentScore = 100,
    this.postureScore = 100,
    this.symmetryScore = 100,
    required this.label,
    required this.feedback,
  });

  factory SquatFormScore.fromKneeAngle(double angle) => fromMetrics(
        leftKneeAngle: angle,
        rightKneeAngle: angle,
      );

  factory SquatFormScore.fromMetrics({
    required double leftKneeAngle,
    double? rightKneeAngle,
    double? kneeAlignment,
    double? torsoLean,
  }) {
    final leftDepth = _depth(leftKneeAngle);
    final rightDepth = rightKneeAngle == null ? leftDepth : _depth(rightKneeAngle);
    final depth = ((leftDepth + rightDepth) / 2).round();
    final symmetry = rightKneeAngle == null
        ? 100
        : (100 - (leftKneeAngle - rightKneeAngle).abs() * 1.5).clamp(0, 100).round();
    final alignment = (kneeAlignment ?? 100).clamp(0, 100).round();
    final posture = torsoLean == null
        ? 100
        : (100 - ((torsoLean.abs() - 15).clamp(0, 40) * 2.0)).clamp(20, 100).round();
    final score = (depth * .40 + alignment * .25 + posture * .20 + symmetry * .15)
        .round()
        .clamp(0, 100);
    final label = score >= 90 ? 'Excellent' : score >= 75 ? 'Good' : score >= 55 ? 'Needs work' : 'Adjust form';

    final feedback = depth < 75
        ? (leftKneeAngle > 110
            ? 'Go a little deeper while keeping your movement controlled.'
            : 'You are going very deep — keep the squat controlled.')
        : alignment < 75
            ? 'Keep your knees tracking in line with your feet.'
            : posture < 75
                ? 'Keep your chest controlled and avoid excessive forward lean.'
                : symmetry < 80
                    ? 'Try to keep both sides moving at a similar depth.'
                    : 'Great control. Keep this movement consistent.';

    return SquatFormScore(
      score: score,
      depthScore: depth,
      kneeAlignmentScore: alignment,
      postureScore: posture,
      symmetryScore: symmetry,
      label: label,
      feedback: feedback,
    );
  }

  static int _depth(double angle) {
    return angle >= 85 && angle <= 110
        ? 100
        : angle > 110
            ? (100 - ((angle - 110) * 1.5)).clamp(0, 100).round()
            : (100 - ((85 - angle) * 2.0)).clamp(0, 100).round();
  }
}
