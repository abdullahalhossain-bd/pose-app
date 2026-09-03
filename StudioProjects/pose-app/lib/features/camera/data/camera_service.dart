import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Wraps the `camera` plugin: permission checks, controller lifecycle,
/// lens switching, and capture. Kept free of any UI or AI concerns
/// (spec §17 — services layer stays independent of presentation and
/// vision logic).
class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _activeCameraIndex = 0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;
  double get minZoom => _minZoom;
  double get maxZoom => _maxZoom;

  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> hasCameraPermission() async {
    return (await Permission.camera.status).isGranted;
  }

  Future<void> initialize({CameraLensDirection preferredLens = CameraLensDirection.back}) async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      throw CameraException('no_cameras', 'No cameras available on this device.');
    }

    _activeCameraIndex = _cameras.indexWhere((c) => c.lensDirection == preferredLens);
    if (_activeCameraIndex == -1) _activeCameraIndex = 0;

    await _openController(_cameras[_activeCameraIndex]);
  }

  Future<void> _openController(CameraDescription description) async {
    await _controller?.dispose();
    _controller = CameraController(
      description,
      // Medium resolution: real-time pose inference doesn't need 4K,
      // and lower resolution keeps frame processing fast on mid/low-tier
      // devices (spec §20/§21 — never process more than needed).
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    await _controller!.initialize();

    // Zoom bounds are per-camera (front/back often differ, and some
    // devices report a minZoom above 1.0 for ultra-wide sensors) — must
    // be re-read every time the controller is (re)opened, not cached
    // once at app start.
    try {
      _minZoom = await _controller!.getMinZoomLevel();
      _maxZoom = await _controller!.getMaxZoomLevel();
    } catch (_) {
      // Some devices/simulators don't support zoom queries at all —
      // degrade to "zoom unavailable" (min==max==1.0) rather than
      // crashing initialization over a non-essential feature.
      _minZoom = 1.0;
      _maxZoom = 1.0;
    }
  }

  Future<void> switchLens() async {
    if (_cameras.length < 2) return;
    _activeCameraIndex = (_activeCameraIndex + 1) % _cameras.length;
    await _openController(_cameras[_activeCameraIndex]);
  }

  /// Clamps to the current camera's actual supported range — the caller
  /// (CameraSessionController) doesn't need to know per-device bounds,
  /// it can pass any requested value and this will do the right thing.
  Future<double> setZoomLevel(double zoom) async {
    if (_controller == null || !_controller!.value.isInitialized) return 1.0;
    final clamped = zoom.clamp(_minZoom, _maxZoom);
    await _controller!.setZoomLevel(clamped);
    return clamped;
  }

  Future<void> setFlashMode(FlashMode mode) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      await _controller!.setFlashMode(mode);
    } catch (_) {
      // Some devices (most front cameras) have no flash hardware at
      // all — setFlashMode throws rather than silently no-op-ing.
      // Treat that as "flash unavailable here" rather than an error
      // the user needs to see.
    }
  }

  Future<void> startImageStream(void Function(CameraImage image) onFrame) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isStreamingImages) return;
    await _controller!.startImageStream(onFrame);
  }

  Future<void> stopImageStream() async {
    if (_controller != null && _controller!.value.isStreamingImages) {
      await _controller!.stopImageStream();
    }
  }

  /// Captures a still photo. Image streaming is paused around the
  /// capture, since some devices can't run both concurrently.
  Future<File> capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw CameraException('not_initialized', 'Camera is not ready.');
    }

    final wasStreaming = _controller!.value.isStreamingImages;
    if (wasStreaming) await stopImageStream();

    try {
      final xFile = await _controller!.takePicture();
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'avd_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = '${dir.path}/$fileName';
      final saved = await File(xFile.path).copy(savedPath);
      return saved;
    } finally {
      // Streaming is resumed by the caller once it re-attaches its
      // frame callback, to avoid this service depending on guidance state.
    }
  }

  CameraLensDirection get activeLensDirection =>
      _cameras.isEmpty ? CameraLensDirection.back : _cameras[_activeCameraIndex].lensDirection;

  int get sensorOrientation =>
      _cameras.isEmpty ? 0 : _cameras[_activeCameraIndex].sensorOrientation;

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }
}
