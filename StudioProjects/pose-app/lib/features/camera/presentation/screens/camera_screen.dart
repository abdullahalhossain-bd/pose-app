import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../capture/domain/auto_capture_state.dart';
import '../../../gallery/presentation/screens/gallery_screen.dart';
import '../../../guidance/domain/guidance_message.dart';
import '../../application/camera_session_controller.dart';
import '../../domain/camera_state.dart';
import '../widgets/capture_button.dart';
import '../widgets/guidance_overlay.dart';
import '../widgets/permission_request_view.dart';
import '../widgets/pose_overlay_painter.dart';

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
    // Kick off permission + camera + pose pipeline once the first frame
    // is laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cameraSessionProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Camera lifecycle correctness (spec §5): release the camera when
    // backgrounded, reinitialize on resume, so we don't hold the sensor
    // open (battery/thermal) or crash on some OEM devices.
    //
    // IMPORTANT: this must call pauseSession()/resumeSession(), never
    // the notifier's dispose()/initialize() directly — dispose() on a
    // StateNotifier is terminal (see CameraSessionController's class
    // doc). The earlier version of this code called
    // `.notifier.dispose()` here, which meant the first
    // background→foreground cycle crashed the app: resume tried to set
    // state on an already-disposed notifier. Fixed during the P0
    // hardening pass — see docs/P0_VERIFICATION_REPORT.md.
    final controller = ref.read(cameraSessionProvider).controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      ref.read(cameraSessionProvider.notifier).pauseSession();
    } else if (state == AppLifecycleState.resumed) {
      ref.read(cameraSessionProvider.notifier).resumeSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only rebuild the screen-level switch when the *status* changes
    // (rare — permission granted, camera ready, error, etc), not on
    // every pose/guidance update (several times a second). Guidance and
    // capture-button state are watched independently, deeper in the
    // tree, via `select` in `_ReadyView`'s children.
    final status = ref.watch(
      cameraSessionProvider.select((s) => s.status),
    );
    final errorMessage = ref.watch(
      cameraSessionProvider.select((s) => s.errorMessage),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _buildBody(status, errorMessage),
      ),
    );
  }

  Widget _buildBody(CameraSessionStatus status, String? errorMessage) {
    switch (status) {
      case CameraSessionStatus.initial:
      case CameraSessionStatus.requestingPermission:
      case CameraSessionStatus.loading:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        );

      case CameraSessionStatus.permissionDenied:
        return PermissionRequestView(
          onRetry: () =>
              ref.read(cameraSessionProvider.notifier).retryPermission(),
        );

      case CameraSessionStatus.error:
        return _ErrorView(
          message: errorMessage ??
              'Something went wrong starting the camera.',
          onRetry: () =>
              ref.read(cameraSessionProvider.notifier).initialize(),
        );

      case CameraSessionStatus.ready:
        return const _ReadyView();
    }
  }
}

/// The live camera experience. Deliberately does NOT watch the whole
/// [CameraSessionState] — it watches only `controller`, which changes
/// rarely (init, lens switch), so the (relatively expensive) preview
/// widget subtree doesn't rebuild on every pose/guidance update. The
/// fast-changing pieces (guidance text, capture-ready ring) are isolated
/// in their own `select`-scoped widgets below.
class _ReadyView extends ConsumerStatefulWidget {
  const _ReadyView();

  @override
  ConsumerState<_ReadyView> createState() => _ReadyViewState();
}

