import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/ai_frame.dart';
import '../../domain/entities/detection.dart';
import '../../domain/repositories/inference_backend.dart';

/// Stub backend used during Day 8 foundation work. Returns no
/// detections but exercises the full pipeline so we can verify
/// performance, state transitions, and overlay plumbing end-to-end.
///
/// Day 9 will register a real backend (TFLite MoveNet) via
/// `inferenceBackendProvider` — the pipeline won't change.
class StubInferenceBackend implements InferenceBackend {
  StubInferenceBackend({this.latencyMs = 30});

  final int latencyMs;
  bool _initialized = false;

  @override
  String get identifier => 'stub';

  @override
  bool get runsOnIsolate => false;

  @override
  Future<Either<Failure, void>> initialize() async {
    await Future<void>.delayed(Duration(milliseconds: latencyMs));
    _initialized = true;
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<DetectionResult>>> infer(AiFrame frame) async {
    if (!_initialized) {
      return Left(UnexpectedFailure(message: 'Backend not initialized'));
    }
    // Simulate compute. No detections returned — Day 9 will fill these.
    await Future<void>.delayed(Duration(milliseconds: latencyMs));
    return const Right([]);
  }

  @override
  Future<void> dispose() async {
    _initialized = false;
  }
}
