import 'package:ai_visual_director/features/ai/config/ai_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiConfig', () {
    test('default is balanced mode', () {
      const c = AiConfig();
      expect(c.performanceMode, AiPerformanceMode.balanced);
      expect(c.targetFps, 15);
      expect(c.processingIntervalMs, 66);
    });

    test('performance mode has higher FPS', () {
      final c = AiConfig.forMode(AiPerformanceMode.performance);
      expect(c.targetFps, greaterThan(15));
      expect(c.inputWidth, greaterThan(256));
    });

    test('battery saver has lower FPS + frame skip', () {
      final c = AiConfig.forMode(AiPerformanceMode.batterySaver);
      expect(c.targetFps, lessThan(15));
      expect(c.frameSkip, greaterThan(0));
    });

    test('copyWith preserves unspecified fields', () {
      const c = AiConfig();
      final updated = c.copyWith(confidenceThreshold: 0.7);
      expect(updated.confidenceThreshold, 0.7);
      expect(updated.targetFps, c.targetFps);
    });
  });
}
