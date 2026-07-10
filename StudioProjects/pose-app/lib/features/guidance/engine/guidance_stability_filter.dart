import '../domain/enums/guidance_enums.dart';

/// Smooths the stream of [GuidanceSignal]s so the user doesn't see
/// flickering instructions every frame.
///
/// Algorithm:
/// 1. Track the candidate (latest) signal each frame.
/// 2. If it matches the currently-displayed signal → reset confirmation.
/// 3. If it differs → increment confirmation counter.
/// 4. Once counter ≥ `confirmationFrames` AND the cooldown has elapsed,
///    promote the candidate to displayed.
/// 5. Never show the same instruction more than `maxInstructionPerMinute`.
class GuidanceStabilityFilter {
  GuidanceStabilityFilter({
    required this.confirmationFrames,
    required this.cooldownFrames,
    required this.maxPerMinute,
  });

  final int confirmationFrames;
  final int cooldownFrames;
  final int maxPerMinute;

  GuidanceSignal _displayed = GuidanceSignal.empty;
  GuidanceSignal _candidate = GuidanceSignal.empty;
  int _candidateCount = 0;
  int _framesSinceLastSwitch = 0;

  // Rolling 60s window of timestamps (frame counts) when we emitted.
  final List<int> _emitHistory = [];

  /// Process the latest signal; returns the signal that should be
  /// displayed right now (may be unchanged from last frame).
  GuidanceSignal process(GuidanceSignal incoming, {int? frameId}) {
    final fid = frameId ?? 0;

    if (_isSameInstruction(incoming, _candidate)) {
      _candidateCount++;
    } else {
      _candidate = incoming;
      _candidateCount = 1;
    }

    _framesSinceLastSwitch++;

    // Should we promote the candidate?
    final sameAsDisplayed = _isSameInstruction(_candidate, _displayed);
    if (!sameAsDisplayed &&
        _candidateCount >= confirmationFrames &&
        _framesSinceLastSwitch >= cooldownFrames &&
        _withinRateLimit(fid)) {
      _displayed = _candidate;
      _framesSinceLastSwitch = 0;
      _emitHistory.add(fid);
      _pruneHistory(fid);
    }

    return _displayed;
  }

  bool _isSameInstruction(GuidanceSignal a, GuidanceSignal b) {
    // Same instruction type + same direction = stable enough.
    return a.instruction == b.instruction && a.direction == b.direction;
  }

  bool _withinRateLimit(int now) {
    _pruneHistory(now);
    return _emitHistory.length < maxPerMinute;
  }

  void _pruneHistory(int now) {
    // Assume 15 FPS steady-state; 60s = 900 frames.
    const sixtySecondsFrames = 900;
    _emitHistory.removeWhere((t) => now - t > sixtySecondsFrames);
  }

  GuidanceSignal get current => _displayed;

  void reset() {
    _displayed = GuidanceSignal.empty;
    _candidate = GuidanceSignal.empty;
    _candidateCount = 0;
    _framesSinceLastSwitch = 0;
    _emitHistory.clear();
  }
}
