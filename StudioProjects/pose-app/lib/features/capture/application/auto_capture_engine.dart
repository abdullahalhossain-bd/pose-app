import '../domain/auto_capture_state.dart';

/// Result of one evaluation cycle: the state to show the user, plus
/// whether THIS cycle is the one that should actually trigger a
/// capture. Separated from [AutoCaptureState] itself so the caller
/// doesn't have to infer "did a capture just happen" from a state
/// transition — it's an explicit, one-shot signal.
class AutoCaptureEvaluation {
  final AutoCaptureState state;
  final bool shouldCapture;

  const AutoCaptureEvaluation({required this.state, required this.shouldCapture});
}

/// Decides when a sustained "hold" pose should trigger an automatic
/// capture. Deliberately opt-in and defaults to disabled (spec §5:
/// "Auto Capture MUST remain optional. Manual shutter must always
/// exist.") — this engine never captures anything by itself unless
/// explicitly enabled, and the manual shutter (CaptureButton) works
/// identically whether this is on or off.
///
/// Uses wall-clock time (via an injectable clock, for testability)
/// rather than counting evaluation cycles, so the countdown duration
/// means the same thing regardless of device tier / frame-sample rate
/// (spec §9 — low-tier devices sample pose less often; a frame-count-
/// based countdown would silently run slower on them).
///
/// This is intentionally separate from [GuidanceEngine] — it only
/// consumes [GuidanceEngine]'s already-debounced `hold` signal, it
/// doesn't reach into pose data itself, matching the same "consume,
/// don't own" pattern used for lighting/composition/attention.
class AutoCaptureEngine {
  AutoCaptureEngine({
    this.holdDuration = const Duration(seconds: 2),
    this.cooldownDuration = const Duration(seconds: 3),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final Duration holdDuration;
  final Duration cooldownDuration;
  final DateTime Function() _clock;

  bool _enabled = false;
  DateTime? _holdStartedAt;
  DateTime? _cooldownUntil;

  bool get isEnabled => _enabled;

  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (!enabled) {
      _holdStartedAt = null;
      _cooldownUntil = null;
    }
  }

  /// [poseIsHolding] should be `guidance.state == PoseTrackingState.hold`
  /// — i.e. GuidanceEngine's own sustained-good-pose signal, already
  /// debounced. This engine adds its own, separate timer on top of that
  /// (how long has the ALREADY-debounced hold persisted), rather than
  /// re-implementing hysteresis over raw pose data.
  AutoCaptureEvaluation evaluate(bool poseIsHolding) {
    final now = _clock();

    if (!_enabled) {
      return const AutoCaptureEvaluation(
        state: AutoCaptureState.disabled,
        shouldCapture: false,
      );
    }

    if (_cooldownUntil != null) {
      if (now.isBefore(_cooldownUntil!)) {
        final remaining = _cooldownUntil!.difference(now);
        return AutoCaptureEvaluation(
          state: AutoCaptureState(
            status: AutoCaptureStatus.cooldown,
            secondsRemaining: _ceilSeconds(remaining),
          ),
          shouldCapture: false,
        );
      }
      _cooldownUntil = null;
    }

    if (!poseIsHolding) {
      _holdStartedAt = null;
      return const AutoCaptureEvaluation(
        state: AutoCaptureState.waiting,
        shouldCapture: false,
      );
    }

    _holdStartedAt ??= now;
    final elapsed = now.difference(_holdStartedAt!);
    final remaining = holdDuration - elapsed;

    if (remaining <= Duration.zero) {
      _holdStartedAt = null;
      _cooldownUntil = now.add(cooldownDuration);
      return AutoCaptureEvaluation(
        state: AutoCaptureState(
          status: AutoCaptureStatus.cooldown,
          secondsRemaining: cooldownDuration.inSeconds,
        ),
        shouldCapture: true,
      );
    }

    return AutoCaptureEvaluation(
      state: AutoCaptureState(
        status: AutoCaptureStatus.countingDown,
        secondsRemaining: _ceilSeconds(remaining),
      ),
      shouldCapture: false,
    );
  }

  int _ceilSeconds(Duration d) => (d.inMilliseconds / 1000).ceil().clamp(0, 999);

  void reset() {
    _holdStartedAt = null;
    _cooldownUntil = null;
  }
}
