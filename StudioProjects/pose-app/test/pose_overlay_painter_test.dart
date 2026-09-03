import 'package:flutter_test/flutter_test.dart';
import 'package:ai_visual_director/features/camera/presentation/widgets/pose_overlay_painter.dart';
import 'package:ai_visual_director/features/guidance/domain/guidance_message.dart';
import 'package:ai_visual_director/features/pose/domain/pose_landmark_data.dart';

void main() {
  group('PoseOverlayPainter.shouldRepaint', () {
    test('does not repaint when nothing changed', () {
      final a = PoseOverlayPainter(
        pose: PoseFrame.empty,
        guidanceCategory: GuidanceCategory.none,
        showGrid: true,
      );
      final b = PoseOverlayPainter(
        pose: PoseFrame.empty,
        guidanceCategory: GuidanceCategory.none,
        showGrid: true,
      );
      expect(a.shouldRepaint(b), false);
    });

    test('repaints when the pose changes', () {
      final a = PoseOverlayPainter(
        pose: PoseFrame.empty,
        guidanceCategory: GuidanceCategory.none,
        showGrid: true,
      );
      final b = PoseOverlayPainter(
        pose: const PoseFrame(landmarks: {}, confidence: 0.5),
        guidanceCategory: GuidanceCategory.none,
        showGrid: true,
      );
      expect(a.shouldRepaint(b), true);
    });

    test('repaints when the guidance category changes', () {
      final a = PoseOverlayPainter(
        pose: PoseFrame.empty,
        guidanceCategory: GuidanceCategory.none,
        showGrid: true,
      );
      final b = PoseOverlayPainter(
        pose: PoseFrame.empty,
        guidanceCategory: GuidanceCategory.position,
        showGrid: true,
      );
      expect(a.shouldRepaint(b), true);
    });

    test('repaints when the grid visibility toggles', () {
      final a = PoseOverlayPainter(
        pose: PoseFrame.empty,
        guidanceCategory: GuidanceCategory.none,
        showGrid: true,
      );
      final b = PoseOverlayPainter(
        pose: PoseFrame.empty,
        guidanceCategory: GuidanceCategory.none,
        showGrid: false,
      );
      expect(a.shouldRepaint(b), true);
    });
  });
}
