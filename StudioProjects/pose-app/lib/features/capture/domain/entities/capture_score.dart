import 'package:flutter/foundation.dart';

import '../enums/capture_enums.dart';

/// A single factor's contribution to the overall capture score.
@immutable
class FactorScore {
  const FactorScore({
    required this.factor,
    required this.score,
    required this.weight,
    this.note,
  });

  final CaptureFactor factor;

  /// Raw sub-score [0..1].
  final double score;

  /// Normalized weight applied [0..1].
  final double weight;

  /// Optional debug note (e.g. "stable 12 frames").
  final String? note;

  /// Weighted contribution to the final score.
  double get contribution => score * weight;
}

/// Snapshot of the engine's scoring at a single frame.
@immutable
class CaptureScore {
  const CaptureScore({
    required this.factors,
    required this.overall,
    required this.suppressReason,
    required this.stableForFrames,
    required this.timestamp,
  });

  final List<FactorScore> factors;

  /// Weighted aggregate score [0..1]. Already EMA-smoothed by the
  /// engine before being placed here.
  final double overall;

  final CaptureSuppressReason suppressReason;

  /// How many consecutive frames the score has been above threshold
  /// AND no suppress reason was active.
  final int stableForFrames;

  final int timestamp;

  bool get isReady =>
      suppressReason == CaptureSuppressReason.none &&
      overall >= 0.0 &&
      stableForFrames > 0;

  FactorScore? operator [](CaptureFactor f) {
    for (final s in factors) {
      if (s.factor == f) return s;
    }
    return null;
  }
}
