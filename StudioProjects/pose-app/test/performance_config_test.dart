import 'package:flutter_test/flutter_test.dart';
import 'package:ai_visual_director/features/device/domain/device_tier.dart';
import 'package:ai_visual_director/features/device/domain/performance_config.dart';

void main() {
  group('PerformanceConfig.forTier', () {
    test('low tier still samples pose reasonably often (never unusable)', () {
      final config = PerformanceConfig.forTier(DeviceTier.low);
      expect(config.tier, DeviceTier.low);
      // Spec requirement: never make the app unusable on LOW devices.
      // A sample rate of 5 at a typical 30fps stream is still ~6
      // pose evaluations/sec.
      expect(config.poseFrameSampleRate, lessThanOrEqualTo(5));
    });

    test('medium tier matches the original P0 default (unchanged behavior for the common case)', () {
      final config = PerformanceConfig.forTier(DeviceTier.medium);
      expect(config.poseFrameSampleRate, 3);
      expect(config.lightingFrameSampleRate, 30);
    });

    test('high tier samples pose more frequently than low tier', () {
      final low = PerformanceConfig.forTier(DeviceTier.low);
      final high = PerformanceConfig.forTier(DeviceTier.high);
      expect(high.poseFrameSampleRate, lessThan(low.poseFrameSampleRate));
    });

    test('every tier produces a strictly positive sample rate (no divide-by-zero / infinite-loop risk)', () {
      for (final tier in DeviceTier.values) {
        final config = PerformanceConfig.forTier(tier);
        expect(config.poseFrameSampleRate, greaterThan(0));
        expect(config.lightingFrameSampleRate, greaterThan(0));
      }
    });
  });
}
