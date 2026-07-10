/// Categories the capture engine scores. Each factor produces a
/// sub-score in [0..1]; the engine combines them via normalized
/// weights from [CaptureConfig].
enum CaptureFactor {
  pose,        // body landmark quality, alignment
  stability,   // subject + camera motion
  face,        // face visibility, eye openness, smile (Day 12+ plugs in)
  composition, // rule of thirds, leading space (Day 12 plugs in)
  framing,     // subject size + centering + headroom
  confidence,  // aggregate detection confidence
}

/// Reason the engine suppressed / cancelled a capture. Surfaced to
/// the UI as user-friendly copy.
enum CaptureSuppressReason {
  none,
  userDisabled,
  multiplePeople,
  noFace,
  closedEyes,
  lowLight,
  subjectMoving,
  cameraShake,
  poseUnstable,
  lowConfidence,
  userExited,
  manualCancel,
  captureFailed,
}

/// Reason a capture attempt failed post-shutter. Drives the retry
/// strategy + the user-facing tip.
enum CaptureFailureReason {
  none,
  motionBlur,
  closedEyes,
  lostTracking,
  lowConfidence,
  encoderError,
  unknown,
}
