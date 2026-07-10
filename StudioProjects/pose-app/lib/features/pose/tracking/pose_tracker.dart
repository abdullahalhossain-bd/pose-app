import 'dart:math' as math;

import '../domain/entities/pose_sample.dart';

/// Assigns stable track IDs to incoming [PoseSample]s using IoU-based
/// matching. Cheap, deterministic, no external state — the tracker
/// keeps a sliding window of last-seen poses per ID.
///
/// Multi-person strategy for MVP: if N poses arrive in one frame,
/// the tracker assigns/maintains an ID for each. Day 11+ will plug in
/// DeepSORT-style appearance embedding for crowded scenes — the
/// [PoseTracker] interface stays the same.
class PoseTracker {
  PoseTracker({
    this.maxCoastFrames = 30,
    this.iouThreshold = 0.3,
    this.maxTrackAgeFrames = 600,
  });

  /// How many frames a lost track is kept alive (coasting) before
  /// being declared lost.
  final int maxCoastFrames;

  /// Minimum IoU to consider two boxes the same person.
  final double iouThreshold;

  /// Hard cap on track lifetime to prevent ID leaks across long gaps.
  final int maxTrackAgeFrames;

  final Map<int, _Track> _tracks = {};
  int _nextId = 1;

  /// Assign IDs to the incoming batch. Returns a new list where each
  /// [PoseSample.id] reflects the assigned track ID.
  List<PoseSample> update(List<PoseSample> detections) {
    // Greedy: sort detections by confidence, match each to its best
    // existing track by IoU. Unmatched detections become new tracks.
    final sorted = List<PoseSample>.from(detections)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));

    final usedTracks = <int>{};
    final assigned = <PoseSample>[];

    for (final det in sorted) {
      final box = det.boundingBox;
      if (box == null) {
        // Without a box we can't match by IoU — give it a new ID.
        assigned.add(_copyWithId(det, _nextId++));
        continue;
      }

      int? bestId;
      double bestIou = iouThreshold;
      for (final entry in _tracks.entries) {
        if (usedTracks.contains(entry.key)) continue;
        final t = entry.value;
        if (t.lastBox == null) continue;
        final score = box.iou(t.lastBox!);
        if (score > bestIou) {
          bestIou = score;
          bestId = entry.key;
        }
      }

      if (bestId != null) {
        usedTracks.add(bestId);
        _tracks[bestId]!.update(det);
        assigned.add(_copyWithId(det, bestId));
      } else {
        final id = _nextId++;
        _tracks[id] = _Track(det);
        assigned.add(_copyWithId(det, id));
      }
    }

    // Age and prune unused tracks.
    _tracks.removeWhere((id, t) {
      if (usedTracks.contains(id)) return false;
      t.coastFrames++;
      return t.coastFrames > maxCoastFrames ||
          t.totalFrames > maxTrackAgeFrames;
    });

    // Increment coast on matched tracks that didn't get a detection
    // this round (multi-person case).
    for (final id in _tracks.keys) {
      if (!usedTracks.contains(id)) {
        _tracks[id]!.coastFrames++;
      }
    }

    return assigned;
  }

  /// Track IDs that are currently "alive" (may be coasting).
  Set<int> get activeIds => _tracks.keys.toSet();

  /// Whether the given track ID is in coast state (lost but recoverable).
  bool isCoasting(int id) =>
      _tracks[id]?.coastFrames != null &&
      _tracks[id]!.coastFrames > 0 &&
      _tracks[id]!.coastFrames <= maxCoastFrames;

  void reset() {
    _tracks.clear();
    _nextId = 1;
  }

  PoseSample _copyWithId(PoseSample src, int id) => PoseSample(
        id: id,
        landmarks: src.landmarks,
        confidence: src.confidence,
        timestamp: src.timestamp,
        boundingBox: src.boundingBox,
      );
}

class _Track {
  _Track(this.firstSample);
  final PoseSample firstSample;
  PoseSample? lastSample;
  PoseBoundingBox? lastBox;
  int coastFrames = 0;
  int totalFrames = 1;

  void update(PoseSample s) {
    lastSample = s;
    lastBox = s.boundingBox;
    coastFrames = 0;
    totalFrames++;
  }
}
