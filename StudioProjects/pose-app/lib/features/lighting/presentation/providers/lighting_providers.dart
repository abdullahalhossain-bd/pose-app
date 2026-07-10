import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../config/lighting_config.dart';
import '../../domain/entities/lighting_score.dart';
import '../../domain/enums/lighting_enums.dart';
import '../../engine/lighting_analyzer.dart';
import '../../engine/lighting_recommendation_engine.dart';

// ── Config ───────────────────────────────────────────────────────
final lightingConfigProvider =
    StateProvider<LightingConfig>((ref) => const LightingConfig());

// ── Engine singletons ────────────────────────────────────────────
final lightingAnalyzerProvider = Provider<LightingAnalyzer>(
  (ref) => LightingAnalyzer(ref.watch(lightingConfigProvider)),
);

final lightingRecommendationEngineProvider =
    Provider<LightingRecommendationEngine>((ref) {
  return LightingRecommendationEngine(
    config: ref.watch(lightingConfigProvider),
    analyzer: ref.watch(lightingAnalyzerProvider),
  );
});

final lightingStabilityFilterProvider =
    Provider<LightingStabilityFilter>((ref) {
  final c = ref.watch(lightingConfigProvider);
  return LightingStabilityFilter(
    confirmationFrames: c.confirmationFrames,
    cooldownFrames: c.cooldownFrames,
    maxPerMinute: c.maxRecommendationPerMinute,
  );
});

// ── Latest lighting score (consumed by debug HUD + capture engine) ──
final lightingScoreProvider =
    StateNotifierProvider<LightingScoreNotifier, LightingScore?>(
        (ref) => LightingScoreNotifier());

class LightingScoreNotifier extends StateNotifier<LightingScore?> {
  LightingScoreNotifier() : super(null);
  void update(LightingScore? s) => state = s;
}

// ── Latest stable recommendation (consumed by overlay) ──────────
final lightingRecommendationProvider = StateNotifierProvider<
    LightingRecommendationNotifier, LightingRecommendation>((ref) {
  return LightingRecommendationNotifier();
});

class LightingRecommendationNotifier
    extends StateNotifier<LightingRecommendation> {
  LightingRecommendationNotifier() : super(LightingRecommendation.empty);

  void update(LightingRecommendation r) {
    if (r.type != state.type) {
      state = r;
    } else {
      state = LightingRecommendation(
        type: r.type,
        priority: r.priority,
        confidence: r.confidence,
        rule: r.rule,
        shortText: r.shortText,
        longText: r.longText,
      );
    }
  }

  void clear() => state = LightingRecommendation.empty;
}

/// Push lighting data into the engine. Called by the camera frame
/// listener once per frame.
void pushLightingFrame(
  Ref ref, {
  required dynamic luma,
  required int lumaWidth,
  required int lumaHeight,
  required dynamic uPlane,
  required dynamic vPlane,
  required dynamic pose,
}) {
  final analyzer = ref.read(lightingAnalyzerProvider);
  final score = analyzer.analyze(
    luma: luma,
    lumaWidth: lumaWidth,
    lumaHeight: lumaHeight,
    uPlane: uPlane,
    vPlane: vPlane,
    pose: pose,
  );
  final candidate =
      ref.read(lightingRecommendationEngineProvider).decide(score);
  final stable = ref
      .read(lightingStabilityFilterProvider)
      .process(candidate, frameId: DateTime.now().microsecondsSinceEpoch);

  ref.read(lightingScoreProvider.notifier).update(score);
  ref.read(lightingRecommendationProvider.notifier).update(stable);
}
