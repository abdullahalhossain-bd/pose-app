import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_visual_director/features/camera/domain/camera_state.dart';
import 'package:ai_visual_director/features/capture/domain/auto_capture_state.dart';
import 'package:ai_visual_director/features/guidance/domain/guidance_message.dart';
import 'package:ai_visual_director/features/pose/domain/pose_landmark_data.dart';

void main() {
  group('CameraSessionState.copyWith', () {
    test('defaults to initial status with no controller', () {
      const state = CameraSessionState();
      expect(state.status, CameraSessionStatus.initial);
      expect(state.controller, isNull);
      expect(state.currentPose, PoseFrame.empty);
      expect(state.guidance, GuidanceMessage.none);
      expect(state.isCapturing, false);
    });

    test('zoom/flash/auto-capture/overlay all have sensible, safe defaults', () {
      const state = CameraSessionState();
      // Zoom defaults to 1.0 with a 1.0-1.0 range (i.e. "no zoom
      // available yet") until CameraService reports the real range —
      // never a value that could be out of an unset range.
      expect(state.zoomLevel, 1.0);
      expect(state.minZoom, 1.0);
      expect(state.maxZoom, 1.0);
      expect(state.flashMode, FlashMode.off);
      // Auto Capture defaults to disabled — spec §5: "MUST remain
      // optional", never on by default for a feature this new.
      expect(state.autoCapture.status, AutoCaptureStatus.disabled);
      expect(state.showOverlay, false);
    });

    test('copyWith only changes the fields passed in', () {
      const original = CameraSessionState(
        status: CameraSessionStatus.ready,
        isCapturing: false,
      );

      final updated = original.copyWith(isCapturing: true);

      expect(updated.status, CameraSessionStatus.ready,
          reason: 'status should be unchanged');
      expect(updated.isCapturing, true);
    });

    test('copyWith(errorMessage: ...) can set errorMessage explicitly', () {
      const original = CameraSessionState();
      final updated = original.copyWith(
        status: CameraSessionStatus.error,
        errorMessage: 'boom',
      );
      expect(updated.errorMessage, 'boom');
    });

    test('errorMessage is cleared (not preserved) on the next copyWith without it', () {
      // This documents real, slightly surprising behavior: `errorMessage`
      // is NOT defaulted to `this.errorMessage` in copyWith (unlike every
      // other field), so any subsequent copyWith call silently drops a
      // previously-set error unless the caller passes it again. This is
      // intentional here (transitioning status away from `error` should
      // clear stale error text) but is worth a test precisely because
      // it's the one field that behaves differently from its siblings.
      const withError = CameraSessionState(
        status: CameraSessionStatus.error,
        errorMessage: 'boom',
      );
      final recovered = withError.copyWith(status: CameraSessionStatus.loading);
      expect(recovered.errorMessage, isNull);
    });

    test('zoom bounds and level update independently of other fields', () {
      const original = CameraSessionState(zoomLevel: 1.0, minZoom: 1.0, maxZoom: 1.0);
      final updated = original.copyWith(zoomLevel: 2.5, minZoom: 1.0, maxZoom: 8.0);
      expect(updated.zoomLevel, 2.5);
      expect(updated.maxZoom, 8.0);
      // Untouched fields survive.
      expect(updated.flashMode, FlashMode.off);
    });

    test('flashMode and autoCapture update independently', () {
      const original = CameraSessionState();
      final updated = original.copyWith(
        flashMode: FlashMode.torch,
        autoCapture: AutoCaptureState.waiting,
      );
      expect(updated.flashMode, FlashMode.torch);
      expect(updated.autoCapture.status, AutoCaptureStatus.waiting);
    });
  });
}
