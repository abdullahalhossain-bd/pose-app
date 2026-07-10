import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../capture/presentation/providers/capture_providers.dart';
import '../../composition/presentation/providers/composition_providers.dart';
import '../../lighting/presentation/providers/lighting_providers.dart';
import '../../pose/domain/entities/pose_sample.dart';
import '../domain/entities/pose_quality_result.dart';
import '../domain/enums/guidance_enums.dart';
import '../engine/guidance_engine.dart';
import '../engine/guidance_stability_filter.dart';
import '../presentation/providers/guidance_providers.dart';
import '../services/guidance_feedback_services.dart';

/// Sits between pose tracking/smoothing (Day 9) and the guidance
/// overlay. For every fresh [PoseSample] batch it:
///
/// 1. Picks the primary (highest-confidence) pose.
/// 2. Runs the [GuidanceEngine] → candidate [GuidanceSignal].
/// 3. Passes through [GuidanceStabilityFilter] → stable signal.
/// 4. Updates Riverpod state + triggers audio/haptic feedback.
/// 5. (Day 11) Forwards to the Capture Decision Engine so it can
///    compute a capture score and decide "ready to capture?".
class GuidancePipelineStage {
  GuidancePipelineStage({
    required this.engine,
    required this.filter,
    required this.audio,
    required this.haptic,
    required this.onSignal,
    required this.onEvaluation,
    this.onCaptureScore,
  });

  final GuidanceEngine engine;
  final GuidanceStabilityFilter filter;
  final GuidanceAudioService audio;
  final GuidanceHapticService haptic;

  final void Function(GuidanceSignal) onSignal;
  final void Function(GuidanceEvaluation) onEvaluation;

  /// Optional hook: the capture engine gets a score every frame so
  /// it can decide "ready to capture?". Day 11 added this.
  final void Function({
    required PoseSample? pose,
    required PoseQualityResult? quality,
    required int personCount,
  })? onCaptureScore;

  int _frameCounter = 0;

  void process(List<PoseSample> poses) {
    if (poses.isEmpty) {
      // Reset stability when subject is lost so the next detection
      // doesn't carry stale state.
      filter.reset();
      onSignal(GuidanceSignal.empty);
      onCaptureScore?.call(
        pose: null,
        quality: null,
        personCount: 0,
      );
      return;
    }

    // Pick primary pose (highest confidence).
    final primary = List<PoseSample>.from(poses)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    final pose = primary.first;

    final stopwatch = Stopwatch()..start();
    final result = engine.evaluate(pose);
    final candidate = engine.decide(pose);
    stopwatch.stop();

    final stable = filter.process(candidate, frameId: _frameCounter++);
    final prevStableInstruction = filter.current.instruction;

    onSignal(stable);

    onEvaluation(GuidanceEvaluation(
      signal: stable,
      overallScore: result.overallScore,
      evaluationConfidence: result.confidence,
      activeRule: stable.rule,
      latencyMicros: stopwatch.elapsedMicroseconds,
      issueCount: result.issues.length,
    ));

    // Day 11: forward to capture engine.
    // Note: face visibility / eyes open / low light are stubbed
    // reasonably for now — Day 12+ plugs real signals in.
    onCaptureScore?.call(
      pose: pose,
      quality: result,
      personCount: poses.length,
    );

    // Trigger feedback only when the displayed instruction actually
    // changed — not on every frame.
    if (stable.instruction != prevStableInstruction) {
      if (audio.isEnabled) audio.speak(stable);
      if (haptic.isEnabled) haptic.onNewSignal(stable);
    }
  }

  void reset() {
    filter.reset();
    _frameCounter = 0;
  }
}

/// Riverpod binding so the stage is constructed with all dependencies.
final guidancePipelineStageProvider = Provider<GuidancePipelineStage>(
  (ref) {
    return GuidancePipelineStage(
      engine: ref.watch(guidanceEngineProvider),
      filter: ref.watch(guidanceStabilityFilterProvider),
      audio: ref.watch(guidanceAudioServiceProvider),
      haptic: ref.watch(guidanceHapticServiceProvider),
      onSignal: (s) => ref.read(guidanceSignalProvider.notifier).update(s),
      onEvaluation: (e) =>
          ref.read(guidanceEvaluationProvider.notifier).update(e),
      onCaptureScore: ({
        required pose,
        required quality,
        required personCount,
      }) {
        // Day 13: push luma + chroma planes to the lighting engine so
        // it can compute exposure / light direction / shadow / color
        // temperature. The actual luma is still null here because the
        // CameraNotifier hasn't been wired to forward it yet — that
        // wiring lands when we plug the camera stream into this stage.
        // For Day 13 we use a synthetic mid-gray luma so the engine
        // produces neutral scores and the overlay can be smoke-tested.
        // TODO(day-14): replace with real luma from CameraNotifier.
        final Uint8List? syntheticLuma = null;
        const syntheticW = 0;
        const syntheticH = 0;

        pushLightingFrame(
          ref,
          luma: syntheticLuma,
          lumaWidth: syntheticW,
          lumaHeight: syntheticH,
          uPlane: null,
          vPlane: null,
          pose: pose,
        );

        // Day 12: push poses to the composition engine.
        pushPosesToComposition(
          ref,
          pose != null ? [pose] : [],
          isFrontCamera: false,
          luma: syntheticLuma,
          lumaWidth: syntheticW,
          lumaHeight: syntheticH,
        );

        // Day 11: forward to the capture engine.
        // Day 13: pull real lowLight state from the lighting engine
        // instead of the hardcoded false stub.
        final lightingScore = ref.read(lightingScoreProvider);
        final faceVisible = pose != null && pose.confidence > 0.7;
        final eyesOpen = faceVisible;
        final lowLight = lightingScore?.isLowLight ?? false;

        // Day 12: composition factor from real CompositionScorer.
        final compositionScore = ref.read(compositionScoreProvider);
        final compositionFactorScore = compositionScore?.overallScore ?? 0.5;

        final score = ref.read(captureDecisionEngineProvider).evaluate(
              pose: pose,
              quality: quality,
              personCount: personCount,
              faceVisible: faceVisible,
              eyesOpen: eyesOpen,
              lowLight: lowLight,
              luma: syntheticLuma,
              lumaWidth: syntheticW,
              lumaHeight: syntheticH,
              compositionOverride: compositionFactorScore,
            );
        ref.read(captureStateProvider.notifier).onNewScore(score);
      },
    );
  },
);

/// Convenience: push pose batch into the guidance stage. Called by the
/// pose pipeline stage after tracking/smoothing completes.
void pushPosesToGuidance(Ref ref, List<PoseSample> poses) {
  ref.read(guidancePipelineStageProvider).process(poses);
}
