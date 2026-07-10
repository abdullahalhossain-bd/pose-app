import '../../pose/domain/entities/pose_sample.dart';
import '../config/guidance_config.dart';
import '../domain/entities/pose_quality_result.dart';
import '../domain/enums/guidance_enums.dart';
import 'pose_quality_scorer.dart';

/// Converts [PoseQualityResult] → a single [GuidanceSignal] for the UI.
///
/// Philosophy:
///  - Never overwhelm the user with multiple instructions.
///  - Pick the highest-priority issue; if all clear, emit affirmation.
///  - If evaluation confidence is low, suppress strong instructions.
class GuidanceEngine {
  GuidanceEngine(this.config) : _scorer = PoseQualityScorer(config);

  final GuidanceConfig config;
  final PoseQualityScorer _scorer;

  /// Full result exposed for the debug HUD.
  PoseQualityResult evaluate(PoseSample pose) => _scorer.evaluate(pose);

  /// Pick the single best signal to show the user right now.
  GuidanceSignal decide(PoseSample pose) {
    final result = _scorer.evaluate(pose);

    // Confidence gate — if we can't see enough of the subject, stay quiet.
    if (pose.reliableCount < config.minLandmarksForGuidance ||
        result.confidence < config.minAggregateConfidence) {
      return GuidanceSignal(
        instruction: GuidanceInstructionType.holdStill,
        priority: GuidancePriority.affirmation,
        status: GuidanceStatus.good,
        confidence: result.confidence,
        rule: 'low_confidence_suppress',
        shortText: 'Hold still',
      );
    }

    if (result.issues.isEmpty) {
      return GuidanceSignal(
        instruction: GuidanceInstructionType.greatPose,
        priority: GuidancePriority.affirmation,
        status: GuidanceStatus.good,
        confidence: result.confidence,
        rule: 'no_issues',
        shortText: 'Looks great',
        longText: 'Your pose looks balanced — hold still.',
      );
    }

    // Top-priority issue (already sorted by scorer).
    final top = result.issues.first;
    final signal = top.toSignal();

    // Suppress if even the top issue is low-confidence.
    if (signal.confidence < config.minConfidenceToDisplay) {
      return GuidanceSignal(
        instruction: GuidanceInstructionType.holdStill,
        priority: GuidancePriority.affirmation,
        status: GuidanceStatus.good,
        confidence: result.confidence,
        rule: 'low_issue_confidence_suppress',
        shortText: 'Hold still',
      );
    }

    return signal;
  }
}
