import '../../composition/domain/composition_message.dart';
import '../../lighting/domain/lighting_message.dart';
import '../domain/guidance_message.dart';

/// Merges every guidance source into the ONE message shown to the user
/// (spec §14 — never stack multiple recommendations). A pure function,
/// not a class with hidden state: pose, attention, composition, and
/// lighting each already carry whatever history their own debouncing
/// needs (GuidanceEngine, AttentionEngine, CompositionEngine,
/// LightingEngine respectively) — this step just picks between their
/// four already-stable outputs, so it doesn't need history of its own.
///
/// Priority (highest first), matching how a human photographer actually
/// directs someone — fix the person, then whether they're looking at
/// the camera, then the shot's composition, then the light:
///   1. Anything pose-related that needs the user's attention right now
///      (a correction, or the detector losing/not finding them) always
///      wins — nothing else matters if the framing itself is wrong.
///   2. Once pose is acceptable, "face the camera" (attention/yaw) —
///      still a fundamental human-factor issue, ahead of composition
///      and lighting refinements.
///   3. Composition (currently: headroom).
///   4. Lighting.
///   5. Otherwise, the pose engine's own "ready"/"hold" confirmation.
///
/// This ordering is a product decision, not just an engineering
/// default — documented here so it can be revisited deliberately rather
/// than drifting.
GuidanceMessage mergeGuidance({
  required GuidanceMessage poseGuidance,
  required GuidanceMessage? attentionGuidance,
  required CompositionMessage compositionGuidance,
  required LightingMessage lightingGuidance,
}) {
  const poseNeedsAttention = {
    PoseTrackingState.guidance,
    PoseTrackingState.searching,
    PoseTrackingState.lowConfidence,
    PoseTrackingState.noPerson,
    PoseTrackingState.error,
  };

  if (poseNeedsAttention.contains(poseGuidance.state)) {
    return poseGuidance;
  }

  // From here on, pose is "ready" or "hold" — its `state` is preserved
  // on whatever we return, so the UI's capture-ready ring (bound to
  // PoseTrackingState.hold) doesn't turn off just because a secondary
  // nudge about facing the camera, composition, or lighting is showing.
  if (attentionGuidance != null) {
    return GuidanceMessage(
      state: poseGuidance.state,
      category: attentionGuidance.category,
      textEn: attentionGuidance.textEn,
      textBn: attentionGuidance.textBn,
    );
  }

  if (compositionGuidance.condition == CompositionCondition.insufficientHeadroom ||
      compositionGuidance.condition == CompositionCondition.excessiveHeadroom) {
    return GuidanceMessage(
      state: poseGuidance.state,
      category: GuidanceCategory.composition,
      textEn: compositionGuidance.textEn,
      textBn: compositionGuidance.textBn,
    );
  }

  if (lightingGuidance.condition == LightingCondition.tooDark ||
      lightingGuidance.condition == LightingCondition.tooBright) {
    return GuidanceMessage(
      state: poseGuidance.state,
      category: GuidanceCategory.lighting,
      textEn: lightingGuidance.textEn,
      textBn: lightingGuidance.textBn,
    );
  }

  return poseGuidance;
}
