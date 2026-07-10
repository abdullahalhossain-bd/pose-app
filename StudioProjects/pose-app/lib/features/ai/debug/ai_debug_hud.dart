import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../composition/presentation/providers/composition_providers.dart';
import '../../guidance/presentation/providers/guidance_providers.dart';
import '../../lighting/presentation/providers/lighting_providers.dart';
import '../../pose/presentation/providers/pose_providers.dart';
import '../presentation/providers/ai_providers.dart';
/// On-screen HUD that shows FPS / latency / drop rate + pose metrics +
/// guidance metrics (Day 10). Visible only when `AiConfig.showDebugOverlay`
/// is true.
class AiDebugHud extends ConsumerWidget {
  const AiDebugHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(aiConfigProvider);
    if (!config.showDebugOverlay) return const SizedBox.shrink();

    return Consumer(
      builder: (_, ref, __) {
        final monitor = ref.watch(aiPerformanceMonitorProvider);
        final snap = monitor.snapshot();
        final poses = ref.watch(poseSamplesProvider);
        final poseState = ref.watch(poseStateProvider);
        final guidance = ref.watch(guidanceEvaluationProvider);

        final landmarkCount = poses.isEmpty
            ? 0
            : poses.first.landmarks.where((l) => l.isReliable).length;
        final trackingLabel = switch (poseState.runtimeType.toString()) {
          'PoseTracking' => 'TRK#${(poseState as dynamic).trackId}',
          'PoseReady' => 'RDY#${(poseState as dynamic).trackId}',
          _ => '—',
        };

        return Positioned(
          top: 100,
          right: 12,
          child: IgnorePointer(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _row('FPS', '${snap.fps}'),
                  _row('Lat', '${snap.latencyMs}ms'),
                  _row('Drop', '${(snap.dropRate * 100).toStringAsFixed(1)}%'),
                  _row('LM', '$landmarkCount'),
                  _row('Trk', trackingLabel),
                  if (guidance != null) ...[
                    const _Separator(),
                    _row('Q', '${(guidance.overallScore * 100).round()}%'),
                    _row('Cnf', '${(guidance.evaluationConfidence * 100).round()}%'),
                    _row('Iss', '${guidance.issueCount}'),
                    _row('T', '${(guidance.latencyMicros / 1000).toStringAsFixed(1)}ms'),
                    _row('Rul', guidance.activeRule),
                  ],
                  // Day 12: composition metrics
                  ..._compositionRows(ref),
                  // Day 13: lighting metrics
                  ..._lightingRows(ref),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Text(
          '$k: $v',
          style: const TextStyle(
            color: Colors.greenAccent,
            fontSize: 11,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  List<Widget> _compositionRows(WidgetRef ref) {
    final score = ref.watch(compositionScoreProvider);
    final scene = ref.watch(sceneContextProvider);
    final rec = ref.watch(compositionRecommendationProvider);
    if (score == null) return const [];
    return [
      const _Separator(),
      _row('Comp', '${(score.overallScore * 100).round()}%'),
      if (scene != null) _row('Scn', scene.type.name),
      if (score.horizonAngleDeg != null)
        _row('Hzn', '${score.horizonAngleDeg!.toStringAsFixed(1)}°'),
      if (rec.shortText != null) _row('cRec', rec.shortText!),
    ];
  }

  List<Widget> _lightingRows(WidgetRef ref) {
    final score = ref.watch(lightingScoreProvider);
    final rec = ref.watch(lightingRecommendationProvider);
    if (score == null) return const [];
    return [
      const _Separator(),
      _row('Lit', '${(score.overallScore * 100).round()}%'),
      _row('Exp', score.exposureState.name),
      _row('Lum', score.avgLuminance.round().toString()),
      _row('Dir', score.lightDirection.name),
      _row('Shd', score.shadowStatus.name),
      _row('Tmp', score.colorTemp.name),
      if (rec.shortText != null) _row('lRec', rec.shortText!),
    ];
  }
}

class _Separator extends StatelessWidget {
  const _Separator();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Divider(
          height: 1,
          thickness: 1,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      );
}
