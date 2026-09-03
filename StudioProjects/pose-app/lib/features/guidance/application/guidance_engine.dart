import '../../pose/domain/pose_landmark_data.dart';
import '../domain/guidance_message.dart';

/// Converts a stream of [PoseFrame]s into the ONE instruction the user
/// should hear right now (spec §14 — never stack multiple corrections).
///
/// Unlike a stateless per-frame classifier, this engine keeps a small
/// amount of history so it can debounce noisy detector output:
///
/// - A single low-confidence frame right after a good detection doesn't
///   immediately drop to "step into frame" — it goes through a brief
///   [PoseTrackingState.searching] grace period first.
/// - A correction (e.g. "move left") doesn't flip to a different
///   correction (e.g. "move right") until the new recommendation has
///   been the top candidate for [_switchDebounceFrames] consecutive
///   evaluations, and the centering/tilt checks use a wider "enter"
///   threshold than "clear" threshold (hysteresis) so a subject sitting
///   right on the boundary doesn't cause the message to oscillate.
/// - "Hold" is only signaled after the pose has been acceptable for
///   [_holdFrames] consecutive evaluations, not on the first good frame.
///
/// Still intentionally a simple, explainable rule engine, not a learned
/// model — personalization/ML-based decisioning is deferred until real
/// usage data justifies it (spec §6), matching docs/IMPLEMENTATION_REPORT.md.
class GuidanceEngine {
  GuidanceEngine({this.minConfidence = 0.55});

  final double minConfidence;

  // Tunable thresholds (spec §27: no magic numbers scattered through the
  // logic — named and grouped here so they can become device-tier-aware
  // config later, spec §21).
  static const double _centerEnterThreshold = 0.08;
  static const double _centerClearThreshold = 0.05;
  static const double _minSubjectHeight = 0.35;
  static const double _maxSubjectHeight = 0.85;
  static const double _framingHysteresisMargin = 0.03;
  static const double _shoulderTiltEnterThreshold = 0.04;
  static const double _shoulderTiltClearThreshold = 0.025;

  static const int _switchDebounceFrames = 3;
  static const int _searchingGraceFrames = 4;
  static const int _holdFrames = 5;

  _Correction? _activeCorrection;
  _Correction? _pendingCorrection;
  int _pendingCorrectionStreak = 0;

  int _framesSinceGoodDetection = 0;
  int _consecutiveGoodPose = 0;
  bool _hadAnyDetection = false;

  GuidanceMessage evaluate(PoseFrame pose) {
    final hasLandmarks = pose.landmarks.isNotEmpty;

    if (!hasLandmarks) {
      return _handleGap(isNoPerson: true);
    }

    if (pose.confidence < minConfidence) {
      return _handleGap(isNoPerson: false);
    }

    // A genuinely confident detection — this is the only branch allowed
    // to reset the "how long have we been without one" counter. (A
    // previous version of this method reset the counter on ANY frame
    // with non-empty landmarks, including low-confidence ones, which
    // meant a sustained low-confidence stream could never escalate past
    // the transient "searching" state into "lowConfidence" — found via
    // unit test tracing during the P0 hardening pass, fixed here.)
    _hadAnyDetection = true;
    _framesSinceGoodDetection = 0;

    final correction = _findCorrection(pose);
    if (correction != null) {
      _consecutiveGoodPose = 0;
      return _applyDebounced(correction);
    }

    // No correction needed this frame — clear any pending switch and
    // count toward the hold threshold.
    _activeCorrection = null;
    _pendingCorrection = null;
    _pendingCorrectionStreak = 0;
    _consecutiveGoodPose++;

    if (_consecutiveGoodPose >= _holdFrames) {
      return GuidanceMessage.holdPerfect;
    }
    return GuidanceMessage.ready;
  }

  /// Called when a frame reports an actual pipeline error (the detector
  /// threw). Distinct from simply not seeing a confident pose.
  GuidanceMessage onError() {
    _resetHistory();
    return GuidanceMessage.error;
  }

  void reset() => _resetHistory();

  void _resetHistory() {
    _activeCorrection = null;
    _pendingCorrection = null;
    _pendingCorrectionStreak = 0;
    _framesSinceGoodDetection = 0;
    _consecutiveGoodPose = 0;
    _hadAnyDetection = false;
  }

  /// Shared handling for "no landmarks at all" and "landmarks present
  /// but below confidence threshold" — both mean the engine can't act
  /// on this frame, differing only in which terminal state they
  /// escalate to after the searching grace period.
  GuidanceMessage _handleGap({required bool isNoPerson}) {
    _consecutiveGoodPose = 0;
    _activeCorrection = null;
    _pendingCorrection = null;
    _pendingCorrectionStreak = 0;

    if (!_hadAnyDetection) {
      // Never seen a confident detection yet this session — searching,
      // not "lost".
      return GuidanceMessage.searching;
    }

    _framesSinceGoodDetection++;
    if (_framesSinceGoodDetection <= _searchingGraceFrames) {
      return GuidanceMessage.searching;
    }
    return isNoPerson ? GuidanceMessage.outOfFrame : GuidanceMessage.lowConfidence;
  }

