import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../capture/application/auto_capture_engine.dart';
import '../../capture/domain/auto_capture_state.dart';
import '../../composition/application/composition_analyzer.dart';
import '../../composition/domain/composition_message.dart';
import '../../device/application/device_tier_detector.dart';
import '../../device/domain/performance_config.dart';
import '../../guidance/application/attention_engine.dart';
import '../../guidance/application/guidance_coordinator.dart';
import '../../guidance/application/guidance_engine.dart';
import '../../guidance/domain/guidance_message.dart';
import '../../lighting/application/lighting_analyzer.dart';
import '../../lighting/domain/lighting_message.dart';
import '../../lighting/domain/lighting_reading.dart';
import '../../pose/data/pose_detection_service.dart';
import '../data/camera_service.dart';
import '../domain/camera_state.dart';

/// The single orchestrator for the camera screen: owns the camera
/// session, feeds frames to pose detection, runs the guidance engine,
/// and exposes one immutable state object to the UI.
///
/// This is the "Frame Pipeline → Vision → Pose → Decision Engine →
/// Guidance" chain from spec §19, implemented as a thin coordinator over
/// three independently-testable services/engines rather than one god
/// class (spec §27).
///
/// LIFECYCLE NOTE (fixed during P0 hardening pass): this StateNotifier
/// itself is owned by Riverpod for the lifetime of the provider scope —
/// it must never be manually `dispose()`d by app-lifecycle callbacks,
/// because `StateNotifier` throws if you touch `state` after `dispose()`
/// has run, and there is no supported way to "undispose" it. Backgrounding
/// the app must only tear down the camera/detector *resources* via
/// [pauseSession] / [resumeSession]; the real `dispose()` override here
/// is reserved for when Riverpod itself disposes the provider (e.g. the
/// widget subtree is removed for good).
class CameraSessionController extends StateNotifier<CameraSessionState> {
  CameraSessionController({PerformanceConfig? performanceConfig})
      : _cameraService = CameraService(),
        _poseService = PoseDetectionService(),
        _guidanceEngine = GuidanceEngine(),
        _attentionEngine = AttentionEngine(),
        _compositionEngine = CompositionEngine(),
        _lightingAnalyzer = const LightingAnalyzer(),
        _lightingEngine = LightingEngine(),
        _autoCaptureEngine = AutoCaptureEngine(),
        // Device-tier detection (spec §9 of the P1-completion pass):
        // classified once from a cheap, dependency-free signal
        // (dart:io's `Platform.numberOfProcessors`) rather than
        // benchmarked. See device/application/device_tier_detector.dart
        // for why this proxy was chosen and its limitations.
        performanceConfig = performanceConfig ?? PerformanceConfig.forTier(detectDeviceTier()),
        super(const CameraSessionState());

  final CameraService _cameraService;
  final PoseDetectionService _poseService;
  final GuidanceEngine _guidanceEngine;
  final AttentionEngine _attentionEngine;
  final CompositionEngine _compositionEngine;
  final LightingAnalyzer _lightingAnalyzer;
  final LightingEngine _lightingEngine;
  final AutoCaptureEngine _autoCaptureEngine;
  final PerformanceConfig performanceConfig;

  // Lighting most recently classified — merged with pose guidance in
  // _onFrame. Kept as a field (not recomputed inline) because lighting
  // is sampled far less often than pose (see performanceConfig) but
  // still needs to be available every time we merge and emit a new
  // guidance message.
  LightingMessage _lastLightingMessage = LightingMessage.unknown;

  // StateNotifier (the `state_notifier` package underneath Riverpod's
  // StateNotifierProvider) does not expose a public `mounted` getter for
  // subclasses, despite that being a natural thing to reach for here —
  // confirmed by inspecting the package's public API surface rather than
  // assumed. We track disposal ourselves and gate every `state =`
  // assignment that happens after an `await` behind it, so a frame
  // callback or async completion that lands after teardown can't throw.
  bool _disposed = false;

