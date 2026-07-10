import 'package:flutter/foundation.dart';

import '../../../pose/domain/enums/pose_landmark_type.dart';
import '../enums/guidance_enums.dart';

/// A single computed geometric measurement about the pose.
@immutable
class PoseMetric {
  const PoseMetric({
    required this.name,
    required this.value,
    required this.unit,
    required this.isWithinThreshold,
  });

  final String name;
  final double value;
  final String unit;
  final bool isWithinThreshold;
}

/// The full output of the [PoseQualityScorer].
@immutable
class PoseQualityResult {
  const PoseQualityResult({
    required this.metrics,
    required this.issues,
    required this.overallScore,
    required this.confidence,
  });

  /// All measured metrics — used by debug HUD.
  final List<PoseMetric> metrics;

  /// Issues found, sorted by priority (highest first).
  final List<PoseIssue> issues;

  /// Aggregate score [0..1] — 1.0 = textbook pose.
  final double overallScore;

  /// Confidence in the evaluation itself, derived from landmark
  /// availability + per-metric stability. Drives whether the engine
  /// emits strong instructions or stays quiet.
  final double confidence;

  bool get isAcceptable => issues.every((i) => i.priority == GuidancePriority.low || i.priority == GuidancePriority.affirmation);
}

/// A single issue with the current pose, ready for the guidance engine
/// to convert into an instruction.
@immutable
class PoseIssue {
  const PoseIssue({
    required this.kind,
    required this.priority,
    required this.severity,
    required this.confidence,
    required this.rule,
    this.targetLandmark,
    this.targetX,
    this.targetY,
    this.targetRadius,
    this.suggestedDirection,
  });

  final PoseIssueKind kind;
  final GuidancePriority priority;
  final double severity; // [0..1], higher = worse
  final double confidence; // [0..1]
  final String rule;

  final PoseLandmarkType? targetLandmark;
  final double? targetX;
  final double? targetY;
  final double? targetRadius;
  final GuidanceDirection? suggestedDirection;

  /// Convert to a [GuidanceSignal] using the dictionary.
  GuidanceSignal toSignal() {
    final copy = _instructionMap[kind]!;
    return GuidanceSignal(
      instruction: copy.$1,
      priority: priority,
      status: _statusFor(priority),
      confidence: confidence,
      rule: rule,
      direction: suggestedDirection ?? copy.$2,
      targetX: targetX,
      targetY: targetY,
      targetRadius: targetRadius,
      shortText: copy.$3,
      longText: copy.$4,
    );
  }

  static GuidanceStatus _statusFor(GuidancePriority p) => switch (p) {
        GuidancePriority.critical => GuidanceStatus.fix,
        GuidancePriority.high => GuidanceStatus.fix,
        GuidancePriority.medium => GuidanceStatus.improve,
        GuidancePriority.low => GuidanceStatus.improve,
        GuidancePriority.affirmation => GuidanceStatus.good,
      };
}

/// Catalog of pose issues the scorer can detect. Each maps to a
/// (instruction, direction, short text, long text) tuple — the
/// single source of truth for user-facing copy.
enum PoseIssueKind {
  // Head
  headTiltedLeft,
  headTiltedRight,
  chinTooLow,
  chinTooHigh,
  notFacingCamera,
  // Shoulders
  shouldersTilted,
  shouldersRotated,
  shouldersRaised,
  // Hips
  hipsNotLevel,
  // Body
  bodyRotatedLeft,
  bodyRotatedRight,
  // Arms
  leftArmTooLow,
  rightArmTooLow,
  leftArmTooHigh,
  rightArmTooHigh,
  armsCrossed,
  // Legs
  stanceTooNarrow,
  stanceTooWide,
  // Framing
  tooCloseToCamera,
  tooFarFromCamera,
  offCenterLeft,
  offCenterRight,
  insufficientHeadRoom,
  tooMuchHeadRoom,
}

