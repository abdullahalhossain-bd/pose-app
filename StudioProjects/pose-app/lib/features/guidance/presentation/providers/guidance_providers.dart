import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/guidance_config.dart';
import '../../domain/enums/guidance_enums.dart';
import '../../engine/guidance_engine.dart';
import '../../engine/guidance_stability_filter.dart';
import '../../services/guidance_feedback_services.dart';

/// ── Config ───────────────────────────────────────────────────────
final guidanceConfigProvider =
    StateProvider<GuidanceConfig>((ref) => const GuidanceConfig());

/// ── Engine + filter ──────────────────────────────────────────────
final guidanceEngineProvider = Provider<GuidanceEngine>(
  (ref) => GuidanceEngine(ref.watch(guidanceConfigProvider)),
);

final guidanceStabilityFilterProvider =
    Provider<GuidanceStabilityFilter>((ref) {
  final c = ref.watch(guidanceConfigProvider);
  return GuidanceStabilityFilter(
    confirmationFrames: c.confirmationFrames,
    cooldownFrames: c.cooldownFrames,
    maxPerMinute: c.maxInstructionPerMinute,
  );
});

/// ── Services ─────────────────────────────────────────────────────
final guidanceAudioServiceProvider = Provider<GuidanceAudioService>(
  (ref) => StubGuidanceAudioService(
    isEnabled: ref.watch(guidanceConfigProvider).audioEnabled,
  ),
);

final guidanceHapticServiceProvider = Provider<GuidanceHapticService>(
  (ref) => StubGuidanceHapticService(
    isEnabled: ref.watch(guidanceConfigProvider).hapticEnabled,
  ),
);

/// ── Latest guidance signal (consumed by overlay) ────────────────
final guidanceSignalProvider =
    StateNotifierProvider<GuidanceSignalNotifier, GuidanceSignal>(
  (ref) => GuidanceSignalNotifier(),
);

/// Latest full evaluation result (consumed by debug HUD only).
final guidanceEvaluationProvider =
    StateNotifierProvider<GuidanceEvaluationNotifier, GuidanceEvaluation?>(
  (ref) => GuidanceEvaluationNotifier(),
);

class GuidanceSignalNotifier extends StateNotifier<GuidanceSignal> {
  GuidanceSignalNotifier() : super(GuidanceSignal.empty);
  void update(GuidanceSignal s) {
    if (s.instruction != state.instruction || s.direction != state.direction) {
      state = s;
    } else {
      // Same instruction — just update confidence silently.
      state = GuidanceSignal(
        instruction: s.instruction,
        priority: s.priority,
        status: s.status,
        confidence: s.confidence,
        rule: s.rule,
        direction: s.direction,
        targetX: s.targetX,
        targetY: s.targetY,
        targetRadius: s.targetRadius,
        shortText: s.shortText,
        longText: s.longText,
      );
    }
  }

  void clear() => state = GuidanceSignal.empty;
}

class GuidanceEvaluationNotifier
    extends StateNotifier<GuidanceEvaluation?> {
  GuidanceEvaluationNotifier() : super(null);
  void update(GuidanceEvaluation e) => state = e;
  void clear() => state = null;
}

/// Lightweight wrapper carrying the evaluation result + the active
/// signal + the processing latency. Used by debug HUD.
class GuidanceEvaluation {
  const GuidanceEvaluation({
    required this.signal,
    required this.overallScore,
    required this.evaluationConfidence,
    required this.activeRule,
    required this.latencyMicros,
    required this.issueCount,
  });

  final GuidanceSignal signal;
  final double overallScore;
  final double evaluationConfidence;
  final String activeRule;
  final int latencyMicros;
  final int issueCount;
}
