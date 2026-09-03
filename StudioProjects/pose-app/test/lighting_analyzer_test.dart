import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ai_visual_director/features/lighting/application/lighting_analyzer.dart';
import 'package:ai_visual_director/features/lighting/domain/lighting_message.dart';
import 'package:ai_visual_director/features/lighting/domain/lighting_reading.dart';

void main() {
  const analyzer = LightingAnalyzer();

  group('LightingAnalyzer.analyzeYPlane', () {
    test('returns empty for an empty buffer', () {
      final result = analyzer.analyzeYPlane(Uint8List(0));
      expect(result.sampleCount, 0);
    });

    test('computes the correct average for a uniform buffer', () {
      final bytes = Uint8List(100)..fillRange(0, 100, 128);
      final result = analyzer.analyzeYPlane(bytes, sampleStride: 1);
      expect(result.averageBrightness, 128);
      expect(result.sampleCount, 100);
    });

    test('sampleStride actually reduces the number of bytes read', () {
      final bytes = Uint8List(100)..fillRange(0, 100, 200);
      final result = analyzer.analyzeYPlane(bytes, sampleStride: 10);
      expect(result.sampleCount, 10);
    });

    test('correctly averages a non-uniform buffer', () {
      // Half zeros, half 255s, sampled at every byte -> average ~127.5
      final bytes = Uint8List(200);
      for (var i = 100; i < 200; i++) {
        bytes[i] = 255;
      }
      final result = analyzer.analyzeYPlane(bytes, sampleStride: 1);
      expect(result.averageBrightness, closeTo(127.5, 0.01));
    });
  });

  group('LightingAnalyzer.analyzeBgra8888', () {
    test('returns empty for a zero-size image', () {
      final result = analyzer.analyzeBgra8888(Uint8List(0), 0, 0, 0);
      expect(result.sampleCount, 0);
    });

    test('computes correct luma for a solid white image', () {
      // 4x4 image, BGRA, all pixels pure white (255,255,255,255).
      const width = 4;
      const height = 4;
      const bytesPerRow = width * 4;
      final bytes = Uint8List(bytesPerRow * height)..fillRange(0, bytesPerRow * height, 255);

      final result = analyzer.analyzeBgra8888(
        bytes,
        width,
        height,
        bytesPerRow,
        sampleStride: 1,
      );
      expect(result.averageBrightness, closeTo(255, 0.01));
      expect(result.sampleCount, width * height);
    });

    test('computes correct luma for a solid black image', () {
      const width = 4;
      const height = 4;
      const bytesPerRow = width * 4;
      final bytes = Uint8List(bytesPerRow * height);

      final result = analyzer.analyzeBgra8888(
        bytes,
        width,
        height,
        bytesPerRow,
        sampleStride: 1,
      );
      expect(result.averageBrightness, 0);
    });

    test('a pure green image produces the green luma weight (0.587)', () {
      const width = 2;
      const height = 2;
      const bytesPerRow = width * 4;
      final bytes = Uint8List(bytesPerRow * height);
      for (var i = 0; i < bytes.length; i += 4) {
        bytes[i] = 0; // B
        bytes[i + 1] = 255; // G
        bytes[i + 2] = 0; // R
        bytes[i + 3] = 255; // A
      }

      final result = analyzer.analyzeBgra8888(
        bytes,
        width,
        height,
        bytesPerRow,
        sampleStride: 1,
      );
      expect(result.averageBrightness, closeTo(255 * 0.587, 0.5));
    });
  });

  group('LightingEngine hysteresis', () {
    test('classifies a mid-range reading as good', () {
      final engine = LightingEngine();
      final result = engine.classify(const LightingReading(averageBrightness: 130, sampleCount: 100));
      expect(result.condition, LightingCondition.good);
    });

    test('classifies a very dark reading as tooDark', () {
      final engine = LightingEngine();
      final result = engine.classify(const LightingReading(averageBrightness: 20, sampleCount: 100));
      expect(result.condition, LightingCondition.tooDark);
    });

    test('classifies a very bright reading as tooBright', () {
      final engine = LightingEngine();
      final result = engine.classify(const LightingReading(averageBrightness: 240, sampleCount: 100));
      expect(result.condition, LightingCondition.tooBright);
    });

    test('unknown for a reading with zero samples', () {
      final engine = LightingEngine();
      final result = engine.classify(LightingReading.empty);
      expect(result.condition, LightingCondition.unknown);
    });

    test('does not clear tooDark until crossing the higher clear threshold (hysteresis)', () {
      final engine = LightingEngine();
      engine.classify(const LightingReading(averageBrightness: 20, sampleCount: 100));

      // A reading just above the original enter threshold (55) but still
      // below the clear threshold (70) should stay flagged as dark.
      final stillDark = engine.classify(
        const LightingReading(averageBrightness: 60, sampleCount: 100),
      );
      expect(stillDark.condition, LightingCondition.tooDark);

      final cleared = engine.classify(
        const LightingReading(averageBrightness: 75, sampleCount: 100),
      );
      expect(cleared.condition, LightingCondition.good);
    });

    test('reset() clears hysteresis state', () {
      final engine = LightingEngine();
      engine.classify(const LightingReading(averageBrightness: 20, sampleCount: 100));
      engine.reset();

      final result = engine.classify(
        const LightingReading(averageBrightness: 60, sampleCount: 100),
      );
      // Without prior "tooDark" state, 60 is above the enter threshold
      // (55) so it should classify straight to good, not require the
      // higher clear threshold.
      expect(result.condition, LightingCondition.good);
    });
  });
}
