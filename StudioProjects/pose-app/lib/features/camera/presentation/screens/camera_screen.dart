import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../ai/debug/ai_debug_hud.dart';
import '../../../ai/presentation/overlays/ai_overlay_layer.dart';
import '../../../ai/presentation/providers/ai_providers.dart';
import '../../../ai/presentation/widgets/ai_status_banner.dart';
import '../../../capture/domain/entities/capture_attempt.dart';
import '../../../capture/domain/entities/capture_score.dart';
import '../../../capture/domain/enums/capture_enums.dart';
import '../../../capture/presentation/overlays/capture_overlay_layer.dart';
import '../../../capture/presentation/providers/capture_providers.dart';
import '../../../composition/overlays/composition_overlay_layer.dart';
import '../../../composition/presentation/providers/composition_providers.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../guidance/overlays/guidance_overlay_layer.dart';
import '../../../lighting/overlays/lighting_overlay_layer.dart';
import '../../../lighting/presentation/providers/lighting_providers.dart';
import '../../../pose/presentation/overlays/pose_overlay_layer.dart';
import '../../../../shared/widgets/widgets.dart';
import '../providers/camera_provider.dart';
import '../widgets/camera_grid_overlay.dart';

/// Full-screen camera capture UI.
///
/// Performance: rebuilds are scoped to the [CameraController] listener.
/// The controls row is a separate [Consumer] so toggling the grid does
/// not re-render the preview.
class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cameraProvider.notifier).init();
      // Subscribe to capture state transitions (fires the shutter).
      ref.listenManual(captureStateProvider, (prev, next) async {
        if (next is CaptureCapturing) {
          final score = ref.read(captureScoreProvider);
          final path = await ref.read(cameraProvider.notifier).capture();
          if (!mounted) return;
          if (path == null) {
            ref.read(captureStateProvider.notifier).onCaptureFailure(
              CaptureFailureReason.encoderError,
            );
          } else {
            final effectiveScore = score ??
                CaptureScore(
                  factors: const <FactorScore>[],
                  overall: 0.8,
                  suppressReason: CaptureSuppressReason.none,
                  stableForFrames: 0,
                  timestamp: 0,
                );
            ref.read(captureStateProvider.notifier).onCaptureSuccess(
              imagePath: path,
              score: effectiveScore,
            );
          }
        }
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifier = ref.read(cameraProvider.notifier);
    if (state == AppLifecycleState.inactive) {
      notifier.dispose();
    } else if (state == AppLifecycleState.resumed) {
      notifier.init();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cam = ref.watch(cameraProvider);

    if (!cam.hasPermission) {
      return _PermissionDeniedView(state: cam);
    }
    if (cam.error != null) {
      return AppErrorState(
        title: 'Camera error',
        description: cam.error,
        onRetry: () => ref.read(cameraProvider.notifier).init(),
      );
    }
    if (!cam.isReady) {
      return const AppLoadingIndicator(label: 'Starting camera…');
    }

    final controller = cam.controller!;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Preview ───────────────────────────────────────────────
            ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.previewSize!.height,
                  height: controller.value.previewSize!.width,
                  child: CameraPreview(controller),
                ),
              ),
            ),

            // ── Grid overlay ──────────────────────────────────────────
            if (cam.showGrid) const CameraGridOverlay(),

            // ── AI overlay layer ─────────────────────────────────────
            // Renders bounding boxes, pose lines, and feedback chips.
            // Auto-collapses to SizedBox.shrink when there are no
            // detections or the AI state doesn't render overlays —
            // zero paint cost when idle.
            Positioned.fill(
              child: AiOverlayLayer(
                previewSize: Size(
                  controller.value.previewSize!.height,
                  controller.value.previewSize!.width,
                ),
              ),
            ),

            // ── Pose skeleton overlay (Day 9) ────────────────────────
            // Renders bones + joints using the PoseCoordinateMapper.
            // Collapses to SizedBox.shrink when no pose is tracked.
            Positioned.fill(
              child: LayoutBuilder(
                builder: (_, constraints) => PoseOverlayLayer(
                  overlaySize:
                  Size(constraints.maxWidth, constraints.maxHeight),
                ),
              ),
            ),

            // ── Pose tracking indicator (top-left chip) ──────────────
            Positioned(
              top: 56,
              left: 16,
              child: const PoseTrackingIndicator(),
            ),

            // ── Guidance overlay (Day 10) ────────────────────────────
            // Renders direction arrow + status badge + guidance text +
            // confidence meter. Auto-collapses when no signal.
            const Positioned.fill(child: GuidanceOverlayLayer()),

            // ── Composition overlay (Day 12) ─────────────────────────
            // Grid (rule-of-thirds / golden / center / horizon / safe)
            // + recommendation card + scene tag + horizon badge.
            const Positioned.fill(child: CompositionOverlayLayer()),

            // ── Lighting overlay (Day 13) ────────────────────────────
            // Exposure meter + light direction indicator + recommendation
            // card + golden hour badge. Auto-collapses when no signal.
            const Positioned.fill(child: LightingOverlayLayer()),

            // ── Capture overlay (Day 11) ─────────────────────────────
            // Countdown ring + result card + suppressed banner.
            // Auto-collapses when no capture is in flight.
            const Positioned.fill(child: CaptureOverlayLayer()),

            // ── AI status banner ─────────────────────────────────────
            const Positioned.fill(child: AiStatusBanner()),

            // ── AI debug HUD (only when config.showDebugOverlay) ─────
            const AiDebugHud(),

            // ── Auto-capture toggle (top-right chip) ─────────────────
            const Positioned(
              top: 56,
              right: 16,
              child: _AutoCaptureToggle(),
            ),

            // ── Top bar ──────────────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  _FlashToggle(state: cam),
                  IconButton(
                    icon: Icon(
                      cam.showGrid ? Icons.grid_on : Icons.grid_off,
                      color: Colors.white,
                    ),
                    onPressed: () =>
                        ref.read(cameraProvider.notifier).toggleGrid(),
                  ),
                ],
              ),
            ),

            // ── Bottom controls ──────────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomControls(state: cam),
            ),

            // ── Zoom indicator ───────────────────────────────────────
            if (cam.zoom > 1.0)
              Positioned(
                right: 16,
                top: 80,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${cam.zoom.toStringAsFixed(1)}x',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PermissionDeniedView extends StatelessWidget {
  const _PermissionDeniedView({required this.state});
  final CameraState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AppErrorState(
          icon: Icons.camera_alt_outlined,
          title: 'Camera permission needed',
          description:
          'AI Visual Director needs camera access to guide your shots. '
              'Tap below to open Settings and grant access.',
          onRetry: () => openAppSettings(),
        ),
      ),
    );
  }
}