const Map<PoseIssueKind,
    (GuidanceInstructionType, GuidanceDirection, String, String)> _instructionMap = {
  PoseIssueKind.headTiltedLeft: (
    GuidanceInstructionType.levelHead,
    GuidanceDirection.right,
    'Level your head',
    'Your head is tilted left — try leveling it.',
  ),
  PoseIssueKind.headTiltedRight: (
    GuidanceInstructionType.levelHead,
    GuidanceDirection.left,
    'Level your head',
    'Your head is tilted right — try leveling it.',
  ),
  PoseIssueKind.chinTooLow: (
    GuidanceInstructionType.raiseChin,
    GuidanceDirection.up,
    'Raise your chin',
    'Lift your chin slightly for a stronger jawline.',
  ),
  PoseIssueKind.chinTooHigh: (
    GuidanceInstructionType.lowerChin,
    GuidanceDirection.down,
    'Lower your chin',
    'Lower your chin a touch — you\'re looking up.',
  ),
  PoseIssueKind.notFacingCamera: (
    GuidanceInstructionType.faceCamera,
    GuidanceDirection.none,
    'Face the camera',
    'Turn to face the camera directly.',
  ),
  PoseIssueKind.shouldersTilted: (
    GuidanceInstructionType.straightenShoulders,
    GuidanceDirection.none,
    'Straighten shoulders',
    'Your shoulders are tilted — level them out.',
  ),
  PoseIssueKind.shouldersRotated: (
    GuidanceInstructionType.faceCamera,
    GuidanceDirection.none,
    'Square your shoulders',
    'Rotate your shoulders toward the camera.',
  ),
  PoseIssueKind.shouldersRaised: (
    GuidanceInstructionType.relaxShoulders,
    GuidanceDirection.down,
    'Relax your shoulders',
    'Drop your shoulders — they\'re tense.',
  ),
  PoseIssueKind.hipsNotLevel: (
    GuidanceInstructionType.squareHips,
    GuidanceDirection.none,
    'Level your hips',
    'Your hips are tilted — try to level them.',
  ),
  PoseIssueKind.bodyRotatedLeft: (
    GuidanceInstructionType.turnRight,
    GuidanceDirection.right,
    'Turn a little right',
    'Rotate your body slightly to the right.',
  ),
  PoseIssueKind.bodyRotatedRight: (
    GuidanceInstructionType.turnLeft,
    GuidanceDirection.left,
    'Turn a little left',
    'Rotate your body slightly to the left.',
  ),
  PoseIssueKind.leftArmTooLow: (
    GuidanceInstructionType.raiseArmLeft,
    GuidanceDirection.upLeft,
    'Raise left arm',
    'Lift your left arm a bit.',
  ),
  PoseIssueKind.rightArmTooLow: (
    GuidanceInstructionType.raiseArmRight,
    GuidanceDirection.upRight,
    'Raise right arm',
    'Lift your right arm a bit.',
  ),
  PoseIssueKind.leftArmTooHigh: (
    GuidanceInstructionType.lowerArmLeft,
    GuidanceDirection.downLeft,
    'Lower left arm',
    'Drop your left arm slightly.',
  ),
  PoseIssueKind.rightArmTooHigh: (
    GuidanceInstructionType.lowerArmRight,
    GuidanceDirection.downRight,
    'Lower right arm',
    'Drop your right arm slightly.',
  ),
  PoseIssueKind.armsCrossed: (
    GuidanceInstructionType.uncrossArms,
    GuidanceDirection.none,
    'Uncross your arms',
    'Let your arms hang naturally for a more open look.',
  ),
  PoseIssueKind.stanceTooNarrow: (
    GuidanceInstructionType.widenStance,
    GuidanceDirection.none,
    'Widen your stance',
    'Step your feet a little further apart.',
  ),
  PoseIssueKind.stanceTooWide: (
    GuidanceInstructionType.narrowStance,
    GuidanceDirection.none,
    'Narrow your stance',
    'Bring your feet slightly closer together.',
  ),
  PoseIssueKind.tooCloseToCamera: (
    GuidanceInstructionType.stepBack,
    GuidanceDirection.down,
    'Step back a bit',
    'You\'re a little close — take a half step back.',
  ),
  PoseIssueKind.tooFarFromCamera: (
    GuidanceInstructionType.stepCloser,
    GuidanceDirection.up,
    'Step closer',
    'Come a bit closer to the camera.',
  ),
  PoseIssueKind.offCenterLeft: (
    GuidanceInstructionType.moveRight,
    GuidanceDirection.right,
    'Move right',
    'Shift a little to your right to center.',
  ),
  PoseIssueKind.offCenterRight: (
    GuidanceInstructionType.moveLeft,
    GuidanceDirection.left,
    'Move left',
    'Shift a little to your left to center.',
  ),
  PoseIssueKind.insufficientHeadRoom: (
    GuidanceInstructionType.lowerChin,
    GuidanceDirection.down,
    'Mind your head',
    'You\'re too close to the top of the frame.',
  ),
  PoseIssueKind.tooMuchHeadRoom: (
    GuidanceInstructionType.stepCloser,
    GuidanceDirection.up,
    'Fill the frame',
    'Step a bit closer — too much space above.',
  ),
};
