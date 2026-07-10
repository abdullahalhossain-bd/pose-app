import 'package:ai_visual_director/features/pose/smoothing/one_euro_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OneEuroFilter', () {
    test('returns input unchanged on first call', () {
      final f = OneEuroFilter();
      final v = f.filter(0.5, 1000);
      expect(v, 0.5);
    });

    test('smooths a noisy signal — output stays within input range', () {
      final f = OneEuroFilter(minCutoff: 1.0, beta: 0.007);
      final input = [0.5, 0.51, 0.49, 0.52, 0.48, 0.5, 0.5, 0.5, 0.5, 0.5];
      final outputs = <double>[];
      for (var i = 0; i < input.length; i++) {
        outputs.add(f.filter(input[i], 1000 + i * 16000));
      }
      // Last few outputs should be very close to the mean (0.5).
      expect((outputs.last - 0.5).abs(), lessThan(0.05));
    });

    test('follows a steady trend without lagging much', () {
      final f = OneEuroFilter(minCutoff: 1.0, beta: 0.05);
      final input = List.generate(30, (i) => 0.1 + i * 0.03);
      final outputs = <double>[];
      for (var i = 0; i < input.length; i++) {
        outputs.add(f.filter(input[i], 1000 + i * 16000));
      }
      // Last output should be close to the last input — the beta ramp
      // should have caught up by then.
      expect((outputs.last - input.last).abs(), lessThan(0.05));
    });

    test('reset clears state — next call behaves like first', () {
      final f = OneEuroFilter();
      f.filter(0.9, 1000);
      f.reset();
      expect(f.filter(0.1, 2000), 0.1);
    });
  });
}
