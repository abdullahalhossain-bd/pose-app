import 'package:flutter/material.dart';

/// Rule-of-thirds grid overlay. Draws 2 vertical + 2 horizontal lines.
class CameraGridOverlay extends StatelessWidget {
  const CameraGridOverlay({super.key, this.opacity = 0.45});
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final color = Colors.white.withValues(alpha: opacity);
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (_, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return Stack(
            children: [
              // Vertical lines (1/3 + 2/3)
              Positioned(
                left: w / 3,
                top: 0,
                bottom: 0,
                child: Container(width: 1, color: color),
              ),
              Positioned(
                left: 2 * w / 3,
                top: 0,
                bottom: 0,
                child: Container(width: 1, color: color),
              ),
              // Horizontal lines
              Positioned(
                top: h / 3,
                left: 0,
                right: 0,
                child: Container(height: 1, color: color),
              ),
              Positioned(
                top: 2 * h / 3,
                left: 0,
                right: 0,
                child: Container(height: 1, color: color),
              ),
            ],
          );
        },
      ),
    );
  }
}
