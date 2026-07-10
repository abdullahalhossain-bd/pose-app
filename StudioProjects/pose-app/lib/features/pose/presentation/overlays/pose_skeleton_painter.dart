import 'package:flutter/material.dart';

import '../../domain/entities/pose_sample.dart';
import '../../domain/enums/pose_landmark_type.dart';
import '../../utils/pose_coordinate_mapper.dart';

/// Renders the skeleton + joints + tracking indicator for one or
/// more tracked poses. Pure renderer — pulls no state itself; the
/// [PoseOverlayLayer] widget passes the data via constructor.
class PoseSkeletonPainter extends CustomPainter {
  PoseSkeletonPainter({
    required this.mapper,
    required this.poses,
    this.boneColor = const Color(0xFF22C55E),
    this.jointColor = const Color(0xFFFFFFFF),
    this.jointRadius = 5.0,
    this.boneWidth = 3.0,
    this.lowConfidenceOpacity = 0.35,
    this.minLikelihood = 0.5,
  });

  final PoseCoordinateMapper mapper;
  final List<PoseSample> poses;
  final Color boneColor;
  final Color jointColor;
  final double jointRadius;
  final double boneWidth;
  final double lowConfidenceOpacity;
  final double minLikelihood;

  @override
  void paint(Canvas canvas, Size size) {
    if (poses.isEmpty) return;

    final bonePaint = Paint()
      ..color = boneColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = boneWidth
      ..strokeCap = StrokeCap.round;

    final jointPaint = Paint()..color = jointColor;

    for (final pose in poses) {
      final alpha = (pose.confidence.clamp(0.0, 1.0) * 255).round();
      bonePaint.color = boneColor.withValues(alpha: alpha / 255);
      jointPaint.color = jointColor.withValues(alpha: alpha / 255);

      // Bones
      for (final c in PoseSkeleton.connections) {
        final a = pose[c.a];
        final b = pose[c.b];
        if (a == null || b == null) continue;
        if (a.likelihood < minLikelihood || b.likelihood < minLikelihood) {
          continue;
        }
        canvas.drawLine(
          mapper.aiToOverlay(Offset(a.x, a.y)),
          mapper.aiToOverlay(Offset(b.x, b.y)),
          bonePaint,
        );
      }

      // Joints
      for (final lm in pose.landmarks) {
        if (lm.likelihood < minLikelihood) continue;
        canvas.drawCircle(
          mapper.aiToOverlay(Offset(lm.x, lm.y)),
          jointRadius,
          jointPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant PoseSkeletonPainter old) {
    return old.poses != poses || old.mapper != mapper;
  }
}

