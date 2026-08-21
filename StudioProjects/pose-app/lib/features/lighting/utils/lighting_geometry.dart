import 'dart:math' as math;
import 'dart:typed_data';

import '../../pose/domain/entities/pose_sample.dart';

/// Pure helpers for luminance + RGB analysis. Stateless, side-effect
/// free — every function trivially unit-testable.
class LightingGeometry {
  const LightingGeometry._();

  /// Build a luminance histogram with [buckets] bins (0..255 mapped).
  /// Samples every [stride]th pixel for speed.
  static List<int> histogram(
    Uint8List? luma,
    int width,
    int height, {
    int buckets = 64,
    int stride = 4,
  }) {
    final hist = List<int>.filled(buckets, 0);
    if (luma == null || width == 0 || height == 0) return hist;
    final bucketSize = 256 / buckets;
    for (var y = 0; y < height; y += stride) {
      for (var x = 0; x < width; x += stride) {
        final idx = y * width + x;
        if (idx >= luma.length) continue;
        final b = (luma[idx] / bucketSize).floor().clamp(0, buckets - 1);
        hist[b]++;
      }
    }
    return hist;
  }

  /// Average luminance over sampled pixels.
  static double averageLuminance(
    Uint8List? luma,
    int width,
    int height, {
    int stride = 4,
  }) {
    if (luma == null || width == 0 || height == 0) return 128;
    double sum = 0;
    int count = 0;
    for (var y = 0; y < height; y += stride) {
      for (var x = 0; x < width; x += stride) {
        final idx = y * width + x;
        if (idx >= luma.length) continue;
        sum += luma[idx];
        count++;
      }
    }
    return count == 0 ? 128 : sum / count;
  }

  /// Percentile of the luminance distribution. [p] in [0..100].
  static double percentile(
    Uint8List? luma,
    int width,
    int height,
    double p, {
    int stride = 4,
  }) {
    if (luma == null || width == 0 || height == 0) return 128;
    // Sample into a list and sort.
    final samples = <int>[];
    for (var y = 0; y < height; y += stride) {
      for (var x = 0; x < width; x += stride) {
        final idx = y * width + x;
        if (idx >= luma.length) continue;
        samples.add(luma[idx]);
      }
    }
    if (samples.isEmpty) return 128;
    samples.sort();
    final idx = (samples.length * p / 100).floor().clamp(0, samples.length - 1);
    return samples[idx].toDouble();
  }

  /// Fraction of pixels above [threshold] — used for highlight clipping.
  static double fractionAbove(Uint8List? luma, int width, int height,
      int threshold, {int stride = 4}) {
    if (luma == null || width == 0 || height == 0) return 0;
    int above = 0;
    int total = 0;
    for (var y = 0; y < height; y += stride) {
      for (var x = 0; x < width; x += stride) {
        final idx = y * width + x;
        if (idx >= luma.length) continue;
        if (luma[idx] > threshold) above++;
        total++;
      }
    }
    return total == 0 ? 0 : above / total;
  }

  /// Fraction of pixels below [threshold] — used for shadow clipping.
  static double fractionBelow(Uint8List? luma, int width, int height,
      int threshold, {int stride = 4}) {
    if (luma == null || width == 0 || height == 0) return 0;
    int below = 0;
    int total = 0;
    for (var y = 0; y < height; y += stride) {
      for (var x = 0; x < width; x += stride) {
        final idx = y * width + x;
        if (idx >= luma.length) continue;
        if (luma[idx] < threshold) below++;
        total++;
      }
    }
    return total == 0 ? 0 : below / total;
  }

