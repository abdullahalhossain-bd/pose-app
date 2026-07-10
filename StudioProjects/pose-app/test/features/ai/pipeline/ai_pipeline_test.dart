import 'package:ai_visual_director/core/error/failures.dart';
import 'package:ai_visual_director/core/logging/logger_adapter.dart';
import 'package:ai_visual_director/features/ai/config/ai_config.dart';
import 'package:ai_visual_director/features/ai/domain/entities/ai_frame.dart';
import 'package:ai_visual_director/features/ai/domain/entities/detection.dart';
import 'package:ai_visual_director/features/ai/domain/repositories/inference_backend.dart';
import 'package:ai_visual_director/features/ai/performance/ai_performance_monitor.dart';
import 'package:ai_visual_director/features/ai/performance/thermal_monitor.dart';
import 'package:ai_visual_director/features/ai/pipeline/ai_pipeline.dart';
import 'package:ai_visual_director/features/ai/state/ai_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _FakeBackend implements InferenceBackend {
  _FakeBackend({this.results = const []});
  List<DetectionResult> results;
  bool initialized = false;

  @override
  String get identifier => 'fake';

  @override
  bool get runsOnIsolate => false;

  @override
  Future<Either<Failure, void>> initialize() async {
    initialized = true;
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<DetectionResult>>> infer(AiFrame frame) async {
    return Right(results);
  }

  @override
  Future<void> dispose() async {
    initialized = false;
  }
}

AiFrame _frame([int id = 0]) => AiFrame(
      id: id,
      width: 100,
      height: 100,
      planes: const [],
      rotationDegrees: 0,
      timestamp: id,
    );

void main() {
  late AiPipeline pipeline;
  late _FakeBackend backend;
  late List<AiState> emittedStates;
  late List<List<DetectionResult>> emittedResults;

  setUp(() {
    backend = _FakeBackend();
    emittedStates = <AiState>[];
    emittedResults = <List<DetectionResult>>[];
    pipeline = AiPipeline(
      backend: backend,
      config: const AiConfig(),
      monitor: AiPerformanceMonitor(logger: LoggerAdapter()),
      thermal: ThermalMonitor(logger: LoggerAdapter()),
      logger: LoggerAdapter(),
      onStateChange: (s) => emittedStates.add(s),
      onResult: (r) => emittedResults.add(r),
    );
  });

  tearDown(() async => pipeline.dispose());

  test('initialize transitions through Preparing → Idle', () async {
    await pipeline.initialize();
    expect(emittedStates.any((s) => s is AiPreparing), isTrue);
    expect(emittedStates.last, isA<AiIdle>());
  });

  test('submit with no detections emits NoSubject', () async {
    await pipeline.initialize();
    emittedStates.clear();
    await pipeline.submit(_frame(1));
    expect(emittedStates.any((s) => s is AiNoSubject), isTrue);
  });

  test('submit with detections emits Ready', () async {
    backend.results = [
      const DetectionResult(
        kind: 'person',
        confidence: 0.9,
        boundingBox: BoundingBox(left: 0.1, top: 0.1, width: 0.4, height: 0.6),
      ),
    ];
    await pipeline.initialize();
    emittedStates.clear();
    await pipeline.submit(_frame(2));
    expect(emittedStates.any((s) => s is AiReady), isTrue);
  });

  test('low-light frame transitions to AiLowLight', () async {
    await pipeline.initialize();
    emittedStates.clear();
    final darkFrame = AiFrame(
      id: 3,
      width: 100,
      height: 100,
      planes: const [],
      rotationDegrees: 0,
      timestamp: 3,
      lux: 10,
    );
    await pipeline.submit(darkFrame);
    expect(emittedStates.any((s) => s is AiLowLight), isTrue);
  });

  test('back-pressure: drops frames while inference is in flight', () async {
    await pipeline.initialize();
    emittedStates.clear();
    // Fire two frames nearly simultaneously — second must be dropped.
    final f1 = _frame(10);
    final f2 = _frame(11);
    await Future.wait([
      pipeline.submit(f1),
      pipeline.submit(f2),
    ]);
    // Pipeline should not have errored.
    expect(emittedStates.any((s) => s is AiError), isFalse);
  });
}
