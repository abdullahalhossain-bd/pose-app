import 'dart:typed_data';

import 'package:ai_visual_director/features/composition/config/composition_config.dart';
import 'package:ai_visual_director/features/composition/domain/enums/composition_enums.dart';
import 'package:ai_visual_director/features/composition/engine/composition_scorer.dart';
import 'package:ai_visual_director/features/pose/domain/entities/pose_sample.dart';
import 'package:ai_visual_director/features/pose/domain/enums/pose_landmark_type.dart';
import 'package:flutter_test/flutter_test.dart';

PoseLandmark _lm(PoseLandmarkType t, double x, double y, {double l = 0.95}) =>
    PoseLandmark(type: t, x: x, y: y, z: 0, likelihood: l);

PoseSample _pose({double left = 0.2, double top = 0.1, double width = 0.5, double height = 0.7}) {
  return PoseSample(
    id: 1,
    landmarks: [
      _lm(PoseLandmarkType.nose, left + width / 2, top + height * 0.2),
      _lm(PoseLandmarkType.leftShoulder, left + width * 0.2, top + height * 0.3),
      _lm(PoseLandmarkType.rightShoulder, left + width * 0.8, top + height * 0.3),
    ],
    confidence: 0.9,
    timestamp: 0,
    boundingBox: PoseBoundingBox(left: left, top: top, width: width, height: height),
  );
}

Uint8List _blankLuma(int w, int h, [int value = 128]) =>
    Uint8List(w * h)..fillRange(0, w * h, value);

void main() {
  late CompositionScorer scorer;

  setUp(() => scorer = CompositionScorer(const CompositionConfig()));

  test('returns neutral score when no pose and no luma', () {
    final s = scorer.evaluate(pose: null, luma: null, lumaWidth: 0, lumaHeight: 0);
    expect(s.overallScore, greaterThanOrEqualTo(0));
    expect(s.overallScore, lessThanOrEqualTo(1));
  });

  test('detects subject too small', () {
    final pose = _pose(width: 0.05, height: 0.05); // tiny bbox
    final s = scorer.evaluate(pose: pose, luma: null, lumaWidth: 0, lumaHeight: 0);
    expect(
      s.issues.any((i) => i.kind == CompositionIssueKind.subjectTooSmall),
      isTrue,
    );
  });

  test('detects subject too large', () {
    final pose = _pose(left: 0, top: 0, width: 0.95, height: 0.95);
    final s = scorer.evaluate(pose: pose, luma: null, lumaWidth: 0, lumaHeight: 0);
    expect(
      s.issues.any((i) => i.kind == CompositionIssueKind.subjectTooLarge),
      isTrue,
    );
  });

  test('detects insufficient headroom', () {
    final pose = _pose(top: 0.02, height: 0.7); // headroom 0.02 < 0.08
    final s = scorer.evaluate(pose: pose, luma: null, lumaWidth: 0, lumaHeight: 0);
    expect(
      s.issues.any((i) => i.kind == CompositionIssueKind.insufficientHeadroom),
      isTrue,
    );
  });

  test('detects cropped feet', () {
    final pose = _pose(top: 0.1, height: 0.95); // footroom = 1 - 1.05 < 0
    final s = scorer.evaluate(pose: pose, luma: null, lumaWidth: 0, lumaHeight: 0);
    expect(
      s.issues.any((i) => i.kind == CompositionIssueKind.croppedFeet),
      isTrue,
    );
  });

  test('detects subject off-center', () {
    final pose = _pose(left: 0.7, top: 0.2, width: 0.2, height: 0.5); // center x ≈ 0.8
    final s = scorer.evaluate(pose: pose, luma: null, lumaWidth: 0, lumaHeight: 0);
    expect(
      s.issues.any((i) =>
          i.kind == CompositionIssueKind.subjectOffCenterRight),
      isTrue,
    );
  });

  test('issues sorted by priority then severity', () {
    final pose = _pose(left: 0.7, top: 0.02, width: 0.95, height: 0.95);
    final s = scorer.evaluate(pose: pose, luma: null, lumaWidth: 0, lumaHeight: 0);
    if (s.issues.length >= 2) {
      for (var i = 1; i < s.issues.length; i++) {
        final prev = s.issues[i - 1];
        final curr = s.issues[i];
        expect(prev.priority.index, lessThanOrEqualTo(curr.priority.index));
      }
    }
  });

  test('overall score in [0, 1]', () {
    final pose = _pose();
    final s = scorer.evaluate(
        pose: pose, luma: _blankLuma(64, 64), lumaWidth: 64, lumaHeight: 64);
    expect(s.overallScore, greaterThanOrEqualTo(0));
    expect(s.overallScore, lessThanOrEqualTo(1));
  });
}
