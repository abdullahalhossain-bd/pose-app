import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/enums/guidance_enums.dart';

/// Renders the direction arrow for a [GuidanceSignal]. Pure painter.
class GuidanceArrowPainter extends CustomPainter {
  GuidanceArrowPainter({
    required this.direction,
    required this.color,
    this.strokeWidth = 4.0,
  });

  final GuidanceDirection direction;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (direction == GuidanceDirection.none) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) * 0.8;

    final angle = _directionToAngle(direction);
    final end = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, end, paint);

    // Arrowhead
    final unit = (end - center);
    if (unit.distance > 0) {
      final u = unit / unit.distance;
      final perp = Offset(-u.dy, u.dx);
      const headLen = 14.0;
      const headAngle = 0.5;
      final p1 = end - u * headLen + perp * headLen * headAngle;
      final p2 = end - u * headLen - perp * headLen * headAngle;
      final headPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      final path = Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..close();
      canvas.drawPath(path, headPaint);
    }
  }

  double _directionToAngle(GuidanceDirection d) {
    // 0 rad = right, increasing clockwise (since +y is down).
    return switch (d) {
      GuidanceDirection.up => -math.pi / 2,
      GuidanceDirection.down => math.pi / 2,
      GuidanceDirection.left => math.pi,
      GuidanceDirection.right => 0,
      GuidanceDirection.upLeft => -3 * math.pi / 4,
      GuidanceDirection.upRight => -math.pi / 4,
      GuidanceDirection.downLeft => 3 * math.pi / 4,
      GuidanceDirection.downRight => math.pi / 4,
      GuidanceDirection.none => 0,
    };
  }

  @override
  bool shouldRepaint(covariant GuidanceArrowPainter old) =>
      old.direction != direction || old.color != color;
}

/// Renders a target ring at a normalized position — used for "move
/// toward this point" hints.
class GuidanceTargetRingPainter extends CustomPainter {
  GuidanceTargetRingPainter({
    required this.target,
    required this.color,
    this.radius = 24,
    this.strokeWidth = 3,
  });

  final Offset target; // in pixels relative to canvas
  final Color color;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(target, radius, paint);

    // Crosshair
    final crossPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth / 2;
    canvas.drawLine(
      Offset(target.dx - radius / 2, target.dy),
      Offset(target.dx + radius / 2, target.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(target.dx, target.dy - radius / 2),
      Offset(target.dx, target.dy + radius / 2),
      crossPaint,
    );
  }

  @override
  bool shouldRepaint(covariant GuidanceTargetRingPainter old) =>
      old.target != target || old.color != color;
}
