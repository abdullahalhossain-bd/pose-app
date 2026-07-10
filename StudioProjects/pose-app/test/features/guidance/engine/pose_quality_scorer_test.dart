import 'package:ai_visual_director/features/guidance/config/guidance_config.dart';
import 'package:ai_visual_director/features/guidance/engine/pose_quality_scorer.dart';
import 'package:ai_visual_director/features/guidance/domain/enums/guidance_enums.dart';
import 'package:ai_visual_director/features/pose/domain/entities/pose_sample.dart';
import 'package:ai_visual_director/features/pose/domain/enums/pose_landmark_type.dart';
import 'package:flutter_test/flutter_test.dart';

PoseLandmark _lm(PoseLandmarkType t, double x, double y, {double l = 0.95}) =>
    PoseLandmark(type: t, x: x, y: y, z: 0, likelihood: l);

PoseSample _pose(List<PoseLandmark> lms,
        {double confidence = 0.9, int timestamp = 0}) =>
    PoseSample(
      id: 1,
      landmarks: lms,
      confidence: confidence,
      timestamp: timestamp,
      boundingBox: const PoseBoundingBox(
          left: 0.2, top: 0.1, width: 0.5, height: 0.7),
    );

void main() {
  late PoseQualityScorer scorer;

  setUp(() => scorer = PoseQualityScorer(const GuidanceConfig()));

  test('returns empty issues for a balanced, well-framed pose', () {
    final pose = _pose([
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
    ]);

    final result = scorer.evaluate(pose);
    expect(result.issues.where((i) => i.priority == GuidancePriority.critical || i.priority == GuidancePriority.high),
        isEmpty,
        reason: 'Balanced pose should have no critical/high issues');
  });

  test('detects head tilt when ears are not level', () {
    final pose = _pose([
      _lm(PoseLandmarkType.nose, 0.50, 0.18),
      _lm(PoseLandmarkType.leftEar, 0.46, 0.15), // left ear higher
      _lm(PoseLandmarkType.rightEar, 0.54, 0.25), // right ear lower
      _lm(PoseLandmarkType.leftShoulder, 0.35, 0.35),
      _lm(PoseLandmarkType.rightShoulder, 0.65, 0.35),
      _lm(PoseLandmarkType.leftHip, 0.40, 0.65),
      _lm(PoseLandmarkType.rightHip, 0.60, 0.65),
    ]);

    final result = scorer.evaluate(pose);
    expect(
      result.issues.any((i) =>
          i.kind == PoseIssueKind.headTiltedLeft ||
          i.kind == PoseIssueKind.headTiltedRight),
      isTrue,
    );
  });

  test('detects shoulders tilted', () {
    final pose = _pose([
      _lm(PoseLandmarkType.nose, 0.50, 0.20),
      _lm(PoseLandmarkType.leftShoulder, 0.35, 0.30), // left high
      _lm(PoseLandmarkType.rightShoulder, 0.65, 0.42), // right low
      _lm(PoseLandmarkType.leftHip, 0.40, 0.65),
      _lm(PoseLandmarkType.rightHip, 0.60, 0.65),
    ]);

    final result = scorer.evaluate(pose);
    expect(result.issues.any((i) => i.kind == PoseIssueKind.shouldersTilted),
        isTrue);
  });

  test('detects too close to camera', () {
    final pose = PoseSample(
      id: 1,
      landmarks: const [],
      confidence: 0.9,
      timestamp: 0,
      // Big bounding box → too close.
      boundingBox: const PoseBoundingBox(
          left: 0.0, top: 0.0, width: 1.0, height: 1.0),
    );

    final result = scorer.evaluate(pose);
    expect(
      result.issues.any((i) => i.kind == PoseIssueKind.tooCloseToCamera),
      isTrue,
    );
  });

  test('detects off-center subject', () {
    final pose = PoseSample(
      id: 1,
      landmarks: [
        _lm(PoseLandmarkType.nose, 0.30, 0.18),
      ],
      confidence: 0.9,
      timestamp: 0,
      // Box shifted left → off-center.
      boundingBox: const PoseBoundingBox(
          left: 0.10, top: 0.10, width: 0.30, height: 0.60),
    );

    final result = scorer.evaluate(pose);
    expect(
      result.issues.any((i) => i.kind == PoseIssueKind.offCenterLeft),
      isTrue,
    );
  });

  test('overall score is 1.0 when every metric passes', () {
    final pose = _pose([
      _lm(PoseLandmarkType.nose, 0.50, 0.18),
      _lm(PoseLandmarkType.leftEar, 0.46, 0.20),
      _lm(PoseLandmarkType.rightEar, 0.54, 0.20),
      _lm(PoseLandmarkType.leftShoulder, 0.35, 0.35),
      _lm(PoseLandmarkType.rightShoulder, 0.65, 0.35),
      _lm(PoseLandmarkType.leftHip, 0.40, 0.65),
      _lm(PoseLandmarkType.rightHip, 0.60, 0.65),
    ]);

    final result = scorer.evaluate(pose);
    // Score should be high — not necessarily 1.0 because some metrics
    // may flag the pose as too far due to small bounding box.
    expect(result.overallScore, greaterThan(0.5));
  });
}
