import 'dart:math' as math;

/// Confidence/framing gate used before counting or scoring a rep.
class LandmarkQuality {
  final bool visible;
  final double confidence;
  final String message;

  const LandmarkQuality({
    required this.visible,
    required this.confidence,
    required this.message,
  });

  bool get acceptable => visible && confidence >= 0.55;

  factory LandmarkQuality.fromPose(dynamic pose) {
    try {
      final landmarks = pose.getVisibleLandmarks(threshold: .55);
      if (landmarks.length < 8) {
        return const LandmarkQuality(
          visible: false,
          confidence: 0,
          message: 'Step back until your whole body is visible.',
        );
      }

      double total = 0;
      var count = 0;
      for (final point in landmarks) {
        try {
          total += (point.confidence as num).toDouble();
          count++;
        } catch (_) {}
      }
      final confidence = count == 0 ? .55 : total / count;
      return LandmarkQuality(
        visible: true,
        confidence: confidence,
        message: confidence >= .75
            ? 'Body detected'
            : 'Good — improve lighting for a clearer read.',
      );
    } catch (_) {
      return const LandmarkQuality(
        visible: false,
        confidence: 0,
        message: 'I cannot see your body clearly yet.',
      );
    }
  }

  static double clamp01(double value) => math.max(0, math.min(1, value));
}
