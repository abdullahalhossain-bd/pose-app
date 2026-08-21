import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ai/domain/entities/ai_frame.dart';
import '../../../ai/domain/entities/detection.dart';
import '../../../ai/pipeline/ai_pipeline.dart';
import '../../../ai/state/ai_state.dart';
import '../../../guidance/engine/guidance_pipeline_stage.dart';
import '../../domain/entities/pose_sample.dart';
import '../../domain/entities/pose_state.dart';
import '../../presentation/providers/pose_providers.dart';
import '../../smoothing/pose_smoother.dart';
import '../../tracking/pose_tracker.dart';
import 'pose_processor.dart';

/// Pose-specific post-processing stage that runs AFTER [AiPipeline]
/// inference but BEFORE the result reaches overlays.
///
/// Responsibilities:
/// 1. Extract [PoseSample]s from each `DetectionResult` (ML Kit
///    backend attaches them via metadata).
/// 2. Filter out noisy landmarks (likelihood < threshold).
/// 3. Run [PoseTracker] to assign stable IDs.
/// 4. Run [PoseSmoother] to reduce per-frame jitter.
/// 5. Run [PoseProcessor] to classify edge cases + decide [PoseState].
/// 6. Forward smoothed samples to the Day 10 guidance stage so it can
///    evaluate pose quality and emit a guidance signal.
///
/// The Day 8 [AiPipeline] still owns the back-pressure gate and the
/// backend call. This stage adds pose semantics without modifying
/// the base pipeline.
class PosePipelineStage {
  PosePipelineStage({
    required this.tracker,
    required this.smoother,
    required this.processor,
    required this.onState,
    required this.onSamples,
    required this.onContext,
    this.onGuidance,
  });

  final PoseTracker tracker;
  final PoseSmoother smoother;
  final PoseProcessor processor;

  final void Function(PoseState) onState;
  final void Function(List<PoseSample>) onSamples;
  final void Function(PoseContext) onContext;

  /// Optional hook invoked with the latest smoothed samples so the
  /// guidance engine (Day 10) can evaluate pose quality.
  final void Function(List<PoseSample>)? onGuidance;

  bool _wasTracking = false;

  /// Process the raw detections emitted by [AiPipeline].
  void process({
    required List<DetectionResult> detections,
    required AiFrame frame,
    required bool lowLight,
  }) {
    // 1. Extract PoseSamples (only those whose kind == 'person').
    final raw = detections
        .where((d) => d.kind == 'person')
        .map((d) => d.metadata['pose'])
        .whereType<PoseSample>()
        .toList();

    if (raw.isEmpty) {
      // Maintain track loss state.
      final context = PoseContext(lowLight: lowLight);
      final state = processor.decide(
        tracked: const [],
        context: context,
        wasTracking: _wasTracking,
      );
      onState(state);
      onSamples(const []);
      onContext(context);
      onGuidance?.call(const []);
      _wasTracking = state is PoseTracking || state is PoseReady;
      return;
    }

    // 2. Filter noisy landmarks (below threshold likelihood).
    final filtered = raw
        .map((p) => PoseSample(
      id: p.id,
      landmarks: p.landmarks.where((l) => l.likelihood >= 0.3).toList(),
      confidence: p.confidence,
      timestamp: p.timestamp,
      boundingBox: p.boundingBox,
    ))
        .toList();

    // 3. Track: assign stable IDs across frames.
    final tracked = tracker.update(filtered);

    // 4. Smooth: per-landmark One-Euro filter on each tracked pose.
    final List<PoseSample> smoothed =
        tracked.map(smoother.smooth).toList();

    // 5. Decide state.
    final context = processor.classify(
      poses: smoothed,
      lowLight: lowLight,
    );
    final state = processor.decide(
      tracked: smoothed,
      context: context,
      wasTracking: _wasTracking,
    );

    onSamples(smoothed);
    onState(state);
    onContext(context);

    // 6. Forward to guidance engine (Day 10).
    onGuidance?.call(smoothed);

    _wasTracking = state is PoseTracking || state is PoseReady;
  }

  void reset() {
    tracker.reset();
    smoother.reset();
    _wasTracking = false;
  }
}