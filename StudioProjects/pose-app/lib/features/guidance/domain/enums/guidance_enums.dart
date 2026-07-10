/// Coarse priority bands. The engine picks the single highest-priority
/// issue and shows its instruction. Within a band, ties are broken by
/// severity score.
enum GuidancePriority {
  /// Pose is unsafe / unphotogenic; user must fix before capture.
  critical,

  /// Significant quality impact; user should fix.
  high,

  /// Worth fixing but capture is acceptable.
  medium,

  /// Nice-to-have polish.
  low,

  /// Pose is good — show a "hold still" / positive confirmation.
  affirmation,
}

/// Status communicated via color + shape + text label so it's
/// accessible without color alone.
enum GuidanceStatus {
  good,    // green, ●
  improve, // amber, ▲
  fix,     // red, ■
}

/// Catalog of guidance instructions the engine can emit.
///
/// Why an enum and not strings? Because:
/// 1. Internationalization (Day 14) maps each enum → translated string.
/// 2. Tests can assert on enum equality, not string matching.
/// 3. The UI layer is the only place that converts to user-facing text.
enum GuidanceInstructionType {
  // Head
  raiseChin,
  lowerChin,
  levelHead,
  lookAtCamera,
  // Body
  turnLeft,
  turnRight,
  faceCamera,
  straightenShoulders,
  relaxShoulders,
  squareHips,
  // Arms
  raiseArmLeft,
  raiseArmRight,
  lowerArmLeft,
  lowerArmRight,
  uncrossArms,
  relaxArms,
  // Legs
  widenStance,
  narrowStance,
  shiftWeightBack,
  // Framing
  stepBack,
  stepCloser,
  moveLeft,
  moveRight,
  centerYourself,
  // Motion
  holdStill,
  // Positive
  greatPose,
}

/// Direction for arrow overlays.
enum GuidanceDirection {
  up, down, left, right,
  upLeft, upRight, downLeft, downRight,
  none,
}

/// A single piece of guidance, ready for the overlay to render.
class GuidanceSignal {
  const GuidanceSignal({
    required this.instruction,
    required this.priority,
    required this.status,
    required this.confidence,
    required this.rule,
    this.direction = GuidanceDirection.none,
    this.targetX,
    this.targetY,
    this.targetRadius,
    this.shortText,
    this.longText,
  });

  final GuidanceInstructionType instruction;
  final GuidancePriority priority;
  final GuidanceStatus status;
  final double confidence; // [0..1]
  final String rule; // debug: which rule produced this

  final GuidanceDirection direction;

  /// Optional normalized [0..1] target position for arrow / ring overlay.
  final double? targetX;
  final double? targetY;
  final double? targetRadius;

  /// User-facing copy. May be null when the instruction is purely visual.
  final String? shortText;
  final String? longText;

  bool get hasTarget => targetX != null && targetY != null;

  /// Empty signal — "no guidance right now".
  static const GuidanceSignal empty = GuidanceSignal(
    instruction: GuidanceInstructionType.greatPose,
    priority: GuidancePriority.affirmation,
    status: GuidanceStatus.good,
    confidence: 0,
    rule: 'noop',
  );
}
