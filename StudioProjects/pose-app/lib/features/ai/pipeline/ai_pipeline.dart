import 'dart:async';
import 'dart:collection';

import 'package:fpdart/fpdart.dart';

import '../../../../core/logging/app_logger.dart';
import '../config/ai_config.dart';
import '../domain/entities/ai_frame.dart';
import '../domain/entities/detection.dart';
import '../domain/repositories/inference_backend.dart';
import '../performance/ai_performance_monitor.dart';
import '../performance/thermal_monitor.dart';
import '../state/ai_state.dart';

/// The end-to-end AI pipeline.
///
/// Stages:
///   Camera → FrameCollector → FrameSelector → Preprocessor
///         → InferenceBackend → DecisionEngine → Overlay emitter
///
/// This class is the orchestrator — it does NOT own any business
/// logic. Each stage is a separate method so they can be tested in
/// isolation.
///
/// Concurrency model:
///  - `submit(frame)` is called from the camera stream listener.
///  - The selector drops frames if the previous inference is still
///    in flight (back-pressure).
///  - Inference runs on the backend's preferred thread (isolate when
///    on-device).
class AiPipeline {
  AiPipeline({
    required this.backend,
    required this.config,
    required this.monitor,
    required this.thermal,
    required this.logger,
    required this.onStateChange,
    required this.onResult,
  });

  final InferenceBackend backend;
  final AiConfig config;
  final AiPerformanceMonitor monitor;
  final ThermalMonitor thermal;
  final AppLogger logger;
  final void Function(AiState) onStateChange;
  final void Function(List<DetectionResult>) onResult;

  final Queue<AiFrame> _queue = Queue<AiFrame>();
  Completer<void>? _processingGate = Completer<void>()..complete();
  bool _initialized = false;
  bool _paused = false;
  int _frameId = 0;
  int _framesSinceLastProcess = 0;
  StreamSubscription<ThermalLevel>? _thermalSub;

  /// Pre-warm the backend. Idempotent.
  Future<void> initialize() async {
    if (_initialized) return;
    onStateChange(const AiPreparing(progress: 0.1));
    final r = await backend.initialize();
    r.fold(
      (f) => onStateChange(AiError(
        kind: AiErrorKind.inferenceFailed,
        message: 'Backend init failed: ${f.message}',
      )),
      (_) {
        _initialized = true;
        onStateChange(const AiIdle());
        _subscribeThermal();
      },
    );
  }

  void _subscribeThermal() {
    _thermalSub = thermal.stream.listen((level) {
      switch (config.thermalPolicy) {
        case ThermalPolicy.ignore:
          break;
        case ThermalPolicy.throttle:
          if (level == ThermalLevel.severe ||
              level == ThermalLevel.critical) {
            _paused = true;
            onStateChange(AiError(
              kind: AiErrorKind.thermalPause,
              message: 'Pausing AI — device is too warm.',
              canRetry: true,
            ));
          } else if (_paused) {
            _paused = false;
            onStateChange(const AiIdle());
          }
        case ThermalPolicy.pause:
          _paused = level != ThermalLevel.nominal;
      }
    });
  }

  /// Entry point — called by the camera frame listener.
  Future<void> submit(AiFrame frame) async {
    if (!_initialized || _paused) return;
    monitor.recordFrameArrived();

    // Frame skipping: drop N frames per processed frame.
    if (_framesSinceLastProcess < config.frameSkip) {
      _framesSinceLastProcess++;
      monitor.recordFrameDropped();
      return;
    }
    _framesSinceLastProcess = 0;

    // Back-pressure: if inference is in flight, drop the new frame.
    if (!_processingGate!.isCompleted) {
      monitor.recordFrameDropped();
      return;
    }

    _processingGate = Completer<void>();
    await _process(frame);
    _processingGate!.complete();
  }

  Future<void> _process(AiFrame frame) async {
    onStateChange(AiDetecting(
        sinceEpoch: DateTime.now().millisecondsSinceEpoch));

    final start = DateTime.now().millisecondsSinceEpoch;
    final preprocessed = _preprocess(frame);
    final result = await backend.infer(preprocessed);

    final latency = DateTime.now().millisecondsSinceEpoch - start;
    monitor.recordInference(latency);

    result.fold(
      (failure) => onStateChange(AiError(
        kind: AiErrorKind.inferenceFailed,
        message: failure.message,
      )),
      (detections) {
        final filtered = _filterByConfidence(detections);
        onResult(filtered);
        onStateChange(_decide(filtered, frame));
      },
    );
  }

  /// Normalize / resize / rotate the frame before passing to the
  /// backend. Day 9 will do real YUV→RGB + resize on the isolate.
  AiFrame _preprocess(AiFrame frame) {
    // Day 8: pass-through. Real preprocessing is added in Day 9 once
    // we wire a real backend.
    return frame;
  }

  /// Drop anything below the configured confidence threshold and
  /// apply NMS via the IoU threshold (naive O(n²) — fine for <=5 dets).
  List<DetectionResult> _filterByConfidence(List<DetectionResult> input) {
    final above = input
        .where((d) => d.confidence >= config.confidenceThreshold)
        .toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));

    final kept = <DetectionResult>[];
    for (final d in above) {
      if (kept.length >= config.maxDetections) break;
      final suppressed = kept.any((k) =>
          _iou(k.boundingBox, d.boundingBox) > config.iouThreshold);
      if (!suppressed) kept.add(d);
    }
    return kept;
  }

  double _iou(BoundingBox? a, BoundingBox? b) {
    if (a == null || b == null) return 0;
    final x1 = a.left > b.left ? a.left : b.left;
    final y1 = a.top > b.top ? a.top : b.top;
    final x2 = a.right < b.right ? a.right : b.right;
    final y2 = a.bottom < b.bottom ? a.bottom : b.bottom;
    final interW = (x2 - x1).clamp(0.0, 1.0);
    final interH = (y2 - y1).clamp(0.0, 1.0);
    final inter = interW * interH;
    final union = a.width * a.height + b.width * b.height - inter;
    return union <= 0 ? 0 : inter / union;
  }

  /// Decide the next [AiState] from the detection set. The decision
  /// engine is intentionally simple for Day 8 — Day 9+ extends it
  /// with pose-quality scoring etc.
  AiState _decide(List<DetectionResult> dets, AiFrame frame) {
    if (frame.lux != null && frame.lux! < config.lowLightLuxThreshold) {
      return AiLowLight(lux: frame.lux!);
    }
    if (dets.isEmpty) return const AiNoSubject();
    // Day 8: always emit "Ready" — Day 9+ plugs pose-quality logic in.
    return AiReady(feedback: _buildFeedback(dets));
  }

  List<AiFeedback> _buildFeedback(List<DetectionResult> dets) {
    // Placeholder feedback — Day 9 fills with pose-quality hints.
    return dets
        .map((d) => AiFeedback(
              id: 'det-${d.kind}',
              message: d.label ?? d.kind,
              severity: AiFeedbackSeverity.info,
              confidence: d.confidence,
              positionX: d.boundingBox?.left,
              positionY: d.boundingBox?.top,
            ))
        .toList();
  }

  /// Pause inference without disposing the backend.
  void pause() {
    _paused = true;
    onStateChange(const AiIdle());
  }

  void resume() {
    _paused = false;
  }

  Future<void> dispose() async {
    _thermalSub?.cancel();
    await backend.dispose();
    monitor.dispose();
  }
}
