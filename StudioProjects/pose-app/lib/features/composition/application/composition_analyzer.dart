import '../../pose/domain/pose_landmark_data.dart';
import '../domain/composition_message.dart';

/// Composition Intelligence v1 — headroom only.
///
/// SCOPING DECISION, stated explicitly rather than silently: this
/// version deliberately does NOT implement rule-of-thirds horizontal
/// placement, symmetry, or horizon alignment, even though the P1 spec
/// lists them. Reasons:
///
/// - Rule-of-thirds horizontal placement (subject at ~1/3 or ~2/3 of
///   frame width) directly CONTRADICTS GuidanceEngine's existing
///   centering logic, which targets dead-center (0.5) as the correct
///   position for the P0/P1 solo-traveler use case. Shipping both would
///   mean the app sometimes tells the user to center themselves and
///   sometimes tells them to move off-center — a coherence bug, not a
///   feature. Resolving it needs a product decision (does this app's
///   default photography style favor centered or rule-of-thirds
///   framing?), not just an engineering task, so it's deferred rather
///   than guessed at.
/// - Horizon alignment needs either a device-tilt (accelerometer) or a
///   detected horizontal reference line in the scene — neither pose
///   landmarks nor the current lighting-analysis buffer provide that.
///   Faking it from shoulder tilt would just duplicate GuidanceEngine's
///   existing shoulder-level check under a different name.
/// - Symmetry detection needs a scene-level model (detecting
///   background structure), which is out of scope for a pose-landmark-
///   driven analyzer.
///
/// Footroom is also intentionally NOT duplicated here — GuidanceEngine's
/// existing framing check (subject height between _minSubjectHeight and
/// _maxSubjectHeight, using ankle/hip landmarks) already covers "is the
/// subject cut off at the bottom" as part of overall distance guidance.
/// Headroom is the one composition dimension GuidanceEngine doesn't
/// already reason about, which is what makes it additive rather than
/// overlapping.
class CompositionAnalyzer {
  const CompositionAnalyzer();

  /// Returns the fraction of frame height between the top edge (y=0)
  /// and the top of the subject's head, using the nose landmark as a
  /// practical proxy (the actual top-of-head is a few percent higher,
  /// which is accounted for in the engine's thresholds rather than here).
  /// Returns null if the nose wasn't detected this frame.
  double? headroomOf(PoseFrame pose) {
    final nose = pose.get(LandmarkType.nose);
    return nose?.y;
  }
}

/// Stateful classifier with the same debounce/hysteresis shape as
/// GuidanceEngine and LightingEngine — a repeated pattern across all
/// three guidance sources at this point, which is exactly why it isn't
/// pulled into a shared base class: each one reasons about a genuinely
/// different signal, and the pattern is simple enough that duplicating
/// ~15 lines of hysteresis bookkeeping three times is cheaper to read
/// and modify independently than coupling three unrelated engines to
/// one shared abstraction on the strength of "they both debounce."
class CompositionEngine {
  CompositionEngine({
    this.minHeadroomEnter = 0.04,
    this.minHeadroomClear = 0.06,
    this.maxHeadroomEnter = 0.24,
    this.maxHeadroomClear = 0.20,
  });

  final double minHeadroomEnter;
  final double minHeadroomClear;
  final double maxHeadroomEnter;
  final double maxHeadroomClear;

  final CompositionAnalyzer _analyzer = const CompositionAnalyzer();
  CompositionCondition _current = CompositionCondition.unknown;

  CompositionMessage classify(PoseFrame pose) {
    final headroom = _analyzer.headroomOf(pose);
    if (headroom == null) {
      return CompositionMessage.unknown;
    }

    switch (_current) {
      case CompositionCondition.insufficientHeadroom:
        _current = headroom > minHeadroomClear
            ? CompositionCondition.good
            : CompositionCondition.insufficientHeadroom;
        break;
      case CompositionCondition.excessiveHeadroom:
        _current = headroom < maxHeadroomClear
            ? CompositionCondition.good
            : CompositionCondition.excessiveHeadroom;
        break;
      case CompositionCondition.good:
      case CompositionCondition.unknown:
        if (headroom < minHeadroomEnter) {
          _current = CompositionCondition.insufficientHeadroom;
        } else if (headroom > maxHeadroomEnter) {
          _current = CompositionCondition.excessiveHeadroom;
        } else {
          _current = CompositionCondition.good;
        }
        break;
    }

    switch (_current) {
      case CompositionCondition.insufficientHeadroom:
        return CompositionMessage.insufficientHeadroom;
      case CompositionCondition.excessiveHeadroom:
        return CompositionMessage.excessiveHeadroom;
      case CompositionCondition.good:
        return CompositionMessage.good;
      case CompositionCondition.unknown:
        return CompositionMessage.unknown;
    }
  }

  void reset() => _current = CompositionCondition.unknown;
}