  /// Brightness centroid (cx, cy) in normalized [0..1] coordinates.
  /// Used to estimate light direction — the brighter side of the
  /// frame is where the light comes from.
  static ({double cx, double cy}) brightnessCentroid(
    Uint8List? luma,
    int width,
    int height, {
    int stride = 8,
  }) {
    if (luma == null || width == 0 || height == 0) {
      return (cx: 0.5, cy: 0.5);
    }
    double sumX = 0, sumY = 0, sumW = 0;
    for (var y = 0; y < height; y += stride) {
      for (var x = 0; x < width; x += stride) {
        final idx = y * width + x;
        if (idx >= luma.length) continue;
        final w = luma[idx].toDouble();
        sumX += x * w;
        sumY += y * w;
        sumW += w;
      }
    }
    if (sumW == 0) return (cx: 0.5, cy: 0.5);
    return (
      cx: (sumX / sumW) / width,
      cy: (sumY / sumW) / height,
    );
  }

  /// Average luminance inside a normalized bbox region (the subject).
  static double regionAverageLuminance(
    Uint8List? luma,
    int width,
    int height,
    PoseBoundingBox? region, {
    int stride = 2,
  }) {
    if (luma == null || width == 0 || height == 0 || region == null) {
      return 128;
    }
    final x0 = (region.left * width).floor().clamp(0, width - 1);
    final y0 = (region.top * height).floor().clamp(0, height - 1);
    final x1 = (region.right * width).floor().clamp(0, width);
    final y1 = (region.bottom * height).floor().clamp(0, height);
    double sum = 0;
    int count = 0;
    for (var y = y0; y < y1; y += stride) {
      for (var x = x0; x < x1; x += stride) {
        final idx = y * width + x;
        if (idx >= luma.length) continue;
        sum += luma[idx];
        count++;
      }
    }
    return count == 0 ? 128 : sum / count;
  }

  /// Local variance inside a region — proxy for shadow harshness.
  /// High variance + dark patches = harsh shadows.
  static double regionVariance(
    Uint8List? luma,
    int width,
    int height,
    PoseBoundingBox? region, {
    int stride = 2,
  }) {
    if (luma == null || width == 0 || height == 0 || region == null) {
      return 0;
    }
    final x0 = (region.left * width).floor().clamp(0, width - 1);
    final y0 = (region.top * height).floor().clamp(0, height - 1);
    final x1 = (region.right * width).floor().clamp(0, width);
    final y1 = (region.bottom * height).floor().clamp(0, height);

    double sum = 0, sumSq = 0;
    int count = 0;
    for (var y = y0; y < y1; y += stride) {
      for (var x = x0; x < x1; x += stride) {
        final idx = y * width + x;
        if (idx >= luma.length) continue;
        final v = luma[idx].toDouble();
        sum += v;
        sumSq += v * v;
        count++;
      }
    }
    if (count == 0) return 0;
    final mean = sum / count;
    return sumSq / count - mean * mean;
  }

  /// Estimate R/B ratio from YUV planes. ML Kit / camera gives us YUV420,
  /// so we approximate by sampling the U and V planes (chrominance).
  /// Returns 1.0 when no chroma available (neutral).
  ///
  /// Note: this is an approximation — for a true R/B ratio we'd need
  /// full YUV→RGB conversion. Good enough for cool/neutral/warm
  /// categorization.
  static double estimateRBRatio({
    Uint8List? uPlane,
    Uint8List? vPlane,
  }) {
    if (uPlane == null || vPlane == null ||
        uPlane.isEmpty || vPlane.isEmpty) {
      return 1.0;
    }
    // In YUV, V - 128 ≈ R - Y, U - 128 ≈ B - Y.
    // Higher V → more red. Higher U → more blue.
    // R/B ratio proxy: (128 + avgV) / (128 + avgU).
    double sumU = 0, sumV = 0;
    final len = math.min(uPlane.length, vPlane.length);
    final stride = (len / 64).floor().clamp(1, len);
    int count = 0;
    for (var i = 0; i < len; i += stride) {
      sumU += uPlane[i];
      sumV += vPlane[i];
      count++;
    }
    if (count == 0) return 1.0;
    final avgU = sumU / count;
    final avgV = sumV / count;
    // Clamp to avoid div-by-zero.
    final b = 128 + (avgU - 128).abs();
    final r = 128 + (avgV - 128).abs();
    return r / b.clamp(1, 255);
  }
}
