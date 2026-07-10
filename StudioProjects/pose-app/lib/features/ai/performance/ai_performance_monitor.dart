import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/logging/app_logger.dart';

/// Real-time performance metrics for the AI pipeline.
///
/// Consumers:
///  - The pipeline consults `effectiveFps` / `recentLatency` for
///    back-pressure decisions.
///  - The debug overlay (Day 6 widget) reads the public snapshot for
///    the on-screen FPS / latency readout.
///
/// This is intentionally framework-free — it's a pure Dart class
/// driven by the pipeline's `record*` calls.
class AiPerformanceMonitor {
  AiPerformanceMonitor({required this.logger}) {
    _emitTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tick();
    });
  }

  final AppLogger logger;

  // Rolling window of frame timestamps (ms since epoch).
  final List<int> _frameTimestamps = [];
  // Rolling window of inference latency (ms).
  final List<int> _inferenceLatencies = [];

  int _droppedFrames = 0;
  int _totalFrames = 0;
  int _totalInferences = 0;
  int _lastEmitFps = 0;
  int _lastEmitLatency = 0;

  late final Timer _emitTimer;

  /// Call when a frame arrives at the collector.
  void recordFrameArrived() {
    _totalFrames++;
    _frameTimestamps.add(DateTime.now().millisecondsSinceEpoch);
  }

  /// Call when a frame is dropped by the selector due to back-pressure.
  void recordFrameDropped() {
    _droppedFrames++;
  }

  /// Call when an inference completes; [latencyMs] is wall-clock.
  void recordInference(int latencyMs) {
    _totalInferences++;
    _inferenceLatencies.add(latencyMs);
  }

  /// Latest computed FPS (frames received in the last 1s).
  int get currentFps => _lastEmitFps;

  /// Latest computed inference latency (avg of last window).
  int get recentLatency => _lastEmitLatency;

  double get dropRate {
    if (_totalFrames == 0) return 0;
    return _droppedFrames / _totalFrames;
  }

  void _tick() {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Trim to last 1s of frame arrivals.
    _frameTimestamps.removeWhere((t) => now - t > 1000);
    _lastEmitFps = _frameTimestamps.length;

    // Trim to last 30 inferences for latency avg.
    if (_inferenceLatencies.length > 30) {
      _inferenceLatencies.removeRange(
          0, _inferenceLatencies.length - 30);
    }
    if (_inferenceLatencies.isNotEmpty) {
      _lastEmitLatency =
          (_inferenceLatencies.reduce((a, b) => a + b) /
                  _inferenceLatencies.length)
              .round();
    }

    if (kDebugMode) {
      logger.debug('AI perf: fps=$_lastEmitFps '
          'latency=${_lastEmitLatency}ms '
          'drop=${(dropRate * 100).toStringAsFixed(1)}%');
    }
  }

  /// Snapshot for the debug overlay.
  AiPerformanceSnapshot snapshot() => AiPerformanceSnapshot(
        fps: _lastEmitFps,
        latencyMs: _lastEmitLatency,
        dropRate: dropRate,
        totalFrames: _totalFrames,
        totalInferences: _totalInferences,
        droppedFrames: _droppedFrames,
      );

  void dispose() {
    _emitTimer.cancel();
  }
}

@immutable
class AiPerformanceSnapshot {
  const AiPerformanceSnapshot({
    required this.fps,
    required this.latencyMs,
    required this.dropRate,
    required this.totalFrames,
    required this.totalInferences,
    required this.droppedFrames,
  });

  final int fps;
  final int latencyMs;
  final double dropRate;
  final int totalFrames;
  final int totalInferences;
  final int droppedFrames;
}
