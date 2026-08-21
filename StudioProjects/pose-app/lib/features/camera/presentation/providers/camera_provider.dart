import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../ai/domain/entities/ai_frame.dart';

/// Top-level camera state.
@immutable
class CameraState {
  const CameraState({
    this.permissionStatus = PermissionStatus.denied,
    this.controller,
    this.flashMode = FlashMode.off,
    this.lensDirection = CameraLensDirection.back,
    this.zoom = 1.0,
    this.showGrid = false,
    this.isCapturing = false,
    this.error,
    this.aiEnabled = false,
    this.frameStreamActive = false,
  });

  final PermissionStatus permissionStatus;
  final CameraController? controller;
  final FlashMode flashMode;
  final CameraLensDirection lensDirection;
  final double zoom;
  final bool showGrid;
  final bool isCapturing;
  final String? error;
  final bool aiEnabled;
  final bool frameStreamActive;

  bool get isReady => controller != null && controller!.value.isInitialized;
  bool get hasPermission => permissionStatus.isGranted;

  CameraState copyWith({
    PermissionStatus? permissionStatus,
    CameraController? controller,
    FlashMode? flashMode,
    CameraLensDirection? lensDirection,
    double? zoom,
    bool? showGrid,
    bool? isCapturing,
    String? error,
    bool clearError = false,
    bool? aiEnabled,
    bool? frameStreamActive,
  }) {
    return CameraState(
      permissionStatus: permissionStatus ?? this.permissionStatus,
      controller: controller ?? this.controller,
      flashMode: flashMode ?? this.flashMode,
      lensDirection: lensDirection ?? this.lensDirection,
      zoom: zoom ?? this.zoom,
      showGrid: showGrid ?? this.showGrid,
      isCapturing: isCapturing ?? this.isCapturing,
      error: clearError ? null : (error ?? this.error),
      aiEnabled: aiEnabled ?? this.aiEnabled,
      frameStreamActive: frameStreamActive ?? this.frameStreamActive,
    );
  }
}

typedef AiFrameSink = void Function(AiFrame frame);

class CameraNotifier extends StateNotifier<CameraState> {
  CameraNotifier({this.onFrame}) : super(const CameraState());

  /// Optional sink that receives every camera frame. Set by the AI
  /// pipeline when it binds to the camera. When null, frames are
  /// not streamed (saves battery when AI is off).
  final AiFrameSink? onFrame;

  /// Initialize permission + controller. Idempotent.
  Future<void> init() async {
    final perm = await Permission.camera.request();
    if (!perm.isGranted) {
      state = state.copyWith(permissionStatus: perm);
      return;
    }
    state = state.copyWith(permissionStatus: perm, clearError: true);

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        state = state.copyWith(error: 'No cameras available on this device.');
        return;
      }
      final initial = cameras.firstWhere(
        (c) => c.lensDirection == state.lensDirection,
        orElse: () => cameras.first,
      );
      await _initController(initial);
    } catch (e, st) {
      state = state.copyWith(error: 'Failed to initialize camera: $e');
      debugPrint('CameraNotifier.init failed\n$e\n$st');
    }
  }

  Future<void> _initController(CameraDescription camera) async {
    final old = state.controller;
    if (old != null) {
      await old.dispose();
    }
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      // YUV420 is required for real-time AI inference — JPEG would
      // force a decode per frame.
      imageFormatGroup:
          state.aiEnabled ? ImageFormatGroup.yuv420 : ImageFormatGroup.jpeg,
    );
    await controller.initialize();
    state = state.copyWith(
      controller: controller,
      lensDirection: camera.lensDirection,
      zoom: 1.0,
    );
    if (state.aiEnabled) {
      await startImageStream();
    }
  }

  /// Begin streaming frames to [onFrame]. Idempotent.
  Future<void> startImageStream() async {
    final c = state.controller;
    if (c == null || state.frameStreamActive || onFrame == null) return;
    await c.startImageStream(_handleCameraImage);
    state = state.copyWith(frameStreamActive: true);
  }

  Future<void> stopImageStream() async {
    final c = state.controller;
    if (c == null || !state.frameStreamActive) return;
    await c.stopImageStream();
    state = state.copyWith(frameStreamActive: false);
  }

  void _handleCameraImage(CameraImage image) {
    final sink = onFrame;
    if (sink == null) return;

    final planes = <AiFramePlane>[
      for (final p in image.planes)
        AiFramePlane(
          bytes: p.bytes,
          width: p.width ?? image.width,
          height: p.height ?? image.height,
          bytesPerPixel: p.bytesPerPixel ?? 1,
        ),
    ];

    sink(AiFrame(
      id: _frameIdCounter++,
      width: image.width,
      height: image.height,
      planes: planes,
      rotationDegrees: _sensorRotation,
      timestamp: DateTime.now().microsecondsSinceEpoch,
    ));
  }

  int _frameIdCounter = 0;
  int get _sensorRotation => 0; // Day 9: read from CameraDescription.

  /// Enable AI features — restarts the controller with the YUV image
  /// format so frames can be streamed.
  Future<void> enableAi() async {
    if (state.aiEnabled) return;
    state = state.copyWith(aiEnabled: true);
    // Re-init to switch imageFormatGroup.
    final desc = state.controller?.description;
    if (desc != null) await _initController(desc);
  }

  Future<void> disableAi() async {
    if (!state.aiEnabled) return;
    await stopImageStream();
    state = state.copyWith(aiEnabled: false);
    final desc = state.controller?.description;
    if (desc != null) await _initController(desc);
  }

  /// Switch front ↔ back.
  Future<void> flip() async {
    final cameras = await availableCameras();
    final target = state.lensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    final next = cameras.firstWhere(
      (c) => c.lensDirection == target,
      orElse: () => cameras.first,
    );
    await _initController(next);
  }

  Future<void> setFlash(FlashMode mode) async {
    final c = state.controller;
    if (c == null) return;
    await c.setFlashMode(mode);
    state = state.copyWith(flashMode: mode);
  }

  /// Cycle through off → on → auto.
  Future<void> cycleFlash() async {
    final next = switch (state.flashMode) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.always,
      FlashMode.always => FlashMode.torch,
      FlashMode.torch => FlashMode.off,
    };
    await setFlash(next);
  }

  Future<void> setZoom(double z) async {
    final c = state.controller;
    if (c == null) return;
    final clamped = z.clamp(1.0, 8.0);
    await c.setZoomLevel(clamped);
    state = state.copyWith(zoom: clamped);
  }

  void toggleGrid() => state = state.copyWith(showGrid: !state.showGrid);

  /// Take a picture. Returns the file path.
  Future<String?> capture() async {
    final c = state.controller;
    if (c == null || !c.value.isInitialized || state.isCapturing) return null;
    state = state.copyWith(isCapturing: true);
    try {
      final file = await c.takePicture();
      return file.path;
    } catch (e) {
      state = state.copyWith(error: 'Capture failed: $e');
      return null;
    } finally {
      if (mounted) state = state.copyWith(isCapturing: false);
    }
  }

  @override
  void dispose() {
    if (state.frameStreamActive) {
      state.controller?.stopImageStream();
    }
    state.controller?.dispose();
    super.dispose();
  }
}

final cameraProvider =
    StateNotifierProvider<CameraNotifier, CameraState>((ref) {
  return CameraNotifier();
});
