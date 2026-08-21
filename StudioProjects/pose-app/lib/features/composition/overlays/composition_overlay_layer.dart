import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/composition_config.dart' show GridOverlayType;
import '../domain/entities/composition_recommendation.dart';
import '../domain/enums/composition_enums.dart';
import '../domain/enums/scene_type.dart';
import 'composition_grid_painter.dart';
import '../presentation/providers/composition_providers.dart';

/// গ্রিড ওভারলে + রেকমেন্ডেশন কার্ড রেন্ডার করে। উভয়ই আলাদাভাবে টগল করা।
/// IgnorePointer — প্রিভিউতে ট্যাপ ব্লক করে না।
class CompositionOverlayLayer extends ConsumerWidget {
  const CompositionOverlayLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(compositionPrefsProvider);
    final recommendation = ref.watch(compositionRecommendationProvider);
    final score = ref.watch(compositionScoreProvider);

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── গ্রিড ────────────────────────────────────────────────
          if (prefs.enabledGrid != GridOverlayType.none)
            CustomPaint(
              painter: CompositionGridPainter(
                type: prefs.enabledGrid,
                horizonAngleDeg: score?.horizonAngleDeg,
              ),
            ),

          // ── রেকমেন্ডেশন কার্ড (নিচে কেন্দ্র) ───────────────────────
          if (prefs.showCompositionHints &&
              recommendation.shortText != null &&
              recommendation.type !=
                  CompositionRecommendationType.greatComposition)
            Positioned(
              left: 0,
              right: 0,
              bottom: 220,
              child: Center(
                child: _RecommendationCard(recommendation: recommendation),
              ),
            ),

          // ── দৃশ্য ট্যাগ (উপরে-বাম, পোজ ট্র্যাকিং চিপের পাশে) ────────
          if (prefs.showCompositionHints)
            Positioned(
              top: 90,
              left: 16,
              child: const _SceneTag(),
            ),

          // ── হরাইজন সতর্কতা ব্যাজ ────────────────────────────────
          if (score?.horizonAngleDeg != null &&
              score!.horizonAngleDeg!.abs() > 2.5)
            Positioned(
              top: 90,
              right: 16,
              child: _HorizonBadge(angle: score.horizonAngleDeg!),
            ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.recommendation});
  final CompositionRecommendation recommendation;

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
          Icon(Icons.crop_free, color: color, size: 16),
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

  Color _priorityColor(CompositionPriority p) => switch (p) {
        CompositionPriority.critical => const Color(0xFFEF4444),
        CompositionPriority.high => const Color(0xFFF59E0B),
        CompositionPriority.medium => const Color(0xFF3D5AFE),
        CompositionPriority.low => const Color(0xFF6B7280),
        CompositionPriority.affirmation => const Color(0xFF22C55E),
      };
}

class _SceneTag extends ConsumerWidget {
  const _SceneTag();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scene = ref.watch(sceneContextProvider);
    if (scene == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _sceneLabel(scene.type),
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _sceneLabel(SceneType t) => switch (t) {
        SceneType.portrait => 'Portrait',
        SceneType.selfie => 'Selfie',
        SceneType.couple => 'Couple',
        SceneType.group => 'Group',
        SceneType.fullBody => 'Full body',
        SceneType.landscape => 'Landscape',
        SceneType.indoor => 'Indoor',
        SceneType.outdoor => 'Outdoor',
        SceneType.nature => 'Nature',
        SceneType.city => 'City',
        SceneType.unknown => '—',
      };
}

class _HorizonBadge extends StatelessWidget {
  const _HorizonBadge({required this.angle});
  final double angle;

  @override
  Widget build(BuildContext context) {
    final dir = angle > 0 ? '↘' : '↙';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(dir, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            '${angle.abs().toStringAsFixed(1)}°',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
