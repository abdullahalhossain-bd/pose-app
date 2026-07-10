import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../camera/presentation/providers/camera_provider.dart';
import '../../ai/presentation/providers/ai_providers.dart';
import '../../ai/pipeline/ai_pipeline.dart';

/// Glues the camera frame stream to the AI pipeline.
///
/// Why a dedicated controller? Because:
/// 1. The camera provider is created with `onFrame` set at construction
///    time — but the pipeline needs to exist first. Bootstrapping order
///    matters; this controller handles it.
/// 2. We want one obvious place to enable/disable AI features without
///    leaking that concern into either the camera or the AI module.
class AiCameraBridge {
  AiCameraBridge(this._ref);
  final Ref _ref;

  bool _started = false;

  /// Initialize the AI pipeline + wire the camera frame sink.
  Future<void> start() async {
    if (_started) return;
    _started = true;

    final pipeline = _ref.read(aiPipelineProvider);
    await pipeline.initialize();

    // The camera notifier was constructed with onFrame=null. We replace
    // it with a fresh notifier that sinks into the pipeline.
    // (Riverpod's StateNotifierProvider doesn't allow swapping one
    // notifier for another, so for Day 8 we register the sink lazily.)
    //
    // Day 9 will refactor `CameraNotifier` to expose `setFrameSink()`
    // so we can avoid the recreation. For Day 8, the wiring is wired
    // at notifier construction via an override in main.dart.
  }

  Future<void> stop() async {
    if (!_started) return;
    _started = false;
    await _ref.read(aiPipelineProvider).dispose();
  }

  /// Toggle the user-facing AI toggle.
  Future<void> toggleAi(bool enabled) async {
    final camera = _ref.read(cameraProvider.notifier);
    if (enabled) {
      await camera.enableAi();
    } else {
      await camera.disableAi();
    }
  }
}

final aiCameraBridgeProvider = Provider<AiCameraBridge>((ref) {
  return AiCameraBridge(ref);
});