  // Frame sampling rates now come from `performanceConfig`
  // (device-tier-aware) instead of hardcoded constants — see
  // device/domain/performance_config.dart. Composition analysis piggy-
  // backs on the same cadence as pose (it consumes the same PoseFrame,
  // at zero extra frame-processing cost), so it has no separate rate.
  int _frameCounter = 0;

  bool _isProcessingFrame = false;
  bool _isProcessingLighting = false;

  Future<void> initialize() async {
    if (_disposed) return;
    state = state.copyWith(status: CameraSessionStatus.requestingPermission);

    final hasPermission = await _cameraService.hasCameraPermission() ||
        await _cameraService.requestCameraPermission();
    if (_disposed) return;

    if (!hasPermission) {
      state = state.copyWith(status: CameraSessionStatus.permissionDenied);
      return;
    }

    state = state.copyWith(status: CameraSessionStatus.loading);
    try {
      await _cameraService.initialize();
      if (_disposed) return;
      _cameraService.controller?.addListener(_onCameraControllerUpdate);
      _guidanceEngine.reset();
      _attentionEngine.reset();
      _compositionEngine.reset();
      _lightingEngine.reset();
      _autoCaptureEngine.reset();
      _lastLightingMessage = LightingMessage.unknown;
      state = state.copyWith(
        status: CameraSessionStatus.ready,
        controller: _cameraService.controller,
        zoomLevel: 1.0,
        minZoom: _cameraService.minZoom,
        maxZoom: _cameraService.maxZoom,
      );
      await _cameraService.startImageStream(_onFrame);
    } catch (e) {
      if (_disposed) return;
      state = state.copyWith(
        status: CameraSessionStatus.error,
        errorMessage: 'Could not start the camera. Please try again.',
      );
    }
  }

  /// Reacts to the camera plugin's own error signal — covers the case
  /// where the camera becomes unavailable mid-session for a reason
  /// outside our control (another app takes the hardware, an OEM
  /// throws mid-stream, etc). Previously unhandled: nothing was
  /// listening to `CameraController`'s `hasError`/`errorDescription`,
  /// so this failure mode would have frozen the preview with no
  /// feedback to the user. Found during the P0 lifecycle audit
  /// (scenario 14: "camera becomes unavailable").
  void _onCameraControllerUpdate() {
    if (_disposed) return;
    final controller = _cameraService.controller;
    if (controller == null) return;
    if (controller.value.hasError) {
      state = state.copyWith(
        status: CameraSessionStatus.error,
        errorMessage: controller.value.errorDescription ??
            'The camera stopped unexpectedly. Please try again.',
      );
    }
  }

  /// Tears down camera + detector resources without disposing this
  /// controller — call when the app is backgrounded. Safe to call
  /// multiple times; safe to call even if the camera was never started.
  Future<void> pauseSession() async {
    if (_disposed) return;
    _cameraService.controller?.removeListener(_onCameraControllerUpdate);
    await _cameraService.stopImageStream();
    await _cameraService.dispose();
    // The pose detector itself is cheap to keep alive and does not hold
    // a camera-hardware handle, so it is left running across a pause —
    // only the camera resource needs releasing for battery/thermal and
    // to avoid the "camera already in use" errors some OEMs throw if a
    // backgrounded app doesn't relinquish it.
    state = state.copyWith(
      status: CameraSessionStatus.loading,
      controller: null,
    );
  }

  /// Re-opens camera resources after [pauseSession] — call when the app
  /// resumes from background. This intentionally re-runs the full
  /// [initialize] flow (permission may have been revoked from system
  /// settings while backgrounded) rather than assuming prior state is
  /// still valid.
  Future<void> resumeSession() => initialize();