class _ReadyViewState extends ConsumerState<_ReadyView> {
  // Zoom gesture needs the level at gesture-start to compute a relative
  // scale, since ScaleUpdateDetails.scale is cumulative from the start
  // of the current gesture, not a delta from the last callback.
  double _zoomAtGestureStart = 1.0;

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(
      cameraSessionProvider.select((s) => s.controller),
    );

    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview dominates the screen (spec §13). This subtree
        // only rebuilds when `controller` itself changes identity.
        // Wrapped in a pinch-to-zoom gesture — a standard camera-app
        // interaction that was entirely missing before.
        Center(
          child: GestureDetector(
            onScaleStart: (_) {
              _zoomAtGestureStart = ref.read(cameraSessionProvider).zoomLevel;
            },
            onScaleUpdate: (details) {
              final requested = _zoomAtGestureStart * details.scale;
              ref.read(cameraSessionProvider.notifier).setZoomLevel(requested);
            },
            child: AspectRatio(
              aspectRatio: 1 / controller.value.aspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(controller),
                  const _PoseOverlayBinding(),
                ],
              ),
            ),
          ),
        ),

        // Subtle gradient scrims so the guidance chip and bottom
        // controls stay legible over bright or busy backgrounds,
        // without darkening the subject in the middle of frame — the
        // same technique real camera apps use. `IgnorePointer` so these
        // never intercept taps meant for the preview/controls above.
        const IgnorePointer(
          child: _EdgeScrim(alignment: Alignment.topCenter),
        ),
        const IgnorePointer(
          child: _EdgeScrim(alignment: Alignment.bottomCenter),
        ),

        // Top-left: flash / overlay / auto-capture toggles. Top-center:
        // guidance chip. Kept as two separate rows rather than one
        // crowded row so the guidance chip — the most important thing
        // on this screen — stays visually dominant and centered.
        Positioned(
          top: AppSpacing.sm,
          left: AppSpacing.sm,
          child: Row(
            children: [
              _FlashControlBinding(
                onPressed: () =>
                    ref.read(cameraSessionProvider.notifier).toggleFlash(),
              ),
              const SizedBox(width: AppSpacing.xs),
              _OverlayToggleBinding(
                onPressed: () =>
                    ref.read(cameraSessionProvider.notifier).toggleOverlay(),
              ),
              const SizedBox(width: AppSpacing.xs),
              _AutoCaptureToggleBinding(
                onChanged: (enabled) => ref
                    .read(cameraSessionProvider.notifier)
                    .setAutoCaptureEnabled(enabled),
              ),
            ],
          ),
        ),

        const Positioned(
          top: AppSpacing.md + 44, // clears the top control row above
          left: 0,
          right: 0,
          child: Align(
            alignment: Alignment.topCenter,
            child: _GuidanceOverlayBinding(),
          ),
        ),

        // Zoom level indicator — briefly meaningful feedback during a
        // pinch gesture; a real camera app never leaves the user
        // guessing what zoom they're at.
        const Positioned(
          top: AppSpacing.sm,
          right: AppSpacing.sm,
          child: _ZoomIndicatorBinding(),
        ),

        // Auto-capture countdown, shown centered so it's impossible to
        // miss right before the shutter fires on its own.
        const Positioned(
          left: 0,
          right: 0,
          bottom: 140,
          child: _AutoCaptureCountdownBinding(),
        ),

        // Bottom controls.
        Positioned(
          left: 0,
          right: 0,
          bottom: AppSpacing.xl,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _IconControl(
                icon: Icons.cameraswitch_rounded,
                semanticLabel: 'Switch camera',
                onPressed: () =>
                    ref.read(cameraSessionProvider.notifier).switchLens(),
              ),
              const _CaptureButtonBinding(),
              _IconControl(
                icon: Icons.photo_library_outlined,
                semanticLabel: 'View your photos',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GalleryScreen()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Watches only the guidance message — rebuilds several times a second,
/// scoped to this small chip rather than the whole screen.
class _GuidanceOverlayBinding extends ConsumerWidget {
  const _GuidanceOverlayBinding();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guidance = ref.watch(
      cameraSessionProvider.select((s) => s.guidance),
    );
    return GuidanceOverlay(message: guidance);
  }
}

/// Watches only capturing/hold state — rebuilds on guidance and capture
/// changes, scoped to the shutter button rather than the whole screen.
class _CaptureButtonBinding extends ConsumerWidget {
  const _CaptureButtonBinding();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCapturing = ref.watch(
      cameraSessionProvider.select((s) => s.isCapturing),
    );
    final trackingState = ref.watch(
      cameraSessionProvider.select((s) => s.guidance.state),
    );

    return CaptureButton(
      isCapturing: isCapturing,
      isReadyForPerfectShot: trackingState == PoseTrackingState.hold,
      onPressed: () => ref.read(cameraSessionProvider.notifier).capturePhoto(),
    );
  }
}

/// Watches only the current pose + guidance category + overlay-visible
/// flag — the skeleton/grid painter redraws at pose-evaluation
/// frequency, same as the guidance chip, but is a fully separate
/// widget so toggling it off removes its rebuild cost entirely rather
/// than just hiding a widget that's still repainting underneath.
class _PoseOverlayBinding extends ConsumerWidget {
  const _PoseOverlayBinding();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showOverlay = ref.watch(
      cameraSessionProvider.select((s) => s.showOverlay),
    );
    if (!showOverlay) return const SizedBox.shrink();

    final pose = ref.watch(cameraSessionProvider.select((s) => s.currentPose));
    final category =
        ref.watch(cameraSessionProvider.select((s) => s.guidance.category));