class _FlashToggle extends ConsumerWidget {
  const _FlashToggle({required this.state});
  final CameraState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icon = switch (state.flashMode) {
      FlashMode.off => Icons.flash_off,
      FlashMode.auto => Icons.flash_auto,
      FlashMode.always => Icons.flash_on,
      FlashMode.torch => Icons.highlight,
    };
    return IconButton(
      icon: Icon(icon, color: Colors.white),
      onPressed: () => ref.read(cameraProvider.notifier).cycleFlash(),
    );
  }
}

class _BottomControls extends ConsumerWidget {
  const _BottomControls({required this.state});
  final CameraState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom slider
          Row(
            children: [
              const Icon(Icons.zoom_out, color: Colors.white, size: 18),
              Expanded(
                child: Slider(
                  value: state.zoom,
                  min: 1.0,
                  max: 8.0,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white38,
                  onChanged: (v) =>
                      ref.read(cameraProvider.notifier).setZoom(v),
                ),
              ),
              const Icon(Icons.zoom_in, color: Colors.white, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Gallery shortcut
              GestureDetector(
                onTap: () => _openGallery(context),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white54, width: 1.5),
                  ),
                  child: const Icon(Icons.photo_outlined, color: Colors.white),
                ),
              ),
              // Shutter
              GestureDetector(
                onTap: state.isCapturing
                    ? null
                    : () async {
                  final path = await ref
                      .read(cameraProvider.notifier)
                      .capture();
                  if (path != null && context.mounted) {
                    showAppSnack(context, 'Captured', kind: AppSnackKind.success);
                  }
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  alignment: Alignment.center,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: state.isCapturing ? 56 : 66,
                    height: state.isCapturing ? 56 : 66,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              // Flip
              IconButton(
                icon: const Icon(Icons.cameraswitch, color: Colors.white),
                iconSize: 32,
                onPressed: () => ref.read(cameraProvider.notifier).flip(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openGallery(BuildContext context) {
    // Day 8+ will plug into a real gallery picker via photo_manager.
    showAppSnack(context, 'Gallery picker coming in v0.2',
        kind: AppSnackKind.info);
  }
}

/// Day 11: Auto-capture toggle chip. Lets the user enable/disable
/// smart capture directly from the camera screen.
class _AutoCaptureToggle extends ConsumerWidget {
  const _AutoCaptureToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(capturePrefsProvider.select((p) => p.autoCaptureEnabled));
    return GestureDetector(
      onTap: () => ref.read(capturePrefsProvider.notifier).toggleAutoCapture(!enabled),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: enabled ? const Color(0xFF22C55E) : Colors.white54,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              enabled ? Icons.auto_awesome : Icons.auto_awesome_outlined,
              size: 14,
              color: enabled ? const Color(0xFF22C55E) : Colors.white70,
            ),
            const SizedBox(width: 6),
            Text(
              enabled ? 'Auto' : 'Manual',
              style: TextStyle(
                color: enabled ? const Color(0xFF22C55E) : Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}