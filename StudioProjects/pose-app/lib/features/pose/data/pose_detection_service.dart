import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show WriteBuffer;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart'
    as mlkit;

import '../domain/pose_landmark_data.dart';

/// Thrown when the underlying detector fails on a frame it did attempt to
/// process (as opposed to a frame that was skipped because a previous
/// one was still in flight — that case returns null, not an exception).
class PoseDetectionException implements Exception {
  final String message;
  const PoseDetectionException(this.message);
  @override
  String toString() => 'PoseDetectionException: $message';
}

/// Wraps Google ML Kit's on-device pose detector.
///
/// This is the ONLY file in the app allowed to import `google_mlkit_*`
/// (spec §17/§19 — AI must remain modular; UI must never depend on AI
/// implementation details). Swapping vendors or adding a lightweight
/// fallback model for low-end devices (spec §21) means editing this file
/// alone.
class PoseDetectionService {
  PoseDetectionService()
      : _detector = mlkit.PoseDetector(
          options: mlkit.PoseDetectorOptions(
            mode: mlkit.PoseDetectionMode.stream,
          ),
        );

  final mlkit.PoseDetector _detector;
  bool _isBusy = false;
  bool _disposed = false;

  static const Map<mlkit.PoseLandmarkType, LandmarkType> _typeMap = {
    mlkit.PoseLandmarkType.nose: LandmarkType.nose,
    mlkit.PoseLandmarkType.leftEye: LandmarkType.leftEye,
    mlkit.PoseLandmarkType.rightEye: LandmarkType.rightEye,
    mlkit.PoseLandmarkType.leftEar: LandmarkType.leftEar,
    mlkit.PoseLandmarkType.rightEar: LandmarkType.rightEar,
    mlkit.PoseLandmarkType.leftShoulder: LandmarkType.leftShoulder,
    mlkit.PoseLandmarkType.rightShoulder: LandmarkType.rightShoulder,
    mlkit.PoseLandmarkType.leftHip: LandmarkType.leftHip,
    mlkit.PoseLandmarkType.rightHip: LandmarkType.rightHip,
    mlkit.PoseLandmarkType.leftKnee: LandmarkType.leftKnee,
    mlkit.PoseLandmarkType.rightKnee: LandmarkType.rightKnee,
    mlkit.PoseLandmarkType.leftAnkle: LandmarkType.leftAnkle,
    mlkit.PoseLandmarkType.rightAnkle: LandmarkType.rightAnkle,
  };

  /// Processes a single camera frame.
  ///
  /// Returns null if a detection is already in flight for a previous
  /// frame — this is the "latest-frame-wins" backpressure strategy: we
  /// never queue frames, we just drop new ones that arrive while busy,
  /// so the detector is always working on recent data and never falls
  /// behind indefinitely (spec §20/§6 of the verification pass).
  ///
  /// Throws [PoseDetectionException] if a frame WAS accepted for
  /// processing but the detector itself failed on it — callers should
  /// treat that as a distinct pipeline error, not "nothing detected".
  Future<PoseFrame?> processFrame(
    CameraImage image,
    int sensorOrientation,
    CameraLensDirection lensDirection,
  ) async {
    if (_isBusy || _disposed) return null;
    _isBusy = true;
    try {
      final inputImage = _toInputImage(image, sensorOrientation, lensDirection);
      if (inputImage == null) return null;

      final poses = await _detector.processImage(inputImage);
      if (_disposed) return null;
      if (poses.isEmpty) return PoseFrame.empty;

      // Single-subject MVP: take the first detected person. Multi-person
      // support (Group Intelligence, spec §7) is a future slice that
      // will change this to return List<PoseFrame>.
      final pose = poses.first;
      final landmarks = <LandmarkType, Landmark>{};
      double totalLikelihood = 0;
      int count = 0;

      // ML Kit returns landmark coordinates in the *unmirrored* sensor
      // image's pixel space, regardless of platform. On the front
      // camera, `CameraPreview` renders a horizontally mirrored view (so
      // the user sees themselves like a mirror) — without correcting
      // for that here, "move left" guidance would point the wrong way
      // whenever the front camera is active. Flip x for the front lens
      // so downstream landmark coordinates match what's on screen.
      //
      // NOTE: this mirroring behavior is based on the documented
      // contract of google_mlkit_pose_detection + the `camera` plugin
      // and has not been confirmed on a physical device in this
      // environment (no Flutter toolchain / hardware available here —
      // see docs/P0_VERIFICATION_REPORT.md). Flag for explicit device
      // QA before shipping.
      final mirrorX = lensDirection == CameraLensDirection.front;

      for (final entry in _typeMap.entries) {
        final lm = pose.landmarks[entry.key];
        if (lm == null) continue;
        final rawX = lm.x / image.width;
        landmarks[entry.value] = Landmark(
          type: entry.value,
          x: mirrorX ? 1 - rawX : rawX,
          y: lm.y / image.height,
          likelihood: lm.likelihood,
        );
        totalLikelihood += lm.likelihood;
        count++;
      }

      final confidence = count == 0 ? 0.0 : totalLikelihood / count;
      return PoseFrame(landmarks: landmarks, confidence: confidence);
    } catch (e) {
      // Detection failures must never crash the camera session (spec
      // §23 — trust over aggressive AI), but they ARE distinct from "no
      // person visible" and the controller needs to know the difference
      // to surface an explicit error state rather than silently doing
      // nothing.
      throw PoseDetectionException(e.toString());
    } finally {
      _isBusy = false;
    }
  }

  mlkit.InputImage? _toInputImage(
    CameraImage image,
    int sensorOrientation,
    CameraLensDirection lensDirection,
  ) {
    final rotation =
        mlkit.InputImageRotationValue.fromRawValue(sensorOrientation) ??
            mlkit.InputImageRotation.rotation0deg;

    final format = mlkit.InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    // Defensive plane concatenation: on Android, ImageFormatGroup.nv21
    // is expected to already deliver a single concatenated plane on
    // current `camera` plugin versions, but this has NOT been verified
    // on-device in this environment. Concatenating all planes when more
    // than one is present is strictly safer than assuming a single
    // plane — it degrades to a no-op copy in the single-plane case and
    // avoids silently feeding ML Kit a truncated buffer (Y-only, no UV)
    // in the multi-plane case, which would produce garbage or a thrown
    // exception deep inside the detector.
    final Uint8List bytes;
    if (image.planes.length == 1) {
      bytes = image.planes.first.bytes;
    } else {
      final buffer = WriteBuffer();
      for (final plane in image.planes) {
        buffer.putUint8List(plane.bytes);
      }
      bytes = buffer.done().buffer.asUint8List();
    }

    return mlkit.InputImage.fromBytes(
      bytes: bytes,
      metadata: mlkit.InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  Future<void> dispose() async {
    _disposed = true;
    await _detector.close();
  }
}
