import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/detection.dart';
import '../../state/ai_state.dart';
import '../providers/ai_providers.dart';
import 'ai_overlay_painters.dart';

/// Safe drawing layer — the single widget the camera screen hosts on
/// top of the preview. It composes any active overlays based on the
/// current detections + AI state.
///
/// Why a "safe" layer? Because:
/// 1. It clamps drawing to the preview rect (no overlay ever bleeds
///    outside the camera image).
/// 2. It fades overlays in/out smoothly so transitions don't strobe.
/// 3. It collapses the entire overlay subtree to `SizedBox.shrink`
///    when [AiState.rendersOverlay] is false — zero paint cost.
class AiOverlayLayer extends ConsumerWidget {
  const AiOverlayLayer({
    super.key,
    required this.previewSize,
    this.showBoundingBoxes = true,
    this.showPoseLines = false,
    this.showDirectionArrows = false,
  });

  final Size previewSize;
  final bool showBoundingBoxes;
  final bool showPoseLines;
  final bool showDirectionArrows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiStateProvider);
    final detections = ref.watch(aiDetectionsProvider);

    if (!state.rendersOverlay || detections.isEmpty) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 200),
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (showBoundingBoxes)
                CustomPaint(
                  painter: BoundingBoxPainter(
                    previewSize: previewSize,
                    detections: detections,
                  ),
                ),
              if (showPoseLines)
                CustomPaint(
                  painter: PoseLinePainter(
                    previewSize: previewSize,
                    detections: detections,
                    connections: const [],
                  ),
                ),
              // Feedback labels are positioned widgets, not painters.
              ..._buildLabels(context, detections, state),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLabels(
    BuildContext context,
    List<DetectionResult> detections,
    AiState state,
  ) {
    final feedback = switch (state) {
      AiReady(:final feedback) => feedback,
      AiCaptureReady(:final feedback) => feedback,
      _ => const <AiFeedback>[],
    };

    return feedback.map((f) {
      final left = (f.positionX ?? 0.5) * previewSize.width;
      final top = (f.positionY ?? 0.0) * previewSize.height;
      return Positioned(
        left: left,
        top: top,
        child: FractionalTranslation(
          translation: const Offset(-0.5, -1.2),
          child: _FeedbackChip(feedback: f),
        ),
      );
    }).toList();
  }
}

class _FeedbackChip extends StatelessWidget {
  const _FeedbackChip({required this.feedback});
  final AiFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final color = switch (feedback.severity) {
      AiFeedbackSeverity.info => const Color(0xFF3D5AFE),
      AiFeedbackSeverity.suggestion => const Color(0xFF22C55E),
      AiFeedbackSeverity.warning => const Color(0xFFF59E0B),
      AiFeedbackSeverity.critical => const Color(0xFFEF4444),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        feedback.message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
