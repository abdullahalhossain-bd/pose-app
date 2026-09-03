import 'package:flutter/material.dart';

import '../../../guidance/domain/guidance_message.dart';
import '../../../pose/domain/pose_landmark_data.dart';

/// Draws the AI's real-time visual overlay: a skeleton over the
/// detected pose, a rule-of-thirds composition grid, and a direction
/// arrow when the current guidance is a "move" correction.
///
/// IMPORTANT SCOPING NOTE, consistent with every other "AI overlay"
/// decision in this codebase: the rule-of-thirds grid drawn here is
/// PURELY VISUAL — a compositional reference line, like a real camera's
/// grid overlay setting. It does NOT imply the app is telling the user
/// to position themselves on a third; the actual guidance TEXT still
/// targets dead-center (see GuidanceEngine / CompositionAnalyzer's
/// class docs for why rule-of-thirds *guidance* was deliberately not
/// implemented, to avoid contradicting the centering model). A visual
/// grid and a centering instruction can coexist without contradiction —
/// only a *textual* "move to a third" recommendation would.
///
/// Skeleton connections are a small, deliberately-chosen subset of
/// landmarks — the same ones GuidanceEngine already reasons about
/// (nose, shoulders, hips, ankles) — rather than every ML Kit landmark,
/// to keep the drawing legible rather than a cluttered dot field.
class PoseOverlayPainter extends CustomPainter {
  PoseOverlayPainter({
    required this.pose,
    required this.guidanceCategory,
    required this.showGrid,
  });

  final PoseFrame pose;
  final GuidanceCategory guidanceCategory;
  final bool showGrid;

  static const _skeletonConnections = [
    (LandmarkType.leftShoulder, LandmarkType.rightShoulder),
    (LandmarkType.leftShoulder, LandmarkType.leftHip),
    (LandmarkType.rightShoulder, LandmarkType.rightHip),
    (LandmarkType.leftHip, LandmarkType.rightHip),
    (LandmarkType.leftHip, LandmarkType.leftKnee),
    (LandmarkType.leftKnee, LandmarkType.leftAnkle),
    (LandmarkType.rightHip, LandmarkType.rightKnee),
    (LandmarkType.rightKnee, LandmarkType.rightAnkle),
    (LandmarkType.nose, LandmarkType.leftShoulder),
    (LandmarkType.nose, LandmarkType.rightShoulder),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (showGrid) _paintGrid(canvas, size);
    if (pose.landmarks.isNotEmpty) _paintSkeleton(canvas, size);
    if (guidanceCategory == GuidanceCategory.position) {
      _paintDirectionHint(canvas, size);
    }
  }

  void _paintGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..strokeWidth = 1;

    final thirdW = size.width / 3;
    final thirdH = size.height / 3;

    canvas.drawLine(Offset(thirdW, 0), Offset(thirdW, size.height), paint);
    canvas.drawLine(Offset(thirdW * 2, 0), Offset(thirdW * 2, size.height), paint);
    canvas.drawLine(Offset(0, thirdH), Offset(size.width, thirdH), paint);
    canvas.drawLine(Offset(0, thirdH * 2), Offset(size.width, thirdH * 2), paint);
  }

  void _paintSkeleton(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF5EEAD4).withValues(alpha: 0.85) // AppColors.accent
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()..color = const Color(0xFF5EEAD4);

    Offset? toOffset(LandmarkType type) {
      final lm = pose.get(type);
      // Only draw landmarks ML Kit is reasonably confident about — a
      // skeleton jittering between real and low-confidence guessed
      // points would look broken rather than reassuring.
      if (lm == null || lm.likelihood < 0.5) return null;
      return Offset(lm.x * size.width, lm.y * size.height);
    }

    for (final (a, b) in _skeletonConnections) {
      final pointA = toOffset(a);
      final pointB = toOffset(b);
      if (pointA != null && pointB != null) {
        canvas.drawLine(pointA, pointB, linePaint);
      }
    }

    for (final type in LandmarkType.values) {
      final point = toOffset(type);
      if (point != null) {
        canvas.drawCircle(point, 3.5, dotPaint);
      }
    }
  }

  void _paintDirectionHint(Canvas canvas, Size size) {
    // Framing (closer/further) and shoulder-tilt corrections don't have
    // a natural single-arrow visualization, so this only draws for
    // left/right centering — inferred here directly from the pose's
    // horizontal position, independently of GuidanceEngine's own
    // (debounced, hysteresis-protected) decision. That's a deliberate,
    // lower-stakes duplication: worst case this arrow points slightly
    // wrong for a frame or two while the text guidance (the actual
    // instruction) stays correct and stable — this is a supplementary
    // visual, never the primary guidance channel.
    final leftShoulder = pose.get(LandmarkType.leftShoulder);
    final rightShoulder = pose.get(LandmarkType.rightShoulder);
    final nose = pose.get(LandmarkType.nose);

    double? centerX;
    if (leftShoulder != null && rightShoulder != null) {
      centerX = (leftShoulder.x + rightShoulder.x) / 2;
    } else {
      centerX = nose?.x;
    }
    if (centerX == null) return;

    final offset = centerX - 0.5;
    if (offset.abs() < 0.02) return; // near enough to center, no arrow

    final pointsRight = offset < 0;
    final midY = size.height * 0.45;
    final arrowX = pointsRight ? size.width * 0.85 : size.width * 0.15;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    const arrowSize = 22.0;
    final path = Path();
    if (pointsRight) {
      path.moveTo(arrowX, midY - arrowSize);
      path.lineTo(arrowX + arrowSize, midY);
      path.lineTo(arrowX, midY + arrowSize);
    } else {
      path.moveTo(arrowX, midY - arrowSize);
      path.lineTo(arrowX - arrowSize, midY);
      path.lineTo(arrowX, midY + arrowSize);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant PoseOverlayPainter oldDelegate) {
    return oldDelegate.pose != pose ||
        oldDelegate.guidanceCategory != guidanceCategory ||
        oldDelegate.showGrid != showGrid;
  }
}
