import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/lighting_score.dart';
import '../domain/enums/lighting_enums.dart';
import '../presentation/providers/lighting_providers.dart';

/// Composite overlay: exposure meter + light direction indicator +
/// recommendation card + golden hour hint. All `IgnorePointer`.
class LightingOverlayLayer extends ConsumerWidget {
  const LightingOverlayLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(lightingScoreProvider);
    final rec = ref.watch(lightingRecommendationProvider);

    if (score == null) return const SizedBox.shrink();

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Exposure meter (top-right, below auto-capture toggle) ──
          Positioned(
            top: 90,
            right: 16,
            child: _ExposureMeter(score: score),
          ),

          // ── Light direction indicator (bottom-left) ───────────────
          Positioned(
            bottom: 240,
            left: 16,
            child: _LightDirectionIndicator(score: score),
          ),

          // ── Recommendation card (bottom-center, above capture) ────
          if (rec.shortText != null &&
              rec.type != LightingRecommendationType.greatLighting)
            Positioned(
              left: 0,
              right: 0,
              bottom: 280,
              child: Center(
                child: _LightingCard(recommendation: rec),
              ),
            ),

          // ── Golden hour hint (top-center) ──────────────────────────
          if (score.goldenHourActive || score.blueHourActive)
            Positioned(
              top: 56,
              left: 0,
              right: 0,
              child: Center(
                child: _GoldenHourBadge(
                  isGolden: score.goldenHourActive,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExposureMeter extends StatelessWidget {
  const _ExposureMeter({required this.score});
  final LightingScore score;

  @override
  Widget build(BuildContext context) {
    final (color, label) = _exposureStyle(score.exposureState);
    // Map avg luminance (0..255) to a 0..1 meter value.
    final value = (score.avgLuminance / 255).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 60,
            height: 4,
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.white.withOpacity(0.2),
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  (Color, String) _exposureStyle(ExposureState s) => switch (s) {
        ExposureState.balanced =>
          (const Color(0xFF22C55E), 'BAL'),
        ExposureState.underexposed =>
          (const Color(0xFFF59E0B), 'LOW'),
        ExposureState.overexposed =>
          (const Color(0xFFF59E0B), 'HI'),
        ExposureState.severelyUnderexposed =>
          (const Color(0xFFEF4444), 'DARK'),
        ExposureState.severelyOverexposed =>
          (const Color(0xFFEF4444), 'BRIGHT'),
      };
}

class _LightDirectionIndicator extends StatelessWidget {
  const _LightDirectionIndicator({required this.score});
  final LightingScore score;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = _directionStyle(score.lightDirection);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  (IconData, String) _directionStyle(LightSourceDirection d) => switch (d) {
        LightSourceDirection.front => (Icons.wb_sunny, 'Front'),
        LightSourceDirection.back =>
          (Icons.brightness_low, 'Backlit'),
        LightSourceDirection.leftSide =>
          (Icons.arrow_back, 'Left'),
        LightSourceDirection.rightSide =>
          (Icons.arrow_forward, 'Right'),
        LightSourceDirection.overhead =>
          (Icons.arrow_upward, 'Overhead'),
        LightSourceDirection.ambient =>
          (Icons.cloud, 'Diffuse'),
        LightSourceDirection.unknown =>
          (Icons.help_outline, '—'),
      };
}

class _LightingCard extends StatelessWidget {
  const _LightingCard({required this.recommendation});
  final LightingRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(recommendation.priority);
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wb_incandescent, color: color, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              recommendation.shortText ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _priorityColor(LightingPriority p) => switch (p) {
        LightingPriority.critical => const Color(0xFFEF4444),
        LightingPriority.high => const Color(0xFFF59E0B),
        LightingPriority.medium => const Color(0xFF3D5AFE),
        LightingPriority.low => const Color(0xFF6B7280),
        LightingPriority.affirmation => const Color(0xFF22C55E),
      };
}

class _GoldenHourBadge extends StatelessWidget {
  const _GoldenHourBadge({required this.isGolden});
  final bool isGolden;

  @override
  Widget build(BuildContext context) {
    final color = isGolden ? const Color(0xFFF59E0B) : const Color(0xFF60A5FA);
    final label = isGolden ? 'Golden hour' : 'Blue hour';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wb_twilight, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
