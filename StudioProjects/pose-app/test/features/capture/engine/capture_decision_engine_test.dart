import 'package:ai_visual_director/features/capture/config/capture_config.dart';
import 'package:ai_visual_director/features/capture/domain/enums/capture_enums.dart';
import 'package:ai_visual_director/features/capture/engine/capture_decision_engine.dart';
import 'package:ai_visual_director/features/capture/engine/stability_detector.dart';
import 'package:ai_visual_director/features/guidance/config/guidance_config.dart';
import 'package:ai_visual_director/features/guidance/engine/guidance_engine.dart';
import 'package:ai_visual_director/features/pose/domain/entities/pose_sample.dart';
import 'package:ai_visual_director/features/pose/domain/enums/pose_landmark_type.dart';
import 'package:flutter_test/flutter_test.dart';

PoseLandmark _lm(PoseLandmarkType t, double x, double y, {double l = 0.95}) =>
    PoseLandmark(type: t, x: x, y: y, z: 0, likelihood: l);

PoseSample _goodPose() => PoseSample(
      id: 1,
      landmarks: [
        _lm(PoseLandmarkType.nose, 0.50, 0.18),
        _lm(PoseLandmarkType.leftEar, 0.46, 0.20),
        _lm(PoseLandmarkType.rightEar, 0.54, 0.20),
        _lm(PoseLandmarkType.leftShoulder, 0.35, 0.35),
        _lm(PoseLandmarkType.rightShoulder, 0.65, 0.35),
        _lm(PoseLandmarkType.leftHip, 0.40, 0.65),
        _lm(PoseLandmarkType.rightHip, 0.60, 0.65),
        _lm(PoseLandmarkType.leftElbow, 0.28, 0.50),
        _lm(PoseLandmarkType.rightElbow, 0.72, 0.50),
        _lm(PoseLandmarkType.leftWrist, 0.22, 0.62),
        _lm(PoseLandmarkType.rightWrist, 0.78, 0.62),
        _lm(PoseLandmarkType.leftAnkle, 0.38, 0.92),
        _lm(PoseLandmarkType.rightAnkle, 0.62, 0.92),
      ],
      confidence: 0.95,
      timestamp: DateTime.now().microsecondsSinceEpoch,
      boundingBox: const PoseBoundingBox(
          left: 0.20, top: 0.10, width: 0.50, height: 0.85),
    );

CaptureDecisionEngine _engine({CaptureConfig? config}) {
  final c = config ?? const CaptureConfig();
  return CaptureDecisionEngine(
    config: c,
    stability: StabilityDetector(
      poseDeltaSuppressDeg: c.poseDeltaSuppressDeg,
      cameraMotionSuppressPx: c.cameraMotionSuppressPx,
      windowFrames: c.stabilityWindowFrames,
    ),
    guidanceEngine: GuidanceEngine(const GuidanceConfig()),
  );
}

void main() {
  group('CaptureDecisionEngine', () {
    test('suppressed when no pose', () {
      final e = _engine();
      final s = e.evaluate(
        pose: null,
        quality: null,
        personCount: 0,
        faceVisible: false,
        eyesOpen: false,
        lowLight: false,
        luma: null,
        lumaWidth: 0,
        lumaHeight: 0,
      );
      expect(s.suppressReason, CaptureSuppressReason.userExited);
      expect(s.stableForFrames, 0);
    });

    test('suppressed when multiple people', () {
      final e = _engine();
      final s = e.evaluate(
        pose: _goodPose(),
        quality: null,
        personCount: 2,
        faceVisible: true,
        eyesOpen: true,
        lowLight: false,
        luma: null,
        lumaWidth: 0,
        lumaHeight: 0,
      );
      expect(s.suppressReason, CaptureSuppressReason.multiplePeople);
    });

    test('suppressed when low light + config suppressInLowLight', () {
      final e = _engine();
      final s = e.evaluate(
        pose: _goodPose(),
        quality: null,
        personCount: 1,
        faceVisible: true,
        eyesOpen: true,
        lowLight: true,
        luma: null,
        lumaWidth: 0,
        lumaHeight: 0,
      );
      expect(s.suppressReason, CaptureSuppressReason.lowLight);
    });

    test('does not suppress on low light when config allows it', () {
      final e = _engine(
          config: const CaptureConfig(suppressInLowLight: false));
      final s = e.evaluate(
        pose: _goodPose(),
        quality: null,
        personCount: 1,
        faceVisible: true,
        eyesOpen: true,
        lowLight: true,
        luma: null,
        lumaWidth: 0,
        lumaHeight: 0,
      );
      expect(s.suppressReason, CaptureSuppressReason.none);
    });

    test('score accumulates stable frames when good conditions persist', () {
      final e = _engine();
      CaptureScore? last;
      for (var i = 0; i < 12; i++) {
        last = e.evaluate(
          pose: _goodPose(),
          quality: null,
          personCount: 1,
          faceVisible: true,
          eyesOpen: true,
          lowLight: false,
          luma: null,
          lumaWidth: 0,
          lumaHeight: 0,
        );
      }
      expect(last!.stableForFrames, greaterThan(0));
      expect(last.suppressReason, CaptureSuppressReason.none);
    });

    test('reset clears EMA + stable counter', () {
      final e = _engine();
      for (var i = 0; i < 10; i++) {
        e.evaluate(
          pose: _goodPose(),
          quality: null,
          personCount: 1,
          faceVisible: true,
          eyesOpen: true,
          lowLight: false,
          luma: null,
          lumaWidth: 0,
          lumaHeight: 0,
        );
      }
      e.reset();
      // After reset, the next frame should start fresh — stableForFrames 0 or 1.
      final s = e.evaluate(
        pose: _goodPose(),
        quality: null,
        personCount: 1,
        faceVisible: true,
        eyesOpen: true,
        lowLight: false,
        luma: null,
        lumaWidth: 0,
        lumaHeight: 0,
      );
      expect(s.stableForFrames, lessThanOrEqualTo(1));
    });

    test('factor weights sum to 1.0 (normalized)', () {
      const c = CaptureConfig();
      final sum = c.normalizedWeights.values.fold(0.0, (a, b) => a + b);
      expect(sum, closeTo(1.0, 0.001));
    });

    test('eager preset has lower threshold than conservative', () {
      const eager = CaptureConfig.forSensitivity(CaptureSensitivity.eager);
      const conservative =
          CaptureConfig.forSensitivity(CaptureSensitivity.conservative);
      expect(eager.captureThreshold,
          lessThan(conservative.captureThreshold));
    });
  });
}
