import 'package:camera/camera.dart';

import '../../capture/domain/auto_capture_state.dart';
import '../../guidance/domain/guidance_message.dart';
import '../../pose/domain/pose_landmark_data.dart';

/// Explicit UI states for the camera screen (spec §15 — every important
/// screen must support loading/empty/error/permission-denied/etc; never
/// leave the user staring at a blank screen).
enum CameraSessionStatus {
  initial,
  requestingPermission,
  permissionDenied,
  loading,
  ready,
  error,
}

class CameraSessionState {
  final CameraSessionStatus status;
  final CameraController? controller;
  final PoseFrame currentPose;
  final GuidanceMessage guidance;
  final String? errorMessage;
  final bool isCapturing;
  final String? lastCapturedPath;
  final double zoomLevel;
  final double minZoom;
  final double maxZoom;
  final FlashMode flashMode;
  final AutoCaptureState autoCapture;
  final bool showOverlay;

  const CameraSessionState({
    this.status = CameraSessionStatus.initial,
    this.controller,
    this.currentPose = PoseFrame.empty,
    this.guidance = GuidanceMessage.none,
    this.errorMessage,
    this.isCapturing = false,
    this.lastCapturedPath,
    this.zoomLevel = 1.0,
    this.minZoom = 1.0,
    this.maxZoom = 1.0,
    this.flashMode = FlashMode.off,
    this.autoCapture = AutoCaptureState.disabled,
    this.showOverlay = false,
  });

  CameraSessionState copyWith({
    CameraSessionStatus? status,
    CameraController? controller,
    PoseFrame? currentPose,
    GuidanceMessage? guidance,
    String? errorMessage,
    bool? isCapturing,
    String? lastCapturedPath,
    double? zoomLevel,
    double? minZoom,
    double? maxZoom,
    FlashMode? flashMode,
    AutoCaptureState? autoCapture,
    bool? showOverlay,
  }) {
    return CameraSessionState(
      status: status ?? this.status,
      controller: controller ?? this.controller,
      currentPose: currentPose ?? this.currentPose,
      guidance: guidance ?? this.guidance,
      errorMessage: errorMessage,
      isCapturing: isCapturing ?? this.isCapturing,
      lastCapturedPath: lastCapturedPath ?? this.lastCapturedPath,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      flashMode: flashMode ?? this.flashMode,
      autoCapture: autoCapture ?? this.autoCapture,
      showOverlay: showOverlay ?? this.showOverlay,
    );
  }
}
