import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../../../core/error/failures.dart';
import '../../../ai/domain/entities/ai_frame.dart';
import '../../../ai/domain/entities/detection.dart' show BoundingBox, DetectionResult;
import '../../../ai/domain/repositories/inference_backend.dart';
import '../../../pose/domain/entities/pose_sample.dart';
import '../../../pose/domain/enums/pose_landmark_type.dart';

/// ML Kit-backed implementation of [InferenceBackend] for pose.
///
/// Bridge between our pipeline and ML Kit's `PoseDetector`. Notable
/// choices:
/// - `streamMode: true` — uses temporal smoothing internally + the
///   lower-latency model variant (good for camera preview).
/// - We do NOT enable ML Kit's classification here; Day 10+ adds a
///   dedicated pose-quality classifier on top of landmarks.
///
/// The output is converted to our domain [PoseSample] so the pipeline
/// is fully backend-agnostic.
class MlKitPoseBackend implements InferenceBackend {
  MlKitPoseBackend() {
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.base,
    );
    _detector = PoseDetector(options: options);
  }

  late final PoseDetector _detector;
  bool _initialized = false;

  @override
  String get identifier => 'mlkit-pose';

  /// ML Kit inference runs on its own native executor — no Flutter
  /// isolate needed for the inference call itself.
  @override
  bool get runsOnIsolate => false;

  @override
  Future<Either<Failure, void>> initialize() async {
    // ML Kit lazy-loads on first call; we just flip the flag.
    _initialized = true;
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<DetectionResult>>> infer(AiFrame frame) async {
    if (!_initialized) {
      return Left(UnexpectedFailure(message: 'MlKitPoseBackend not initialized'));
    }

    try {
      final inputImage = _toInputImage(frame);
      if (inputImage == null) {
        return Left(UnexpectedFailure(
            message: 'Could not convert AiFrame to InputImage'));
      }

      final poses = await _detector.processImage(inputImage);
      final samples = <PoseSample>[];
      for (final pose in poses) {
        final landmarks = <PoseLandmark>[];
        double likelihoodSum = 0;
        int likelihoodCount = 0;

        for (final entry in pose.landmarks.entries) {
          final rawType = entry.key;
          final lm = entry.value;
          final type = PoseLandmarkType.fromMlKit(rawType.index);
          landmarks.add(PoseLandmark(
            type: type,
            x: lm.x / frame.width,
            y: lm.y / frame.height,
            z: lm.z,
            likelihood: lm.likelihood,
          ));
          if (lm.likelihood >= 0.5) {
            likelihoodSum += lm.likelihood;
            likelihoodCount++;
          }
        }

        final confidence =
            likelihoodCount == 0 ? 0.0 : likelihoodSum / likelihoodCount;

        // Build a bounding box from reliable landmarks.
        final box = _boundingBox(landmarks);

        samples.add(PoseSample(
          id: -1, // Assigned by PoseTracker downstream.
          landmarks: landmarks,
          confidence: confidence,
          timestamp: frame.timestamp,
          boundingBox: box,
        ));
      }

      // Wrap each PoseSample into a DetectionResult so the existing
      // pipeline still works. We attach the PoseSample via metadata
      // so pose-aware stages / overlays can retrieve it.
      final results = samples
          .map((s) => DetectionResult(
                kind: 'person',
                confidence: s.confidence,
                boundingBox: s.boundingBox == null
                    ? null
                    : BoundingBox(
                        left: s.boundingBox!.left,
                        top: s.boundingBox!.top,
                        width: s.boundingBox!.width,
                        height: s.boundingBox!.height,
                      ),
                label: 'person',
                metadata: {'pose': s},
                timestamp: s.timestamp,
              ))
          .toList();

      return Right(results);
    } catch (e, st) {
      return Left(UnexpectedFailure(
        message: 'ML Kit pose detection failed: $e',
        cause: e,
        stackTrace: st,
      ));
    }
  }

  @override
  Future<void> dispose() async {
    await _detector.close();
    _initialized = false;
  }

  /// Convert our [AiFrame] (YUV420 planes) to ML Kit's [InputImage].
  /// Returns null if the format is not one ML Kit accepts.
  InputImage? _toInputImage(AiFrame frame) {
    if (frame.planes.isEmpty) return null;
    final yPlane = frame.planes.first;

    // Concatenate all planes into a single buffer as ML Kit expects.
    final totalLen = frame.planes.fold<int>(
        0, (sum, p) => sum + p.bytes.length);
    final combined = Uint8List(totalLen);
    int offset = 0;
    for (final p in frame.planes) {
      combined.setRange(offset, offset + p.bytes.length, p.bytes);
      offset += p.bytes.length;
    }

    // Build plane metadata for non-Y planes (ML Kit wants this for
    // chrominance subsampling decisions). The exact API surface
    // varies across plugin versions; we pass what we have and let
    // ML Kit's native side validate.
    return InputImage.fromBytes(
      bytes: combined,
      metadata: InputImageMetadata(
        size: Size(frame.width.toDouble(), frame.height.toDouble()),
        rotation: _mlKitRotation(frame.rotationDegrees),
        format: InputImageFormat.yuv420,
        bytesPerRow: yPlane.width,
      ),
    );
  }

  InputImageRotation _mlKitRotation(int degrees) {
    switch (degrees) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  PoseBoundingBox? _boundingBox(List<PoseLandmark> landmarks) {
    final reliable = landmarks.where((l) => l.isReliable).toList();
    if (reliable.isEmpty) return null;
    double minX = 1, minY = 1, maxX = 0, maxY = 0;
    for (final l in reliable) {
      if (l.x < minX) minX = l.x;
      if (l.y < minY) minY = l.y;
      if (l.x > maxX) maxX = l.x;
      if (l.y > maxY) maxY = l.y;
    }
    return PoseBoundingBox(
      left: minX,
      top: minY,
      width: maxX - minX,
      height: maxY - minY,
    );
  }
}
