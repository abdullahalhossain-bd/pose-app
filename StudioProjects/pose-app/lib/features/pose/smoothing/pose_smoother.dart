import '../domain/entities/pose_sample.dart'
    show PoseLandmark, PoseLandmarkType;
import '../domain/enums/pose_landmark_type.dart';
import 'one_euro_filter.dart';

/// Smoothes [PoseSample]s across frames using per-landmark One-Euro
/// filters. Reused across frames so the filter keeps state.
///
/// Resets when a new track ID is assigned (otherwise it would smooth
/// across two different people).
class PoseSmoother {
  PoseSmoother({
    double minCutoff = 1.0,
    double beta = 0.007,
  })  : _minCutoff = minCutoff,
        _beta = beta;

  final double _minCutoff;
  final double _beta;

  final Map<PoseLandmarkType, OneEuroFilter> _xFilters = {};
  final Map<PoseLandmarkType, OneEuroFilter> _yFilters = {};
  int _lastTrackId = -1;

  PoseSample smooth(PoseSample input) {
    // New track → reset filter state.
    if (input.id != _lastTrackId) {
      _xFilters.clear();
      _yFilters.clear();
      _lastTrackId = input.id;
    }

    final smoothedLandmarks = <PoseLandmark>[];
    for (final lm in input.landmarks) {
      final xf = _xFilters.putIfAbsent(
          lm.type, () => OneEuroFilter(minCutoff: _minCutoff, beta: _beta));
      final yf = _yFilters.putIfAbsent(
          lm.type, () => OneEuroFilter(minCutoff: _minCutoff, beta: _beta));

      // Only smooth reliable landmarks; pass through noisy ones as-is
      // so the overlay doesn't fake a confident position.
      final sx = lm.isReliable ? xf.filter(lm.x, input.timestamp) : lm.x;
      final sy = lm.isReliable ? yf.filter(lm.y, input.timestamp) : lm.y;

      smoothedLandmarks.add(PoseLandmark(
        type: lm.type,
        x: sx,
        y: sy,
        z: lm.z,
        likelihood: lm.likelihood,
      ));
    }

    return PoseSample(
      id: input.id,
      landmarks: smoothedLandmarks,
      confidence: input.confidence,
      timestamp: input.timestamp,
      boundingBox: input.boundingBox,
    );
  }

  void reset() {
    _xFilters.clear();
    _yFilters.clear();
    _lastTrackId = -1;
  }
}
