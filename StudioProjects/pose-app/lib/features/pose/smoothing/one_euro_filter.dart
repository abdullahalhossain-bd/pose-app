import 'dart:math' as math;

/// One-Euro filter (Casiez, Roussel, Vogel 2012).
///
/// Adaptive low-pass: at low velocity it filters aggressively (no
/// jitter when the subject is still), at high velocity it barely
/// filters (no lag when the subject moves fast). The standard choice
/// for real-time human pose smoothing.
///
/// Each landmark we want to smooth owns its own [OneEuroFilter]
/// instance because the filter tracks previous-sample state.
class OneEuroFilter {
  OneEuroFilter({
    this.minCutoff = 1.0,
    this.beta = 0.007,
    this.dCutoff = 1.0,
  });

  /// Minimum cutoff frequency. Higher = more smoothing, more lag.
  /// 1.0 Hz is the paper's recommended default for cursor tracking.
  final double minCutoff;

  /// Speed coefficient. Higher = the filter ramps cutoff up faster
  /// when motion accelerates. 0.007–0.03 is the paper's recommended
  /// range for human motion.
  final double beta;

  /// Cutoff for the derivative (velocity) filter. Almost always 1.0.
  final double dCutoff;

  double _xPrev = double.nan;
  double _dxPrev = 0;
  int _tPrevMicros = 0;
  LowPassFilter _xFilt = LowPassFilter(cutoff: 1.0);
  LowPassFilter _dxFilt = LowPassFilter(cutoff: 1.0);

  /// Reset the filter (e.g. when a new track ID is assigned).
  void reset() {
    _xPrev = double.nan;
    _dxPrev = 0;
    _tPrevMicros = 0;
    _xFilt = LowPassFilter(cutoff: 1.0);
    _dxFilt = LowPassFilter(cutoff: 1.0);
  }

  /// Smooths [value] sampled at [tMicros] (microseconds since epoch).
  double filter(double value, int tMicros) {
    if (_xPrev.isNaN) {
      _xPrev = value;
      _tPrevMicros = tMicros;
      return value;
    }

    final dt = ((tMicros - _tPrevMicros) / 1e6).clamp(1e-6, 1.0);
    _tPrevMicros = tMicros;

    // Estimate velocity (filter derivative).
    final dx = (value - _xPrev) / dt;
    _xPrev = value;
    final dCutoffFreq = _alpha(dCutoff, dt);
    final dxSmoothed = _dxFilt.filter(dx, dCutoffFreq);

    // Adaptive cutoff: ramps up with speed.
    final cutoff = minCutoff + beta * dxSmoothed.abs();
    final alpha = _alpha(cutoff, dt);
    return _xFilt.filter(value, alpha);
  }

  double _alpha(double cutoff, double dt) {
    final tau = 1.0 / (2 * math.pi * cutoff);
    final te = dt;
    return 1.0 / (1.0 + tau / te);
  }
}

class LowPassFilter {
  LowPassFilter({required double cutoff}) : _cutoff = cutoff;
  double _cutoff;
  double _yPrev = double.nan;

  double filter(double value, double alpha) {
    if (_yPrev.isNaN) {
      _yPrev = value;
      return value;
    }
    _yPrev = alpha * value + (1 - alpha) * _yPrev;
    return _yPrev;
  }
}