    return IgnorePointer(
      child: CustomPaint(
        painter: PoseOverlayPainter(
          pose: pose,
          guidanceCategory: category,
          showGrid: true,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _FlashControlBinding extends ConsumerWidget {
  const _FlashControlBinding({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flashMode = ref.watch(
      cameraSessionProvider.select((s) => s.flashMode),
    );
    final (icon, label) = switch (flashMode) {
      FlashMode.off => (Icons.flash_off_rounded, 'Flash off'),
      FlashMode.auto => (Icons.flash_auto_rounded, 'Flash auto'),
      FlashMode.torch => (Icons.flash_on_rounded, 'Flash on (torch)'),
      FlashMode.always => (Icons.flash_on_rounded, 'Flash on'),
    };
    return _SmallToggleButton(icon: icon, semanticLabel: label, onPressed: onPressed);
  }
}

class _OverlayToggleBinding extends ConsumerWidget {
  const _OverlayToggleBinding({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showOverlay = ref.watch(
      cameraSessionProvider.select((s) => s.showOverlay),
    );
    return _SmallToggleButton(
      icon: Icons.grid_on_rounded,
      semanticLabel: showOverlay ? 'Hide AI overlay' : 'Show AI overlay',
      active: showOverlay,
      onPressed: onPressed,
    );
  }
}

class _AutoCaptureToggleBinding extends ConsumerWidget {
  const _AutoCaptureToggleBinding({required this.onChanged});

  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoCaptureStatus = ref.watch(
      cameraSessionProvider.select((s) => s.autoCapture.status),
    );
    final enabled = autoCaptureStatus != AutoCaptureStatus.disabled;
    return _SmallToggleButton(
      icon: Icons.timer_outlined,
      semanticLabel:
          enabled ? 'Turn off auto capture' : 'Turn on auto capture',
      active: enabled,
      onPressed: () => onChanged(!enabled),
    );
  }
}

class _SmallToggleButton extends StatelessWidget {
  const _SmallToggleButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: semanticLabel,
      child: Semantics(
        label: semanticLabel,
        button: true,
        child: Material(
          color: active
              ? AppColors.accent.withValues(alpha: 0.22)
              : AppColors.surface.withValues(alpha: 0.6),
          shape: CircleBorder(
            side: active
                ? const BorderSide(color: AppColors.accent, width: 1)
                : BorderSide.none,
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Icon(
                icon,
                size: 20,
                color: active ? AppColors.accent : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ZoomIndicatorBinding extends ConsumerWidget {
  const _ZoomIndicatorBinding();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zoom = ref.watch(cameraSessionProvider.select((s) => s.zoomLevel));
    final maxZoom = ref.watch(cameraSessionProvider.select((s) => s.maxZoom));

    // No point showing "1.0x" when the device doesn't support zoom at
    // all — clutter for no information.
    if (maxZoom <= 1.0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '${zoom.toStringAsFixed(1)}x',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}

class _AutoCaptureCountdownBinding extends ConsumerWidget {
  const _AutoCaptureCountdownBinding();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoCapture = ref.watch(
      cameraSessionProvider.select((s) => s.autoCapture),
    );

    if (autoCapture.status != AutoCaptureStatus.countingDown) {
      return const SizedBox.shrink();
    }

    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: Container(
          key: ValueKey(autoCapture.secondsRemaining),
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.background.withValues(alpha: 0.55),
            border: Border.all(color: AppColors.accent, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            '${autoCapture.secondsRemaining}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}

class _EdgeScrim extends StatelessWidget {
  const _EdgeScrim({required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final isTop = alignment == Alignment.topCenter;
    return Align(
      alignment: alignment,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: isTop ? Alignment.topCenter : Alignment.bottomCenter,
            end: isTop ? Alignment.bottomCenter : Alignment.topCenter,
            colors: [
              isTop ? AppColors.scrimTop : AppColors.scrimBottom,
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class _IconControl extends StatelessWidget {
  const _IconControl({
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onPressed;

  /// Accessibility gap found and fixed during the UI-polish pass: these
  /// buttons previously had no label for screen readers and no tooltip
  /// for anyone unsure what an icon-only button does — a real
  /// regression against spec §16 ("support screen readers"), not just a
  /// style nit.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: semanticLabel,
      child: Semantics(
        label: semanticLabel,
        button: true,
        child: Material(
          color: AppColors.surface.withValues(alpha: 0.6),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(icon, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 40, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
