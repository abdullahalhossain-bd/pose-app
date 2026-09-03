/// What kind of correction is being asked for. Used purely for icon/animation
/// selection in the UI layer — the guidance engine decides the *text*.
enum GuidanceCategory {
  position, // move left/right/forward/back
  pose, // chin, shoulders, turn
  attention, // look at camera
  stability, // hold still
  lighting, // find/avoid light
  composition, // headroom/footroom
  none, // nothing to say — pose looks good
  lowConfidence, // can't see the subject well enough to guide
}

/// Explicit top-level pipeline state, distinct from [GuidanceCategory].
///
/// This is the state machine required to keep guidance from flickering:
/// transitions between these states are debounced inside [GuidanceEngine]
/// rather than being a direct per-frame reflection of raw detector output.
enum PoseTrackingState {
  /// ML Kit returned zero detected people this frame.
  noPerson,

  /// A person was previously tracked and has just been lost, or partial
  /// detections are arriving but not yet confidently classified — a
  /// short grace state so a single flaky frame doesn't visibly bounce
  /// the UI between "no person" and "low confidence".
  searching,

  /// Sustained low detection confidence — per spec §23, the engine must
  /// not guess when it can't see the subject well.
  lowConfidence,

  /// A specific correction is being actively recommended.
  guidance,

  /// The pose just became acceptable — shown briefly before promoting
  /// to [hold] once it's sustained.
  ready,

  /// The pose has been acceptable for several consecutive evaluations —
  /// this is the signal the UI uses to light up "ready to capture".
  hold,

  /// The pose pipeline itself failed (detector threw) — distinct from
  /// simply not seeing a confident pose.
  error,
}

/// A single, human-facing instruction.
///
/// The product principle here (see spec §14) is ONE primary recommendation
/// at a time — never a stacked checklist. [GuidanceEngine] is responsible
/// for picking exactly one of these per evaluation cycle.
class GuidanceMessage {
  final PoseTrackingState state;
  final GuidanceCategory category;
  final String textEn;
  final String textBn;

  /// True when the pose/position issue this message addresses has been
  /// resolved — used to briefly show a "Perfect" confirmation before
  /// moving to the next instruction, per the "real photographer directing
  /// you" UX described in the spec.
  final bool isConfirmation;

  const GuidanceMessage({
    required this.state,
    required this.category,
    required this.textEn,
    required this.textBn,
    this.isConfirmation = false,
  });

  static const GuidanceMessage none = GuidanceMessage(
    state: PoseTrackingState.noPerson,
    category: GuidanceCategory.none,
    textEn: '',
    textBn: '',
  );

  static const GuidanceMessage searching = GuidanceMessage(
    state: PoseTrackingState.searching,
    category: GuidanceCategory.lowConfidence,
    textEn: "Step into frame",
    textBn: "ফ্রেমের মধ্যে আসুন",
  );

  /// ML Kit found nobody at all in this frame (as opposed to [lowConfidence],
  /// where a person was detected but too weakly to trust). Same
  /// user-facing text — the distinction is internal, for state-machine
  /// correctness and future telemetry, not a UX difference in this slice.
  static const GuidanceMessage outOfFrame = GuidanceMessage(
    state: PoseTrackingState.noPerson,
    category: GuidanceCategory.lowConfidence,
    textEn: "Step into frame",
    textBn: "ফ্রেমের মধ্যে আসুন",
  );

  static const GuidanceMessage lowConfidence = GuidanceMessage(
    state: PoseTrackingState.lowConfidence,
    category: GuidanceCategory.lowConfidence,
    textEn: "Step into frame",
    textBn: "ফ্রেমের মধ্যে আসুন",
  );

  static const GuidanceMessage ready = GuidanceMessage(
    state: PoseTrackingState.ready,
    category: GuidanceCategory.stability,
    textEn: "Perfect",
    textBn: "চমৎকার",
    isConfirmation: true,
  );

  static const GuidanceMessage holdPerfect = GuidanceMessage(
    state: PoseTrackingState.hold,
    category: GuidanceCategory.stability,
    textEn: "Perfect. Hold.",
    textBn: "চমৎকার। এভাবে থাকুন।",
    isConfirmation: true,
  );

  static const GuidanceMessage error = GuidanceMessage(
    state: PoseTrackingState.error,
    category: GuidanceCategory.lowConfidence,
    textEn: "Guidance unavailable",
    textBn: "গাইডেন্স পাওয়া যাচ্ছে না",
  );
}
