import 'dart:typed_data';

import '../domain/lighting_reading.dart';
import '../domain/lighting_message.dart';

/// Pure, stateless brightness analysis. No camera or platform-channel
/// dependency — takes raw bytes, returns a reading. This is what makes
/// it unit-testable without a device (see test/lighting_analyzer_test.dart).
///
/// Two entry points because Android and iOS hand the camera plugin
/// different buffer layouts (see camera_service.dart's format choice):
/// - Android (`ImageFormatGroup.nv21`): plane 0 IS luma directly — cheap.
/// - iOS (`ImageFormatGroup.bgra8888`): no dedicated luma plane; each
///   pixel needs a weighted-RGB conversion, so this path is stride-
///   sampled more aggressively to bound cost.
class LightingAnalyzer {
  const LightingAnalyzer();

  /// Android NV21 path: the Y (luma) plane is already brightness data,
  /// one byte per pixel. Sampled at [sampleStride] to avoid reading
  /// every byte of a potentially multi-megapixel frame every time this
  /// runs.
  LightingReading analyzeYPlane(Uint8List yBytes, {int sampleStride = 4}) {
    if (yBytes.isEmpty || sampleStride < 1) return LightingReading.empty;

    int sum = 0;
    int count = 0;
    for (var i = 0; i < yBytes.length; i += sampleStride) {
      sum += yBytes[i];
      count++;
    }
    if (count == 0) return LightingReading.empty;

    return LightingReading(
      averageBrightness: sum / count,
      sampleCount: count,
    );
  }

  /// iOS BGRA8888 path: samples individual pixels at [sampleStride]
  /// pixel intervals (not bytes — a full BGRA pixel is 4 bytes) and
  /// converts each to luma via the standard Rec. 601 weighted formula.
  /// A larger default stride than the Y-plane path because this is
  /// meaningfully more expensive per sample.
  LightingReading analyzeBgra8888(
    Uint8List bytes,
    int width,
    int height,
    int bytesPerRow, {
    int sampleStride = 8,
  }) {
    if (bytes.isEmpty || sampleStride < 1 || width <= 0 || height <= 0) {
      return LightingReading.empty;
    }

    double sum = 0;
    int count = 0;

    for (var y = 0; y < height; y += sampleStride) {
      final rowStart = y * bytesPerRow;
      for (var x = 0; x < width; x += sampleStride) {
        final pixelStart = rowStart + x * 4;
        if (pixelStart + 2 >= bytes.length) continue;
        final b = bytes[pixelStart];
        final g = bytes[pixelStart + 1];
        final r = bytes[pixelStart + 2];
        // Rec. 601 luma weights.
        final luma = 0.299 * r + 0.587 * g + 0.114 * b;
        sum += luma;
        count++;
      }
    }

    if (count == 0) return LightingReading.empty;
    return LightingReading(averageBrightness: sum / count, sampleCount: count);
  }
}

/// Stateful classifier: turns a stream of [LightingReading]s into a
/// single [LightingMessage], with hysteresis so a brightness value
/// hovering near a threshold doesn't flicker the message every frame —
/// same problem, same pattern as GuidanceEngine's debounce logic, kept
/// deliberately separate rather than sharing code, since the two engines
/// reason about completely different signals and forcing a shared base
/// class would couple them for no real benefit.
class LightingEngine {
  LightingEngine({
    this.darkEnterThreshold = 55,
    this.darkClearThreshold = 70,
    this.brightEnterThreshold = 215,
    this.brightClearThreshold = 200,
  });

  final double darkEnterThreshold;
  final double darkClearThreshold;
  final double brightEnterThreshold;
  final double brightClearThreshold;

  LightingCondition _current = LightingCondition.unknown;

  LightingMessage classify(LightingReading reading) {
    if (reading.sampleCount == 0) {
      return LightingMessage.unknown;
    }

    final b = reading.averageBrightness;

    switch (_current) {
      case LightingCondition.tooDark:
        // Already flagged dark — require crossing the (higher) clear
        // threshold before declaring it fixed, not just poking back
        // over the original enter line.
        _current = b > darkClearThreshold
            ? LightingCondition.good
            : LightingCondition.tooDark;
        break;
      case LightingCondition.tooBright:
        _current = b < brightClearThreshold
            ? LightingCondition.good
            : LightingCondition.tooBright;
        break;
      case LightingCondition.good:
      case LightingCondition.unknown:
        if (b < darkEnterThreshold) {
          _current = LightingCondition.tooDark;
        } else if (b > brightEnterThreshold) {
          _current = LightingCondition.tooBright;
        } else {
          _current = LightingCondition.good;
        }
        break;
    }

    switch (_current) {
      case LightingCondition.tooDark:
        return LightingMessage.tooDark;
      case LightingCondition.tooBright:
        return LightingMessage.tooBright;
      case LightingCondition.good:
        return LightingMessage.good;
      case LightingCondition.unknown:
        return LightingMessage.unknown;
    }
  }

  void reset() => _current = LightingCondition.unknown;
}
