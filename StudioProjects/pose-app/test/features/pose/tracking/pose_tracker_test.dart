import 'package:ai_visual_director/features/pose/domain/entities/pose_sample.dart';
import 'package:ai_visual_director/features/pose/tracking/pose_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

PoseSample _pose({
  required int id,
  required double left,
  required double top,
  double confidence = 0.9,
  int timestamp = 0,
}) {
  return PoseSample(
    id: id,
    landmarks: const [],
    confidence: confidence,
    timestamp: timestamp,
    boundingBox: PoseBoundingBox(left: left, top: top, width: 0.2, height: 0.4),
  );
}

void main() {
  group('PoseTracker', () {
    test('first detection gets a new track ID', () {
      final t = PoseTracker();
      final result = t.update([_pose(id: -1, left: 0.2, top: 0.2)]);
      expect(result.length, 1);
      expect(result.first.id, 1);
    });

    test('overlapping detections match the same ID across frames', () {
      final t = PoseTracker();
      final f1 = t.update([_pose(id: -1, left: 0.2, top: 0.2, timestamp: 1)]);
      final f2 = t.update([_pose(id: -1, left: 0.22, top: 0.21, timestamp: 2)]);
      expect(f1.first.id, f2.first.id);
    });

    test('two distinct persons get two distinct IDs', () {
      final t = PoseTracker();
      final f1 = t.update([
        _pose(id: -1, left: 0.1, top: 0.1),
        _pose(id: -1, left: 0.7, top: 0.5),
      ]);
      expect(f1.length, 2);
      expect(f1[0].id, isNot(f1[1].id));
    });

    test('ID survives brief disappearance (coasting)', () {
      final t = PoseTracker(maxCoastFrames: 3);
      final f1 = t.update([_pose(id: -1, left: 0.3, top: 0.3, timestamp: 1)]);
      final originalId = f1.first.id;
      // Missing frame — track coasts.
      t.update([]);
      // Returns with overlapping position — should match same ID.
      final f3 = t.update([_pose(id: -1, left: 0.31, top: 0.3, timestamp: 3)]);
      expect(f3.first.id, originalId);
    });

    test('ID is pruned after maxCoastFrames', () {
      final t = PoseTracker(maxCoastFrames: 1);
      t.update([_pose(id: -1, left: 0.3, top: 0.3, timestamp: 1)]);
      t.update([]);
      t.update([]); // coastFrames = 2 > 1 → pruned
      expect(t.activeIds, isEmpty);
    });

    test('reset clears all tracks', () {
      final t = PoseTracker();
      t.update([_pose(id: -1, left: 0.1, top: 0.1)]);
      t.reset();
      expect(t.activeIds, isEmpty);
      // Next detection starts fresh at ID 1.
      final r = t.update([_pose(id: -1, left: 0.1, top: 0.1)]);
      expect(r.first.id, 1);
    });
  });
}
