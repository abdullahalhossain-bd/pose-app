/// ML Kit Pose Detection's 33 body landmarks.
///
/// Stable across all platforms — ML Kit uses this exact enumeration.
/// Future backends (TFLite MoveNet 17-pt, MediaPipe 33-pt) map into
/// this enum so the pipeline / overlays never change.
///
/// Indices match ML Kit's `PoseLandmark.type` integer values.
enum PoseLandmarkType {
  nose(0),
  leftEyeInner(1),
  leftEye(2),
  leftEyeOuter(3),
  rightEyeInner(4),
  rightEye(5),
  rightEyeOuter(6),
  leftEar(7),
  rightEar(8),
  mouthLeft(9),
  mouthRight(10),
  leftShoulder(11),
  rightShoulder(12),
  leftElbow(13),
  rightElbow(14),
  leftWrist(15),
  rightWrist(16),
  leftPinky(17),
  rightPinky(18),
  leftIndex(19),
  rightIndex(20),
  leftThumb(21),
  rightThumb(22),
  leftHip(23),
  rightHip(24),
  leftKnee(25),
  rightKnee(26),
  leftAnkle(27),
  rightAnkle(28),
  leftHeel(29),
  rightHeel(30),
  leftFootIndex(31),
  rightFootIndex(32);

  const PoseLandmarkType(this.mlKitIndex);
  final int mlKitIndex;

  static PoseLandmarkType fromMlKit(int raw) {
    if (raw < 0 || raw >= values.length) {
      return PoseLandmarkType.nose;
    }
    return values[raw];
  }
}

/// Connections between landmarks that form the human skeleton.
///
/// Used by [PoseLinePainter] to draw bones. This is the COCO-17
/// connectivity subset that's stable across all major pose models —
/// we deliberately don't draw face/foot micro-lines to keep the
/// overlay readable on a phone screen.
class PoseSkeleton {
  const PoseSkeleton._();

  /// Pairs of landmark indices to connect with a line.
  static const List<({PoseLandmarkType a, PoseLandmarkType b})> connections = [
    // Head & shoulders
    (a: PoseLandmarkType.leftShoulder, b: PoseLandmarkType.rightShoulder),
    (a: PoseLandmarkType.leftShoulder, b: PoseLandmarkType.leftEar),
    (a: PoseLandmarkType.rightShoulder, b: PoseLandmarkType.rightEar),
    // Left arm
    (a: PoseLandmarkType.leftShoulder, b: PoseLandmarkType.leftElbow),
    (a: PoseLandmarkType.leftElbow, b: PoseLandmarkType.leftWrist),
    (a: PoseLandmarkType.leftWrist, b: PoseLandmarkType.leftThumb),
    (a: PoseLandmarkType.leftWrist, b: PoseLandmarkType.leftPinky),
    (a: PoseLandmarkType.leftWrist, b: PoseLandmarkType.leftIndex),
    // Right arm
    (a: PoseLandmarkType.rightShoulder, b: PoseLandmarkType.rightElbow),
    (a: PoseLandmarkType.rightElbow, b: PoseLandmarkType.rightWrist),
    (a: PoseLandmarkType.rightWrist, b: PoseLandmarkType.rightThumb),
    (a: PoseLandmarkType.rightWrist, b: PoseLandmarkType.rightPinky),
    (a: PoseLandmarkType.rightWrist, b: PoseLandmarkType.rightIndex),
    // Torso
    (a: PoseLandmarkType.leftShoulder, b: PoseLandmarkType.leftHip),
    (a: PoseLandmarkType.rightShoulder, b: PoseLandmarkType.rightHip),
    (a: PoseLandmarkType.leftHip, b: PoseLandmarkType.rightHip),
    // Left leg
    (a: PoseLandmarkType.leftHip, b: PoseLandmarkType.leftKnee),
    (a: PoseLandmarkType.leftKnee, b: PoseLandmarkType.leftAnkle),
    (a: PoseLandmarkType.leftAnkle, b: PoseLandmarkType.leftHeel),
    (a: PoseLandmarkType.leftAnkle, b: PoseLandmarkType.leftFootIndex),
    // Right leg
    (a: PoseLandmarkType.rightHip, b: PoseLandmarkType.rightKnee),
    (a: PoseLandmarkType.rightKnee, b: PoseLandmarkType.rightAnkle),
    (a: PoseLandmarkType.rightAnkle, b: PoseLandmarkType.rightHeel),
    (a: PoseLandmarkType.rightAnkle, b: PoseLandmarkType.rightFootIndex),
  ];
}
