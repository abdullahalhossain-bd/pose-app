import 'package:ai_visual_director/features/composition/config/composition_config.dart';
import 'package:ai_visual_director/features/composition/domain/enums/scene_type.dart';
import 'package:ai_visual_director/features/composition/engine/scene_classifier.dart';
import 'package:ai_visual_director/features/pose/domain/entities/pose_sample.dart';
import 'package:flutter_test/flutter_test.dart';

PoseSample _pose(double confidence, {double area = 0.3, double height = 0.5}) =>
    PoseSample(
      id: 1,
      landmarks: const [],
      confidence: confidence,
      timestamp: 0,
      boundingBox: PoseBoundingBox(left: 0.3, top: 0.2, width: area, height: height),
    );

void main() {
  late SceneClassifier classifier;

  setUp(() =>
      classifier = SceneClassifier(const CompositionConfig()));

  test('no people → landscape (low confidence)', () {
    final s = classifier.classify(poses: [], isFrontCamera: false);
    expect(s.type, SceneType.landscape);
    expect(s.confidence, lessThan(0.6));
  });

  test('1 person + front camera + large frame → selfie', () {
    final s = classifier.classify(
      poses: [_pose(0.9, area: 0.55)],
      isFrontCamera: true,
    );
    expect(s.type, SceneType.selfie);
    expect(s.confidence, greaterThan(0.8));
  });

  test('1 person + back camera + large frame → portrait', () {
    final s = classifier.classify(
      poses: [_pose(0.9, area: 0.55)],
      isFrontCamera: false,
    );
    expect(s.type, SceneType.portrait);
  });

  test('1 person + tall bbox → fullBody', () {
    final s = classifier.classify(
      poses: [_pose(0.9, area: 0.2, height: 0.85)],
      isFrontCamera: false,
    );
    expect(s.type, SceneType.fullBody);
  });

  test('2 persons close together → couple', () {
    final p1 = _pose(0.9, area: 0.2);
    final p2 = PoseSample(
      id: 2,
      landmarks: const [],
      confidence: 0.9,
      timestamp: 0,
      boundingBox: const PoseBoundingBox(left: 0.45, top: 0.2, width: 0.2, height: 0.5),
    );
    final s = classifier.classify(poses: [p1, p2], isFrontCamera: false);
    // Centers at 0.4 and 0.55 → dist 0.15 < 0.30 → couple
    expect(s.type, SceneType.couple);
  });

  test('3+ persons → group', () {
    final p1 = _pose(0.9);
    final p2 = _pose(0.85);
    final p3 = _pose(0.8);
    final s = classifier.classify(poses: [p1, p2, p3], isFrontCamera: false);
    expect(s.type, SceneType.group);
  });

  test('prioritizesFace for portrait/selfie/couple', () {
    expect(
      classifier
          .classify(poses: [_pose(0.9, area: 0.55)], isFrontCamera: false)
          .prioritizesFace,
      isTrue,
    );
  });

  test('prioritizesHorizon for landscape', () {
    final s = classifier.classify(poses: [], isFrontCamera: false);
    expect(s.prioritizesHorizon, isTrue);
  });
}
