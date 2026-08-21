import 'dart:ui';

import 'package:flutter/painting.dart' show BoxFit;

import '../domain/entities/pose_sample.dart';
import '../domain/enums/pose_landmark_type.dart';

/// Single source of truth for transforming pose coordinates between
/// the three coordinate spaces we deal with:
///
/// 1. **AI space** — normalized [0..1] over the model's input image
///    (after rotation / crop). This is what [PoseSample] holds.
/// 2. **Preview space** — pixel coords over the rendered camera
///    preview widget, before any [FittedBox] scaling.
/// 3. **Overlay space** — pixel coords over the [AiOverlayLayer]
///    widget, which is what painters receive in `Size`.
///
/// Why one mapper? Because every overlay needs the same transform,
/// and scattering the math across painters guarantees bugs. With a
/// single class we can unit-test the transform against fixtures.
class PoseCoordinateMapper {
  PoseCoordinateMapper({
    required this.previewSize,
    required this.overlaySize,
    required this.sensorRotationDegrees,
    required this.isFrontCamera,
    required this.fitter,
  });

  /// Native camera sensor output dimensions (before rotation).
  /// For a back camera in portrait, this is e.g. (1080, 1920).
  final Size previewSize;

  /// Size of the overlay widget receiving the painter.
  final Size overlaySize;

  /// 0 / 90 / 180 / 270 — sensor orientation reported by CameraDescription.
  final int sensorRotationDegrees;

  /// Front cameras mirror the image — needed for X-flip.
  final bool isFrontCamera;

  /// How the preview is fitted into the overlay. We use the same
  /// [BoxFit] the camera widget uses (typically [BoxFit.cover]).
  final BoxFit fitter;

  /// Map a normalized AI-space point to overlay-space pixels.
  Offset aiToOverlay(Offset aiPoint) {
    // Step 1: undo the sensor rotation baked into AI input.
    final rotated = _applySensorRotation(aiPoint);

    // Step 2: mirror X for front camera.
    final mirrored = isFrontCamera ? Offset(1 - rotated.dx, rotated.dy) : rotated;

    // Step 3: fit the (now-rotated) preview into the overlay rect.
    final fittedRect = _fitRect(previewSize, overlaySize, fitter);
    return Offset(
      fittedRect.left + mirrored.dx * fittedRect.width,
      fittedRect.top + mirrored.dy * fittedRect.height,
    );
  }

  /// Convenience: map a [PoseLandmark] by type.
  Offset landmarkToOverlay(PoseSample pose, PoseLandmarkType type) {
    final l = pose[type];
    if (l == null) return Offset.zero;
    return aiToOverlay(Offset(l.x, l.y));
  }

  Offset _applySensorRotation(Offset p) {
    switch (sensorRotationDegrees) {
      case 90:
        return Offset(p.dy, 1.0 - p.dx);
      case 180:
        return Offset(1.0 - p.dx, 1.0 - p.dy);
      case 270:
        return Offset(1.0 - p.dy, p.dx);
      case 0:
      default:
        return p;
    }
  }

  /// Compute the rect that [previewSize] occupies inside [overlaySize]
  /// under the given [BoxFit]. This mirrors Flutter's RenderFittedBox.
  Rect _fitRect(Size content, Size container, BoxFit fit) {
    if (content.isEmpty || container.isEmpty) return Rect.zero;

    final contentAspect = content.width / content.height;
    final containerAspect = container.width / container.height;

    switch (fit) {
      case BoxFit.cover:
      // Scale so the content FILLS the container; crop overflow.
        final scale = contentAspect > containerAspect
            ? container.height / content.height
            : container.width / content.width;
        final w = content.width * scale;
        final h = content.height * scale;
        return Rect.fromCenter(
          center: container.center(Offset.zero),
          width: w,
          height: h,
        );
      case BoxFit.contain:
        final scale = contentAspect > containerAspect
            ? container.width / content.width
            : container.height / content.height;
        final w = content.width * scale;
        final h = content.height * scale;
        return Rect.fromCenter(
          center: container.center(Offset.zero),
          width: w,
          height: h,
        );
      case BoxFit.fill:
        return Offset.zero & container;
      default:
      // Treat none/scaleDown/etc. as contain for safety.
        return _fitRect(content, container, BoxFit.contain);
    }
  }
}
