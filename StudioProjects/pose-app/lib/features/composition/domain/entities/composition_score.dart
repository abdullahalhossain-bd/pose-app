import 'package:flutter/foundation.dart';

import '../enums/composition_enums.dart';

/// A single composition factor's sub-score.
@immutable
class CompositionFactorScore {
  const CompositionFactorScore({
    required this.factor,
    required this.score,
    required this.weight,
    this.note,
  });

  final CompositionFactor factor;
  final double score;       // [0..1]
  final double weight;      // normalized
  final String? note;

  double get contribution => score * weight;
}

/// A single issue found by the scorer.
@immutable
class CompositionIssue {
  const CompositionIssue({
    required this.kind,
    required this.priority,
    required this.severity,
    required this.confidence,
    required this.rule,
  });

  final CompositionIssueKind kind;
  final CompositionPriority priority;
  final double severity;     // [0..1], higher = worse
  final double confidence;   // [0..1]
  final String rule;
}

/// Full output of the CompositionScorer.
@immutable
class CompositionScore {
  const CompositionScore({
    required this.factors,
    required this.issues,
    required this.overallScore,
    required this.horizonAngleDeg,
    required this.timestamp,
  });

  final List<CompositionFactorScore> factors;
  final List<CompositionIssue> issues;
  final double overallScore;       // [0..1]
  final double? horizonAngleDeg;   // null if no horizon detected
  final int timestamp;

  bool get isAcceptable =>
      issues.every((i) => i.priority == CompositionPriority.low ||
                         i.priority == CompositionPriority.affirmation);
}