  void _onFrame(CameraImage image) {
    if (_disposed) return;
    _frameCounter++;

    if (_frameCounter % performanceConfig.lightingFrameSampleRate == 0) {
      _sampleLighting(image);
    }

    if (_frameCounter % performanceConfig.poseFrameSampleRate != 0) return;

    // Extra latest-frame-wins guard at the controller level, in addition
    // to PoseDetectionService's own `_isBusy` check — prevents a burst
    // of near-simultaneous frame callbacks from firing overlapping
    // `.then()` continuations that could interleave state writes.
    if (_isProcessingFrame) return;
    _isProcessingFrame = true;

    _poseService
        .processFrame(
      image,
      _cameraService.sensorOrientation,
      _cameraService.activeLensDirection,
    )
        .then((pose) {
      if (_disposed) return;
      if (pose == null) return; // skipped (busy) — not an error

      // Composition and attention both consume the same PoseFrame pose
      // detection already produced this cycle — zero extra frame
      // processing cost, unlike lighting which needs its own separate
      // (much rarer) sampling pass over raw pixel bytes.
      final poseGuidance = _guidanceEngine.evaluate(pose);
      final attentionGuidance = _attentionEngine.evaluate(pose);
      final compositionGuidance = _compositionEngine.classify(pose);

      final merged = mergeGuidance(
        poseGuidance: poseGuidance,
        attentionGuidance: attentionGuidance,
        compositionGuidance: compositionGuidance,
        lightingGuidance: _lastLightingMessage,
      );

      // Auto Capture consumes the already-debounced `hold` signal from
      // the merge above — it never looks at raw pose data itself (spec
      // "consume, don't own" pattern applied here too). Evaluated even
      // when disabled (cheap early-return) so its internal state stays
      // consistent if the user toggles it mid-session.
      final autoCaptureResult =
          _autoCaptureEngine.evaluate(merged.state == PoseTrackingState.hold);

      state = state.copyWith(
        currentPose: pose,
        guidance: merged,
        autoCapture: autoCaptureResult.state,
      );

      if (autoCaptureResult.shouldCapture) {
        // Fire-and-forget: capturePhoto() manages its own isCapturing
        // state and stream pause/resume. Not awaited here because doing
        // so would block this frame's `.then()` continuation, and
        // capture already guards against concurrent calls itself.
        unawaited(capturePhoto());
      }
    }).catchError((Object error) {
      if (_disposed) return;
      final guidance = _guidanceEngine.onError();
      state = state.copyWith(guidance: guidance);
    }).whenComplete(() {
      _isProcessingFrame = false;
    });
  }

  /// Runs brightness analysis off the same frame stream, at a much
  /// lower sample rate than pose (see `performanceConfig.lightingFrameSampleRate`)
  /// and with its own busy guard so a slow lighting sample can never
  /// block or queue behind pose processing, or vice versa. The result
  /// is cached in [_lastLightingMessage] and merged into guidance on
  /// the *next* pose evaluation, not pushed to `state` directly —
  /// lighting alone changing should not, by itself, trigger a UI update.
  void _sampleLighting(CameraImage image) {
    if (_isProcessingLighting) return;
    _isProcessingLighting = true;

    try {
      // Dispatch on the pixel format we actually asked the camera for
      // (see CameraService._openController), not on plane count — an
      // earlier version of this method used `planes.length == 1` as a
      // proxy for "this must be BGRA8888", which is wrong: Android NV21
      // can legitimately be delivered as either one concatenated plane
      // or two separate ones depending on device/plugin version (the
      // same uncertainty documented in pose_detection_service.dart).
      // Using the format group directly removes the guess entirely.
      final isBgra = image.format.group == ImageFormatGroup.bgra8888;

      final LightingReading reading;
      if (isBgra) {
        reading = _lightingAnalyzer.analyzeBgra8888(
          image.planes.first.bytes,
          image.width,
          image.height,
          image.planes.first.bytesPerRow,
        );
      } else {
        // NV21's luma plane is always exactly width*height bytes,
        // whether or not the plugin happens to deliver it concatenated
        // with the interleaved UV data that follows it in the same
        // buffer. Clipping to exactly that many bytes guarantees we
        // only ever average real luma — without the clip, a
        // concatenated single-plane buffer would mix ~33% chroma bytes
        // into the "brightness" average (4:2:0 subsampling means the
        // UV data is about half the size of the Y data), which is
        // simply wrong, not just imprecise.
        final yPlane = image.planes.first.bytes;
        final yByteCount = image.width * image.height;
        final lumaOnly = yByteCount > 0 && yByteCount <= yPlane.length
            ? Uint8List.sublistView(yPlane, 0, yByteCount)
            : yPlane;
        reading = _lightingAnalyzer.analyzeYPlane(lumaOnly);
      }

      _lastLightingMessage = _lightingEngine.classify(reading);
    } catch (_) {
      // Lighting is a nice-to-have layered on top of pose guidance —
      // never let a lighting analysis failure surface as a user-facing
      // error or disrupt the pose pipeline it's merged into.
    } finally {
      _isProcessingLighting = false;
    }
  }

