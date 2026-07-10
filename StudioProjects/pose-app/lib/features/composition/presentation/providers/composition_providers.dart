import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/di/providers.dart';
import '../../config/composition_config.dart';
import '../../domain/entities/composition_recommendation.dart';
import '../../domain/entities/composition_score.dart';
import '../../domain/enums/scene_type.dart';
import '../../engine/composition_recommendation_engine.dart';
import '../../engine/composition_scorer.dart';
import '../../engine/scene_classifier.dart';
import '../../storage/composition_prefs.dart';
// ── কনফিগ ───────────────────────────────────────────────────────
final compositionConfigProvider =
    StateProvider<CompositionConfig>((ref) => const CompositionConfig());

// ── প্রিফারেন্স ───────────────────────────────────────────────────
final compositionPrefsProvider = StateNotifierProvider<
    CompositionPrefsNotifier, CompositionPrefs>((ref) {
  return CompositionPrefsNotifier(ref.watch(sharedPreferencesProvider));
});

class CompositionPrefsNotifier extends StateNotifier<CompositionPrefs> {
  CompositionPrefsNotifier(this._prefs) : super(const CompositionPrefs()) {
    _load();
  }
  final SharedPreferences _prefs;

  Future<void> _load() async {
    state = await CompositionPrefs.load(_prefs);
  }

  Future<void> setGrid(GridOverlayType type) async {
    state = state.copyWith(enabledGrid: type);
    await state.save(_prefs);
  }

  Future<void> toggleHints(bool enabled) async {
    state = state.copyWith(showCompositionHints: enabled);
    await state.save(_prefs);
  }
}

// ── ইঞ্জিন উপাদান ────────────────────────────────────────────────
final compositionScorerProvider = Provider<CompositionScorer>(
  (ref) => CompositionScorer(ref.watch(compositionConfigProvider)),
);

final sceneClassifierProvider = Provider<SceneClassifier>(
  (ref) => SceneClassifier(ref.watch(compositionConfigProvider)),
);

final compositionRecommendationEngineProvider =
    Provider<CompositionRecommendationEngine>((ref) {
  return CompositionRecommendationEngine(
    config: ref.watch(compositionConfigProvider),
    scorer: ref.watch(compositionScorerProvider),
    sceneClassifier: ref.watch(sceneClassifierProvider),
  );
});

final compositionStabilityFilterProvider =
    Provider<CompositionStabilityFilter>((ref) {
  final c = ref.watch(compositionConfigProvider);
  return CompositionStabilityFilter(
    confirmationFrames: c.confirmationFrames,
    cooldownFrames: c.cooldownFrames,
  );
});

// ── সর্বশেষ স্কোর (ডিবাগ HUD + ক্যাপচার ইঞ্জিন দ্বারা ব্যবহৃত) ────
final compositionScoreProvider =
    StateNotifierProvider<CompositionScoreNotifier, CompositionScore?>(
        (ref) => CompositionScoreNotifier());

class CompositionScoreNotifier extends StateNotifier<CompositionScore?> {
  CompositionScoreNotifier() : super(null);
  void update(CompositionScore? s) => state = s;
}

// ── সর্বশেষ সিন কন্টেক্সট ────────────────────────────────────────
final sceneContextProvider =
    StateNotifierProvider<SceneContextNotifier, SceneContext?>(
        (ref) => SceneContextNotifier());

class SceneContextNotifier extends StateNotifier<SceneContext?> {
  SceneContextNotifier() : super(null);
  void update(SceneContext? s) => state = s;
}

// ── সর্বশেষ স্থিতিশীল রেকমেন্ডেশন (ওভারলে দ্বারা ব্যবহৃত) ─────────
final compositionRecommendationProvider =
    StateNotifierProvider<CompositionRecommendationNotifier, CompositionRecommendation>(
        (ref) => CompositionRecommendationNotifier());

class CompositionRecommendationNotifier
    extends StateNotifier<CompositionRecommendation> {
  CompositionRecommendationNotifier()
      : super(CompositionRecommendation.empty);

  void update(CompositionRecommendation r) {
    if (r.type != state.type) {
      state = r;
    } else {
      state = CompositionRecommendation(
        type: r.type,
        priority: r.priority,
        confidence: r.confidence,
        rule: r.rule,
        shortText: r.shortText,
        longText: r.longText,
      );
    }
  }

  void clear() => state = CompositionRecommendation.empty;
}

/// পোজ ব্যাচ কম্পোজিশন ইঞ্জিনে পুশ করার জন্য সুবিধা। পোজ স্টেজ দ্বারা কল করা হয়।
void pushPosesToComposition(
  Ref ref,
  List<dynamic> poses, {
  required bool isFrontCamera,
  required dynamic luma,
  required int lumaWidth,
  required int lumaHeight,
}) {
  final engine = ref.read(compositionRecommendationEngineProvider);
  final score = engine.evaluate(
    pose: poses,
    luma: luma,
    lumaWidth: lumaWidth,
    lumaHeight: lumaHeight,
  );
  final scene = engine.sceneClassifier.classify(
    poses: poses.cast(),
    isFrontCamera: isFrontCamera,
  );
  final candidate = engine.decide(score: score, scene: scene);
  final stable = ref
      .read(compositionStabilityFilterProvider)
      .process(candidate);

  ref.read(compositionScoreProvider.notifier).update(score);
  ref.read(sceneContextProvider.notifier).update(scene);
  ref.read(compositionRecommendationProvider.notifier).update(stable);
}