  /// Debounces a newly-computed correction candidate against the
  /// currently displayed one so the guidance text doesn't flip every
  /// time the subject wobbles across a threshold.
  GuidanceMessage _applyDebounced(_Correction candidate) {
    if (_activeCorrection == null) {
      _activeCorrection = candidate;
      _pendingCorrection = null;
      _pendingCorrectionStreak = 0;
      return candidate.message;
    }

    if (candidate.axis == _activeCorrection!.axis &&
        candidate.direction == _activeCorrection!.direction) {
      // Same recommendation as before — keep showing it, reset any
      // pending switch to a different one.
      _pendingCorrection = null;
      _pendingCorrectionStreak = 0;
      return _activeCorrection!.message;
    }

    // A different correction is being suggested. Require it to persist
    // for a few frames before actually switching the displayed message.
    if (_pendingCorrection != null &&
        _pendingCorrection!.axis == candidate.axis &&
        _pendingCorrection!.direction == candidate.direction) {
      _pendingCorrectionStreak++;
    } else {
      _pendingCorrection = candidate;
      _pendingCorrectionStreak = 1;
    }

    if (_pendingCorrectionStreak >= _switchDebounceFrames) {
      _activeCorrection = _pendingCorrection;
      _pendingCorrection = null;
      _pendingCorrectionStreak = 0;
    }

    return _activeCorrection!.message;
  }

  /// Priority order, mirroring how a human photographer actually directs
  /// someone: framing → centering → shoulder level. Returns null when
  /// nothing needs correcting.
  ///
  /// Hysteresis: each check widens its threshold (making it *harder* to
  /// re-trigger) when that same axis/direction is already the active
  /// correction, and narrows back to the normal "clear" threshold once
  /// a different axis is active — this is what stops a subject sitting
  /// exactly on a boundary from flickering the message every frame.
  _Correction? _findCorrection(PoseFrame pose) {
    final nose = pose.get(LandmarkType.nose);
    final leftShoulder = pose.get(LandmarkType.leftShoulder);
    final rightShoulder = pose.get(LandmarkType.rightShoulder);
    final leftAnkle = pose.get(LandmarkType.leftAnkle);
    final rightAnkle = pose.get(LandmarkType.rightAnkle);
    final leftHip = pose.get(LandmarkType.leftHip);
    final rightHip = pose.get(LandmarkType.rightHip);

    // 1. Framing / distance.
    final topY = nose?.y;
    final bottomY = (leftAnkle?.y ?? rightAnkle?.y) ?? (leftHip?.y ?? rightHip?.y);
    if (topY != null && bottomY != null && bottomY > topY) {
      final subjectHeight = bottomY - topY;
      final wasFramingClose = _activeCorrection?.axis == _Axis.framing &&
          _activeCorrection?.direction == _Direction.negative;
      final wasFramingFar = _activeCorrection?.axis == _Axis.framing &&
          _activeCorrection?.direction == _Direction.positive;

      final closeThreshold = wasFramingClose
          ? _minSubjectHeight + _framingHysteresisMargin
          : _minSubjectHeight;
      final farThreshold = wasFramingFar
          ? _maxSubjectHeight - _framingHysteresisMargin
          : _maxSubjectHeight;

      if (subjectHeight < closeThreshold) {
        return _Correction(
          axis: _Axis.framing,
          direction: _Direction.negative,
          message: const GuidanceMessage(
            state: PoseTrackingState.guidance,
            category: GuidanceCategory.position,
            textEn: "Step closer",
            textBn: "একটু কাছে আসুন",
          ),
        );
      }
      if (subjectHeight > farThreshold) {
        return _Correction(
          axis: _Axis.framing,
          direction: _Direction.positive,
          message: const GuidanceMessage(
            state: PoseTrackingState.guidance,
            category: GuidanceCategory.position,
            textEn: "Step back a little",
            textBn: "একটু পিছনে যান",
          ),
        );
      }
    }

    // 2. Horizontal centering.
    final centerX = _horizontalCenter(leftShoulder, rightShoulder, nose);
    if (centerX != null) {
      final offset = centerX - 0.5;
      final centeringActive = _activeCorrection?.axis == _Axis.centering;
      final threshold =
          centeringActive ? _centerClearThreshold : _centerEnterThreshold;

      if (offset.abs() > threshold) {
        final moveRight = offset < 0;
        return _Correction(
          axis: _Axis.centering,
          direction: moveRight ? _Direction.positive : _Direction.negative,
          message: GuidanceMessage(
            state: PoseTrackingState.guidance,
            category: GuidanceCategory.position,
            textEn: moveRight ? "Move slightly right" : "Move slightly left",
            textBn: moveRight ? "একটু ডানে যান" : "একটু বামে যান",
          ),
        );
      }
    }

    // 3. Shoulder tilt.
    if (leftShoulder != null && rightShoulder != null) {
      final tilt = leftShoulder.y - rightShoulder.y;
      final wasTiltActive = _activeCorrection?.axis == _Axis.tilt;
      final threshold =
          wasTiltActive ? _shoulderTiltClearThreshold : _shoulderTiltEnterThreshold;

      if (tilt.abs() > threshold) {
        return _Correction(
          axis: _Axis.tilt,
          direction: tilt > 0 ? _Direction.positive : _Direction.negative,
          message: const GuidanceMessage(
            state: PoseTrackingState.guidance,
            category: GuidanceCategory.pose,
            textEn: "Level your shoulders",
            textBn: "কাঁধ সোজা রাখুন",
          ),
        );
      }
    }

    return null;
  }

  double? _horizontalCenter(
    Landmark? leftShoulder,
    Landmark? rightShoulder,
    Landmark? nose,
  ) {
    if (leftShoulder != null && rightShoulder != null) {
      return (leftShoulder.x + rightShoulder.x) / 2;
    }
    return nose?.x;
  }
}

enum _Axis { framing, centering, tilt }

enum _Direction { positive, negative }

class _Correction {
  final _Axis axis;
  final _Direction direction;
  final GuidanceMessage message;

  const _Correction({
    required this.axis,
    required this.direction,
    required this.message,
  });
}
