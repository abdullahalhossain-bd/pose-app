/// Auto Capture is opt-in and always sits alongside the manual shutter,
/// never replacing it (spec §5: "Auto Capture MUST remain optional.
/// Manual shutter must always exist.").
enum AutoCaptureStatus {
  /// Feature is off (the default — see AutoCaptureEngine's class doc
  /// for why defaulting to off matters for a brand-new feature).
  disabled,

  /// Feature is on, but the pose isn't currently "hold"-worthy.
  waiting,

  /// Pose has been "hold"-worthy long enough that a countdown to
  /// automatic capture is running.
  countingDown,

  /// A brief cooldown after an automatic capture, so the same held
  /// pose doesn't immediately trigger a second capture.
  cooldown,
}

class AutoCaptureState {
  final AutoCaptureStatus status;

  /// Whole seconds remaining in the countdown, only meaningful when
  /// [status] is [AutoCaptureStatus.countingDown].
  final int secondsRemaining;

  const AutoCaptureState({
    this.status = AutoCaptureStatus.disabled,
    this.secondsRemaining = 0,
  });

  static const AutoCaptureState disabled =
      AutoCaptureState(status: AutoCaptureStatus.disabled);
  static const AutoCaptureState waiting =
      AutoCaptureState(status: AutoCaptureStatus.waiting);
}
