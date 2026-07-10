import '../domain/enums/guidance_enums.dart';

/// Contract for converting a [GuidanceSignal] into spoken feedback.
///
/// Day 10 ships a [StubGuidanceAudioService] that does nothing — the
/// contract is what matters. Day 14 plugs in flutter_tts for real
/// voice coaching with locale-aware voices.
abstract class GuidanceAudioService {
  Future<void> initialize();
  Future<void> speak(GuidanceSignal signal);
  Future<void> stop();
  Future<void> dispose();

  bool get isEnabled;
  set isEnabled(bool value);
}

/// No-op implementation. Used when audio is disabled in user prefs
/// or in tests. Real TTS is added Day 14.
class StubGuidanceAudioService implements GuidanceAudioService {
  StubGuidanceAudioService({this.isEnabled = false});
  @override
  bool isEnabled;
  @override
  Future<void> initialize() async {}
  @override
  Future<void> speak(GuidanceSignal signal) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}
}

/// Contract for haptic feedback on guidance changes.
abstract class GuidanceHapticService {
  Future<void> initialize();
  Future<void> onNewSignal(GuidanceSignal signal);
  Future<void> onStatusChange(GuidanceStatus status);
  Future<void> dispose();

  bool get isEnabled;
  set isEnabled(bool value);
}

/// No-op implementation; Day 14 wires `HapticFeedback` from
/// `flutter/services`.
class StubGuidanceHapticService implements GuidanceHapticService {
  StubGuidanceHapticService({this.isEnabled = true});
  @override
  bool isEnabled;
  @override
  Future<void> initialize() async {}
  @override
  Future<void> onNewSignal(GuidanceSignal signal) async {}
  @override
  Future<void> onStatusChange(GuidanceStatus status) async {}
  @override
  Future<void> dispose() async {}
}
