import 'dart:ui';

import 'package:ai_visual_director/features/pose/utils/pose_coordinate_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PoseCoordinateMapper', () {
    test('identity transform when rotation=0, no front camera, BoxFit.fill', () {
      final m = PoseCoordinateMapper(
        previewSize: const Size(100, 200),
        overlaySize: const Size(100, 200),
        sensorRotationDegrees: 0,
        isFrontCamera: false,
        fitter: BoxFit.fill,
      );
      expect(m.aiToOverlay(const Offset(0.5, 0.5)), const Offset(50, 100));
      expect(m.aiToOverlay(const Offset(0, 0)), const Offset(0, 0));
      expect(m.aiToOverlay(const Offset(1, 1)), const Offset(100, 200));
    });

    test('90° sensor rotation swaps X/Y', () {
      final m = PoseCoordinateMapper(
        previewSize: const Size(100, 200),
        overlaySize: const Size(100, 200),
        sensorRotationDegrees: 90,
        isFrontCamera: false,
        fitter: BoxFit.fill,
      );
      // (x, y) → (y, 1 - x)
      expect(m.aiToOverlay(const Offset(0.25, 0.5)),
          const Offset(100, 75));
    });

    test('front camera mirrors X', () {
      final m = PoseCoordinateMapper(
        previewSize: const Size(100, 200),
        overlaySize: const Size(100, 200),
        sensorRotationDegrees: 0,
        isFrontCamera: true,
        fitter: BoxFit.fill,
      );
      final p = m.aiToOverlay(const Offset(0.2, 0.5));
      // 1 - 0.2 = 0.8 → 0.8 * 100 = 80
      expect(p.dx, 80);
    });

    test('BoxFit.cover scales up to fill overlay', () {
      final m = PoseCoordinateMapper(
        previewSize: const Size(100, 200),
        overlaySize: const Size(400, 400),
        sensorRotationDegrees: 0,
        isFrontCamera: false,
        fitter: BoxFit.cover,
      );
      // Cover of 100x200 into 400x400 — height becomes 800, width 400.
      // Center crop: the box occupies 400x400 centered at 200,200.
      // Point (0.5, 0.5) should map to overlay center.
      final center = m.aiToOverlay(const Offset(0.5, 0.5));
      expect((center.dx - 200).abs(), lessThan(1));
      expect((center.dy - 200).abs(), lessThan(1));
    });
  });
}
