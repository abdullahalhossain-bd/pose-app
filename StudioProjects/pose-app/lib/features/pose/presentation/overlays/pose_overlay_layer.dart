import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../camera/presentation/providers/camera_provider.dart';
import '../../domain/entities/pose_sample.dart';
import '../../domain/entities/pose_state.dart';
import '../../presentation/providers/pose_providers.dart';
import '../../utils/pose_coordinate_mapper.dart';
import 'pose_skeleton_painter.dart';

/// Widget that hosts [PoseSkeletonPainter] on top of the camera
/// preview. Builds a fresh [PoseCoordinateMapper] from the current
/// camera + overlay dimensions so the painter always gets correct
/// screen-space coordinates.
///
/// Collapses to `SizedBox.shrink` when:
/// - Pose state doesn't render a skeleton (Idle / Searching / NoPerson)
/// - There are no tracked samples
class PoseOverlayLayer extends ConsumerWidget {
  const PoseOverlayLayer({super.key, required this.overlaySize});

  final Size overlaySize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(poseStateProvider);
    final poses = ref.watch(poseSamplesProvider);
    final camera = ref.watch(cameraProvider);

    if (!state.rendersSkeleton || poses.isEmpty || !camera.isReady) {
      return const SizedBox.shrink();
    }

    final mapper = PoseCoordinateMapper(
      previewSize: Size(
        camera.controller!.value.previewSize!.height.toDouble(),
        camera.controller!.value.previewSize!.width.toDouble(),
      ),
      overlaySize: overlaySize,
      sensorRotationDegrees:
          camera.controller!.description.sensorOrientation,
      isFrontCamera:
          camera.controller!.description.lensDirection ==
              CameraLensDirection.front,
      fitter: BoxFit.cover,
    );

    return IgnorePointer(
      child: CustomPaint(
        size: overlaySize,
        painter: PoseSkeletonPainter(
          mapper: mapper,
          poses: poses,
        ),
      ),
    );
  }
}

/// Tiny status chip overlay showing the track ID + confidence.
class PoseTrackingIndicator extends ConsumerWidget {
  const PoseTrackingIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(poseStateProvider);
    return switch (state) {
      PoseTracking(:final trackId, :final confidence) => _Chip(
          label: 'Tracking #$trackId · ${(confidence * 100).round()}%',
        ),
      PoseReady(:final trackId, :final confidence) => _Chip(
          label: 'Ready #$trackId · ${(confidence * 100).round()}%',
          color: const Color(0xFF22C55E),
        ),
      PosePersonFound(:final confidence) => _Chip(
          label: 'Person found · ${(confidence * 100).round()}%',
        ),
      PoseLowConfidence(:final confidence) => _Chip(
          label: 'Low confidence · ${(confidence * 100).round()}%',
          color: const Color(0xFFF59E0B),
        ),
      PoseLostTracking() => const _Chip(
          label: 'Reacquiring…',
          color: Color(0xFFF59E0B),
        ),
      PoseNoPerson() => const _Chip(
          label: 'No person in frame',
          color: Color(0xFFEF4444),
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.color = const Color(0xFF3D5AFE)});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