  Future<void> switchLens() async {
    if (_disposed) return;
    _cameraService.controller?.removeListener(_onCameraControllerUpdate);
    await _cameraService.stopImageStream();
    await _cameraService.switchLens();
    if (_disposed) return;
    _cameraService.controller?.addListener(_onCameraControllerUpdate);
    _guidanceEngine.reset();
    _attentionEngine.reset();
    _compositionEngine.reset();
    _lightingEngine.reset();
    _autoCaptureEngine.reset();
    _lastLightingMessage = LightingMessage.unknown;
    state = state.copyWith(
      controller: _cameraService.controller,
      zoomLevel: 1.0,
      minZoom: _cameraService.minZoom,
      maxZoom: _cameraService.maxZoom,
      flashMode: FlashMode.off,
    );
    await _cameraService.startImageStream(_onFrame);
  }

  Future<void> capturePhoto() async {
    if (_disposed || state.isCapturing) return;
    state = state.copyWith(isCapturing: true);
    try {
      final file = await _cameraService.capturePhoto();
      if (_disposed) return;
      state = state.copyWith(
        isCapturing: false,
        lastCapturedPath: file.path,
      );
    } catch (_) {
      if (_disposed) return;
      state = state.copyWith(isCapturing: false);
    } finally {
      // Resume live guidance after capture, unless we were torn down
      // mid-capture (e.g. user backgrounded the app while the shutter
      // was firing).
      if (!_disposed) {
        await _cameraService.startImageStream(_onFrame);
      }
    }
  }

  Future<void> retryPermission() => initialize();

  Future<void> setZoomLevel(double zoom) async {
    if (_disposed) return;
    final clamped = await _cameraService.setZoomLevel(zoom);
    if (_disposed) return;
    state = state.copyWith(zoomLevel: clamped);
  }

  /// Cycles off → auto → torch, skipping `always` (which fires the
  /// flash on every capture including accidental ones) — `torch`
  /// (continuous light) is the more useful "on" state for a guidance
  /// app where the user is looking at the screen for a while before
  /// capturing, not snapping instantly.
  Future<void> toggleFlash() async {
    if (_disposed) return;
    final next = switch (state.flashMode) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.torch,
      FlashMode.torch => FlashMode.off,
      FlashMode.always => FlashMode.off,
    };
    await _cameraService.setFlashMode(next);
    if (_disposed) return;
    state = state.copyWith(flashMode: next);
  }

  /// Auto Capture is opt-in and defaults to off (spec §5) — this is the
  /// only way it ever turns on.
  void setAutoCaptureEnabled(bool enabled) {
    if (_disposed) return;
    _autoCaptureEngine.setEnabled(enabled);
    state = state.copyWith(
      autoCapture: enabled ? AutoCaptureState.waiting : AutoCaptureState.disabled,
    );
  }

  void toggleOverlay() {
    if (_disposed) return;
    state = state.copyWith(showOverlay: !state.showOverlay);
  }

  @override
  void dispose() {
    _disposed = true;
    _cameraService.controller?.removeListener(_onCameraControllerUpdate);
    // Fire-and-forget: StateNotifier.dispose() is synchronous, so the
    // actual resource teardown below can't be awaited here. Both
    // services are individually safe to have in-flight operations
    // abandoned (PoseDetectionService checks `_disposed` before using
    // its detector; CameraController.dispose() is idempotent-safe).
    unawaited(_cameraService.stopImageStream());
    unawaited(_cameraService.dispose());
    unawaited(_poseService.dispose());
    super.dispose();
  }
}

final cameraSessionProvider =
    StateNotifierProvider<CameraSessionController, CameraSessionState>(
  (ref) => CameraSessionController(),
);
