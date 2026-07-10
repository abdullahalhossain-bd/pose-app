import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/composition_config.dart';

/// ভিজ্যুয়াল গ্রিড ওভারলে সেট আঁকে। প্রতিটি গ্রিড টাইপ একটি পৃথক
/// পেইন্টার — ব্যবহারকারী ক্যামেরা সেটিংসে যেকোনো সমন্বয় টগgle করতে পারেন।
class CompositionGridPainter extends CustomPainter {
  CompositionGridPainter({
    required this.type,
    this.color = const Color(0xFFFFFFFF),
    this.opacity = 0.35,
    this.strokeWidth = 1.0,
    this.horizonAngleDeg,
  });

  final GridOverlayType type;
  final Color color;
  final double opacity;
  final double strokeWidth;

  /// যদি গ্রিড টাইপ [GridOverlayType.horizon] হয় তবে ব্যবহৃত হয়;
  /// সনাক্ত করা হরাইজন অ্যাঙ্গেল আঁকে।
  final double? horizonAngleDeg;

  @override
  void paint(Canvas canvas, Size size) {
    if (type == GridOverlayType.none) return;

    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    switch (type) {
      case GridOverlayType.ruleOfThirds:
        _drawThirds(canvas, size, paint);
        break;
      case GridOverlayType.goldenRatio:
        _drawGoldenRatio(canvas, size, paint);
        break;
      case GridOverlayType.center:
        _drawCenter(canvas, size, paint);
        break;
      case GridOverlayType.horizon:
        _drawHorizon(canvas, size, paint);
        break;
      case GridOverlayType.safeMargins:
        _drawSafeMargins(canvas, size, paint);
        break;
      case GridOverlayType.none:
        break;
    }
  }

  void _drawThirds(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    // উল্লম্ব লাইন
    canvas.drawLine(Offset(w / 3, 0), Offset(w / 3, h), paint);
    canvas.drawLine(Offset(2 * w / 3, 0), Offset(2 * w / 3, h), paint);
    // অনুভূমিক লাইন
    canvas.drawLine(Offset(0, h / 3), Offset(w, h / 3), paint);
    canvas.drawLine(Offset(0, 2 * h / 3), Offset(w, 2 * h / 3), paint);

    // ছেদ বিন্দু হাইলাইট করুন
    final dotPaint = Paint()..color = color.withValues(alpha: opacity * 1.5);
    for (final x in [w / 3, 2 * w / 3]) {
      for (final y in [h / 3, 2 * h / 3]) {
        canvas.drawCircle(Offset(x, y), 4, dotPaint);
      }
    }
  }

  void _drawGoldenRatio(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    final phi = (1 + math.sqrt(5)) / 2;
    final invPhi = 1 / phi; // ≈ 0.618
    // উল্লম্ব গোল্ডেন লাইন
    canvas.drawLine(Offset(w * invPhi, 0), Offset(w * invPhi, h), paint);
    canvas.drawLine(Offset(w * (1 - invPhi), 0), Offset(w * (1 - invPhi), h), paint);
    // অনুভূমিক গোল্ডেন লাইন
    canvas.drawLine(Offset(0, h * invPhi), Offset(w, h * invPhi), paint);
    canvas.drawLine(Offset(0, h * (1 - invPhi)), Offset(w, h * (1 - invPhi)), paint);
  }

  void _drawCenter(Canvas canvas, Size size, Paint paint) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    // ক্রসহেয়ার
    canvas.drawLine(Offset(cx - 20, cy), Offset(cx + 20, cy), paint);
    canvas.drawLine(Offset(cx, cy - 20), Offset(cx, cy + 20), paint);
    // সেন্টার সার্কেল
    canvas.drawCircle(Offset(cx, cy), 12, paint);
  }

  void _drawHorizon(Canvas canvas, Size size, Paint paint) {
    final cy = size.height / 2;
    // একটি কেন্দ্র অনুভূমিক রেফারেন্স লাইন আঁকুন।
    final refPaint = Paint()
      ..color = color.withValues(alpha: opacity * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), refPaint);

    // যদি হরাইজন অ্যাঙ্গেল জানা থাকে তবে কল্পিত নতুন হরাইজন আঁকুন।
    if (horizonAngleDeg != null && horizonAngleDeg!.abs() > 0.1) {
      final angle = horizonAngleDeg! * math.pi / 180;
      final dy = size.width / 2 * math.tan(angle);
      final tiltPaint = Paint()
        ..color = const Color(0xFFFF6B6B).withValues(alpha: opacity * 2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 1.5;
      canvas.drawLine(
        Offset(0, cy - dy),
        Offset(size.width, cy + dy),
        tiltPaint,
      );
    }
  }

  void _drawSafeMargins(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    const margin = 0.08; // 8% প্রান্ত
    final rect = Rect.fromLTWH(
      w * margin,
      h * margin,
      w * (1 - 2 * margin),
      h * (1 - 2 * margin),
    );
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CompositionGridPainter old) =>
      old.type != type ||
      old.horizonAngleDeg != horizonAngleDeg ||
      old.opacity != opacity;
}
