import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/enums/guidance_enums.dart';
import '../presentation/providers/guidance_providers.dart';
import '../overlays/guidance_painters.dart';

/// Composite overlay: status badge + guidance text + arrow + ring.
/// Each sub-widget is independent — only what's needed renders.
///
/// The overlay NEVER blocks the camera preview:
///  - Uses `IgnorePointer` so taps pass through.
///  - Each component is positioned to avoid the center frame area
///    where the subject is.
class GuidanceOverlayLayer extends ConsumerWidget {
  const GuidanceOverlayLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signal = ref.watch(guidanceSignalProvider);
    final config = ref.watch(guidanceConfigProvider);

    // Empty signal — render nothing.
    if (signal.instruction == GuidanceInstructionType.greatPose &&
        signal.confidence == 0) {
      return const SizedBox.shrink();
    }

    final color = _statusColor(signal.status);

    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: 1,
        duration: Duration(milliseconds: config.overlayFadeMs),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Status badge (top-right, color + shape + text) ────
            if (config.showStatusBadge)
              Positioned(
                top: 56,
                right: 16,
                child: _StatusBadge(status: signal.status),
              ),

            // ── Guidance text + arrow (bottom center) ─────────────
            if (signal.shortText != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 160,
                child: Center(
                  child: _GuidanceCard(
                    signal: signal,
                    color: color,
                  ),
                ),
              ),

            // ── Direction arrow at subject position ───────────────
            if (signal.direction != GuidanceDirection.none &&
                signal.hasTarget)
              Positioned(
                left: signal.targetX! * 360,
                top: signal.targetY! * 640,
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: CustomPaint(
                    painter: GuidanceArrowPainter(
                      direction: signal.direction,
                      color: color,
                    ),
                  ),
                ),
              ),

            // ── Confidence meter (subtle, top-center) ─────────────
            if (config.showConfidenceMeter)
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: _ConfidenceMeter(
                    confidence: signal.confidence,
                    color: color,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(GuidanceStatus s) => switch (s) {
        GuidanceStatus.good => const Color(0xFF22C55E),
        GuidanceStatus.improve => const Color(0xFFF59E0B),
        GuidanceStatus.fix => const Color(0xFFEF4444),
      };
}

/// Status badge uses color + shape + letter so it's accessible
/// without color alone.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final GuidanceStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, shape, letter) = switch (status) {
      GuidanceStatus.good => (
          const Color(0xFF22C55E),
          Icons.circle,
          'G',
        ),
      GuidanceStatus.improve => (
          const Color(0xFFF59E0B),
          Icons.change_history,
          'A',
        ),
      GuidanceStatus.fix => (
          const Color(0xFFEF4444),
          Icons.square,
          'R',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(shape, color: color, size: 12),
          const SizedBox(width: 6),
          Text(
            letter,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidanceCard extends StatelessWidget {
  const _GuidanceCard({required this.signal, required this.color});
  final GuidanceSignal signal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (signal.direction != GuidanceDirection.none) ...[
            Icon(_directionIcon(signal.direction), color: color, size: 20),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              signal.shortText ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _directionIcon(GuidanceDirection d) => switch (d) {
        GuidanceDirection.up => Icons.arrow_upward,
        GuidanceDirection.down => Icons.arrow_downward,
        GuidanceDirection.left => Icons.arrow_back,
        GuidanceDirection.right => Icons.arrow_forward,
        GuidanceDirection.upLeft => Icons.arrow_outward,
        GuidanceDirection.upRight => Icons.arrow_outward,
        GuidanceDirection.downLeft => Icons.south_west,
        GuidanceDirection.downRight => Icons.south_east,
        GuidanceDirection.none => Icons.help_outline,
      };
}

class _ConfidenceMeter extends StatelessWidget {
  const _ConfidenceMeter({required this.confidence, required this.color});
  final double confidence;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: confidence.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
