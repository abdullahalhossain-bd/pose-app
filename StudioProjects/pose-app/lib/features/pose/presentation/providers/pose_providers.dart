import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ai/presentation/providers/ai_providers.dart';
import '../../data/datasources/mlkit_pose_backend.dart';
import '../../data/repositories/pose_processor.dart';
import '../../domain/entities/pose_sample.dart';
import '../../domain/entities/pose_state.dart';
import '../../smoothing/pose_smoother.dart';
import '../../tracking/pose_tracker.dart';

/// ── Override ML Kit as the active pose backend ────────────────────
///
/// This single override swaps the Day 8 stub out for ML Kit. The
/// pipeline, state machine, and overlays all remain unchanged.
final poseBackendOverrideProvider = Provider<MlKitPoseBackend>((ref) {
  return MlKitPoseBackend();
});

/// ── Pose infrastructure singletons ────────────────────────────────
final poseTrackerProvider = Provider<PoseTracker>(
  (ref) => PoseTracker(),
);

final poseSmootherProvider = Provider<PoseSmoother>(
  (ref) => PoseSmoother(),
);

final poseProcessorProvider = Provider<PoseProcessor>(
  (ref) => PoseProcessor(),
);

/// ── Pose state ────────────────────────────────────────────────────
final poseStateProvider =
    StateNotifierProvider<PoseStateController, PoseState>(
  (ref) => PoseStateController(),
);

/// Latest tracked poses (consumed by overlays).
final poseSamplesProvider =
    StateNotifierProvider<PoseSampleNotifier, List<PoseSample>>(
  (ref) => PoseSampleNotifier(),
);

/// Latest pose context (edge cases: too close / too far / partial body).
final poseContextProvider = Provider<PoseContext>((ref) {
  // Read latest context emitted by the pipeline. Day 10+ reads this
  // to decide which guidance hints to show.
  return ref.watch(_poseContextInternalProvider);
});

final _poseContextInternalProvider = StateProvider<PoseContext>(
  (ref) => const PoseContext(),
);

class PoseSampleNotifier extends StateNotifier<List<PoseSample>> {
  PoseSampleNotifier() : super(const []);
  void update(List<PoseSample> next) => state = next;
}

class PoseStateController extends StateNotifier<PoseState> {
  PoseStateController() : super(const PoseIdle());

  void idle() => state = const PoseIdle();
  void searching() => state = const PoseSearching();

  void transitionTo(PoseState next) {
    if (state == next) return;
    state = next;
  }
}

/// Helper used by the pipeline to push fresh pose context.
void pushPoseContext(Ref ref, PoseContext ctx) {
  ref.read(_poseContextInternalProvider.notifier).state = ctx;
}
