import '../../pose/domain/pose_landmark_data.dart';
import '../domain/guidance_message.dart';

/// "Face the camera" guidance — the honest subset of Phase 5's "chin &
/// eye guidance" that ML Kit's body-pose landmarks can actually support.
///
/// SCOPING DECISION, stated explicitly per the P1 spec's own instruction
/// ("do not claim precise facial analysis if the available model cannot
/// reliably support it... if uncertain, say nothing"):
///
/// - Head YAW (turning left/right, away from the camera) IS implemented
///   here, using a signal that's genuinely reliable from body-pose
///   landmarks: when a person turns their head to one side, ML Kit's
///   confidence (`likelihood`) for the ear on the far side drops
///   sharply relative to the near-side ear, because it's foreshortened
///   or occluded. A sustained, large asymmetry between left/right ear
///   likelihood is a real, direct measurement, not a guess.
/// - Chin PITCH (raise/lower chin) is explicitly NOT implemented. This
///   app only has `google_mlkit_pose_detection`'s body landmarks (nose,
///   eyes, ears — coarse 2D points on a skeleton), not a dedicated face
///   mesh. There is no reliable 2D-landmark signal in this set for
///   "chin tilted up vs down" that isn't either (a) confusable with the
///   person simply being shorter/taller in frame, or (b) so noisy it
///   would flicker constantly even with the same hysteresis treatment
///   used everywhere else. Doing it properly would mean integrating
///   `google_mlkit_face_detection` (a different model, a new
///   dependency, its own frame-processing budget) — a real feature, not
///   a quick addition, and out of scope for this pass. Faking chin
///   guidance from an unreliable proxy would violate the product's own
///   "never guess when uncertain" principle (spec §23) more than simply
///   not having the feature yet.
class AttentionEngine {
  AttentionEngine({
    this.likelihoodAsymmetryEnter = 0.45,
    this.likelihoodAsymmetryClear = 0.30,
    this.enterPersistenceFrames = 4,
    this.clearPersistenceFrames = 2,
  });

  final double likelihoodAsymmetryEnter;
  final double likelihoodAsymmetryClear;
  final int enterPersistenceFrames;
  final int clearPersistenceFrames;

  bool _flagged = false;
  int _aboveEnterStreak = 0;
  int _belowClearStreak = 0;

  static const GuidanceMessage _faceCamera = GuidanceMessage(
    state: PoseTrackingState.guidance,
    category: GuidanceCategory.attention,
    textEn: "Face the camera",
    textBn: "ক্যামেরার দিকে তাকান",
  );

  /// Returns null when there's nothing to say — either the person is
  /// facing the camera, or there isn't enough landmark data to tell
  /// (both ears/eyes need to have been detected at all to compare).
  GuidanceMessage? evaluate(PoseFrame pose) {
    final leftEar = pose.get(LandmarkType.leftEar);
    final rightEar = pose.get(LandmarkType.rightEar);

    if (leftEar == null || rightEar == null) {
      // Can't compare what wasn't detected — say nothing rather than
      // guess, and don't let a temporary miss reset an established
      // "turned away" streak instantly (matches the persistence
      // treatment used everywhere else in this codebase).
      return _flagged ? _faceCamera : null;
    }

    final asymmetry = (leftEar.likelihood - rightEar.likelihood).abs();

    if (_flagged) {
      if (asymmetry < likelihoodAsymmetryClear) {
        _belowClearStreak++;
        if (_belowClearStreak >= clearPersistenceFrames) {
          _flagged = false;
          _belowClearStreak = 0;
          _aboveEnterStreak = 0;
          return null;
        }
      } else {
        _belowClearStreak = 0;
      }
      return _faceCamera;
    }

    if (asymmetry > likelihoodAsymmetryEnter) {
      _aboveEnterStreak++;
      if (_aboveEnterStreak >= enterPersistenceFrames) {
        _flagged = true;
        _aboveEnterStreak = 0;
        return _faceCamera;
      }
      return null;
    }

    _aboveEnterStreak = 0;
    return null;
  }

  void reset() {
    _flagged = false;
    _aboveEnterStreak = 0;
    _belowClearStreak = 0;
  }
}
