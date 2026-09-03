/// A single brightness measurement of a camera frame.
///
/// Deliberately minimal for v1 — just overall average luma. Backlight
/// detection (comparing subject-region brightness to background) is a
/// real, useful next step but needs a reliable subject bounding box and
/// is left for a follow-up slice rather than guessed at now.
class LightingReading {
  /// Mean luma (brightness), 0-255. 0 = black, 255 = fully white/blown out.
  final double averageBrightness;

  /// How many bytes/pixels were actually sampled to compute the average.
  /// Frames are stride-sampled, not read pixel-by-pixel, to bound cost
  /// (spec §20 — never process more than needed). Exposed mainly for
  /// tests to assert sampling actually happened.
  final int sampleCount;

  const LightingReading({
    required this.averageBrightness,
    required this.sampleCount,
  });

  static const LightingReading empty =
      LightingReading(averageBrightness: 0, sampleCount: 0);
}
