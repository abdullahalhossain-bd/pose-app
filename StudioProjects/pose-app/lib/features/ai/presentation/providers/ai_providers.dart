import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/error/error_handler.dart';
import '../../../guidance/engine/guidance_pipeline_stage.dart';
import '../../../pose/data/datasources/mlkit_pose_backend.dart';
import '../../../pose/data/repositories/pose_pipeline_stage.dart';
import '../../../pose/data/repositories/pose_processor.dart';
import '../../../pose/domain/entities/pose_sample.dart';
import '../../../pose/domain/entities/pose_state.dart';
import '../../../pose/presentation/providers/pose_providers.dart';
import '../../../pose/smoothing/pose_smoother.dart';
import '../../../pose/tracking/pose_tracker.dart';
import '../../config/ai_config.dart';
import '../../data/datasources/stub_inference_backend.dart';
import '../../domain/entities/ai_frame.dart';
import '../../domain/entities/detection.dart';
import '../../domain/repositories/inference_backend.dart';
import '../../performance/ai_performance_monitor.dart';
import '../../performance/thermal_monitor.dart';
import '../../pipeline/ai_pipeline.dart';
import '../../state/ai_state.dart';
import 'ai_state_controller.dart';

/// ── Config ─────────────────────────────────────────────────────────
final aiConfigProvider = StateProvider<AiConfig>((ref) => const AiConfig());

/// ── Backend ────────────────────────────────────────────────────────
///
/// Day 9: ML Kit Pose Detection is now the active backend. The Day 8
/// stub is kept for tests / fallback. To swap backends, override this
/// provider in main.dart based on AppConfig.env.
final inferenceBackendProvider = Provider<InferenceBackend>((ref) {
  return ref.watch(poseBackendOverrideProvider);
});

/// ── Performance monitoring ────────────────────────────────────────
final aiPerformanceMonitorProvider =
    Provider<AiPerformanceMonitor>((ref) => AiPerformanceMonitor(
          logger: ref.watch(loggerProvider),
        ));

final thermalMonitorProvider = Provider<ThermalMonitor>(
  (ref) => ThermalMonitor(
    logger: ref.watch(loggerProvider),
  ),
);

/// ── State ──────────────────────────────────────────────────────────
final aiStateProvider =
    StateNotifierProvider<AiStateController, AiState>((ref) {
  return AiStateController(
    errorHandler: ref.watch(errorHandlerProvider),
    logger: ref.watch(loggerProvider),
  );
});

/// ── Pose pipeline stage (post-inference pose processing) ──────────
final posePipelineStageProvider = Provider<PosePipelineStage>((ref) {
  return PosePipelineStage(
    tracker: ref.watch(poseTrackerProvider),
    smoother: ref.watch(poseSmootherProvider),
    processor: ref.watch(poseProcessorProvider),
    onState: (s) =>
        ref.read(poseStateProvider.notifier).transitionTo(s),
    onSamples: (s) =>
        ref.read(poseSamplesProvider.notifier).update(s),
    onContext: (c) => pushPoseContext(ref, c),
    onGuidance: (poses) => pushPosesToGuidance(ref, poses),
  );
});

/// ── Pipeline ──────────────────────────────────────────────────────
final aiPipelineProvider = Provider<AiPipeline>((ref) {
  final poseStage = ref.watch(posePipelineStageProvider);
  return AiPipeline(
    backend: ref.watch(inferenceBackendProvider),
    config: ref.watch(aiConfigProvider),
    monitor: ref.watch(aiPerformanceMonitorProvider),
    thermal: ref.watch(thermalMonitorProvider),
    logger: ref.watch(loggerProvider),
    onStateChange: (s) =>
        ref.read(aiStateProvider.notifier).transitionTo(s),
    onResult: (results) {
      // 1. Forward to the Day 8 detection overlay (kept for non-pose AI).
      ref.read(aiDetectionsProvider.notifier).update(results);

      // 2. Run the pose-specific stage: tracking → smoothing → state.
      //    We pass a synthetic frame with lux=0 (low-light check is
      //    done by the AiPipeline's _decide() and surfaced via AiState).
      poseStage.process(
        detections: results,
        frame: _lastFrame ?? _emptyFrame,
        lowLight: false,
      );
    },
  );
});

// Last-frame cache so the post-processing stage has access to the
// frame context (used for low-light + edge case classification).
AiFrame? _lastFrame;
final AiFrame _emptyFrame = AiFrame(
  id: -1,
  width: 1,
  height: 1,
  planes: const [],
  rotationDegrees: 0,
  timestamp: 0,
);

/// ── Latest detections (consumed by overlays) ─────────────────────
final aiDetectionsProvider =
    StateNotifierProvider<_DetectionNotifier, List<DetectionResult>>(
        (ref) {
  return _DetectionNotifier();
});

class _DetectionNotifier extends StateNotifier<List<DetectionResult>> {
  _DetectionNotifier() : super(const []);
  void update(List<DetectionResult> next) => state = next;
}
