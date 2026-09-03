import 'device_tier.dart';

/// Centralized, tier-dependent tuning for everything in the frame
/// processing pipeline (spec: "thresholds/configuration centralized").
/// This is the one place frame-sampling rates live now — previously
/// they were hardcoded constants directly in CameraSessionController.
///
/// Capture resolution is deliberately NOT varied by tier here: capture
/// quality is a user-facing product decision (a low-tier device's user
/// still wants a good photo), whereas these sample rates only affect
/// how often the live *analysis* runs, which is a pure performance
/// lever with no quality trade-off the user would notice as "my photos
/// look worse" — only as "guidance updates less often," which degrades
/// gracefully.
class PerformanceConfig {
  const PerformanceConfig({
    required this.tier,
    required this.poseFrameSampleRate,
    required this.lightingFrameSampleRate,
  });

  final DeviceTier tier;

  /// Run pose detection on every Nth camera frame.
  final int poseFrameSampleRate;

  /// Run lighting analysis on every Nth camera frame.
  final int lightingFrameSampleRate;

  /// Never make the app unusable on LOW devices (explicit spec
  /// requirement) — even the low tier still samples pose every 5th
  /// frame, which at a typical 30fps stream is still ~6 evaluations/sec,
  /// the same rate the original P0 slice shipped with for ALL devices
  /// before tiering existed. Low tier only pulls back lighting sampling
  /// (a lower-value, more expensive-per-sample signal) further.
  factory PerformanceConfig.forTier(DeviceTier tier) {
    switch (tier) {
      case DeviceTier.low:
        return const PerformanceConfig(
          tier: DeviceTier.low,
          poseFrameSampleRate: 5,
          lightingFrameSampleRate: 60,
        );
      case DeviceTier.medium:
        return const PerformanceConfig(
          tier: DeviceTier.medium,
          poseFrameSampleRate: 3,
          lightingFrameSampleRate: 30,
        );
      case DeviceTier.high:
        return const PerformanceConfig(
          tier: DeviceTier.high,
          poseFrameSampleRate: 2,
          lightingFrameSampleRate: 20,
        );
    }
  }
}
