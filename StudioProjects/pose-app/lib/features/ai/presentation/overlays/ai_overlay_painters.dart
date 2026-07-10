import 'package:flutter/material.dart';

import '../../domain/entities/detection.dart';

/// Base class for everything that draws on top of the camera preview.
///
/// Overlays receive the latest [DetectionResult]s and the preview size,
/// and paint whatever they need. They MUST be stateless painters —
/// the AI pipeline owns state; overlays only render.
abstract class AiOverlayPainter extends CustomPainter {
  AiOverlayPainter({
    required this.previewSize,
    required this.detections,
    this.confidenceThreshold = 0.5,
  });

  final Size previewSize;
  final List<DetectionResult> detections;
  final double confidenceThreshold;

  @override
  bool shouldRepaint(covariant AiOverlayPainter old) =>
      old.detections != detections || old.previewSize != previewSize;
}

/// Draws axis-aligned boxes around each detection.
class BoundingBoxPainter extends AiOverlayPainter {
  BoundingBoxPainter({
    required super.previewSize,
    required super.detections,
    super.confidenceThreshold,
    this.color = const Color(0xFF3D5AFE),
    this.strokeWidth = 2.0,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (final d in detections) {
      final b = d.boundingBox;
      if (b == null) continue;
      final rect = Rect.fromLTWH(
        b.left * size.width,
        b.top * size.height,
        b.width * size.width,
        b.height * size.height,
      );
      canvas.drawRect(rect, paint);
    }
  }
}

/// Draws lines connecting keypoints — e.g. a skeleton.
class PoseLinePainter extends AiOverlayPainter {
  PoseLinePainter({
    required super.previewSize,
    required super.detections,
    required this.connections,
    super.confidenceThreshold,
    this.color = const Color(0xFF22C55E),
    this.strokeWidth = 3.0,
    this.pointRadius = 4.0,
  });

  /// Index pairs to connect, e.g. [(5, 7), (7, 9), ...].
  final List<PoseConnection> connections;
  final Color color;
  final double strokeWidth;
  final double pointRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final pointPaint = Paint()..color = color;

    for (final d in detections) {
      if (d.keypoints.isEmpty) continue;
      for (final c in connections) {
        if (c.a >= d.keypoints.length || c.b >= d.keypoints.length) continue;
        final a = d.keypoints[c.a];
        final b = d.keypoints[c.b];
        if (a.confidence < confidenceThreshold ||
            b.confidence < confidenceThreshold) {
          continue;
        }
        canvas.drawLine(
          Offset(a.x * size.width, a.y * size.height),
          Offset(b.x * size.width, b.y * size.height),
          linePaint,
        );
      }
      for (final k in d.keypoints) {
        if (k.confidence < confidenceThreshold) continue;
        canvas.drawCircle(
          Offset(k.x * size.width, k.y * size.height),
          pointRadius,
          pointPaint,
        );
      }
    }
  }
}

/// Draws a directional arrow at a normalized position.
class DirectionArrowPainter extends AiOverlayPainter {
  DirectionArrowPainter({
    required super.previewSize,
    required super.detections,
    required this.from,
    required this.to,
    this.color = const Color(0xFFFF6B6B),
    this.strokeWidth = 4.0,
  });

  final Offset from; // normalized
  final Offset to; // normalized
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final start = Offset(from.dx * size.width, from.dy * size.height);
    final end = Offset(to.dx * size.width, to.dy * size.height);
    canvas.drawLine(start, end, paint);

    // Arrowhead
    final dir = (end - start);
    if (dir.distance > 0) {
      final unit = dir / dir.distance;
      final perp = Offset(-unit.dy, unit.dx);
      const arrowLen = 12.0;
      const arrowAngle = 0.5;
      final p1 = end - unit * arrowLen + perp * arrowLen * arrowAngle;
      final p2 = end - unit * arrowLen - perp * arrowLen * arrowAngle;
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
}
