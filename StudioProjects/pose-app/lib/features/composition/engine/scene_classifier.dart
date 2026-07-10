import '../../pose/domain/entities/pose_sample.dart';
import '../config/composition_config.dart';
import '../domain/enums/scene_type.dart';
import '../utils/composition_geometry.dart';

/// Derives the [SceneType] from pose count + camera lens + framing.
///
/// Day 12 heuristic — fast, deterministic. Day 14+ will swap in ML
/// image labeling (Google ML Kit Image Labeling) for outdoor/nature/
/// city/etc.; the [SceneContext] shape stays the same.
class SceneClassifier {
  SceneClassifier(this.config);

  final CompositionConfig config;

  SceneContext classify({
    required List<PoseSample> poses,
    required bool isFrontCamera,
  }) {
    final personCount = poses.length;
    final primary = poses.isEmpty
        ? null
        : (List<PoseSample>.from(poses)
              ..sort((a, b) => b.confidence.compareTo(a.confidence)))
            .first;
    final frameRatio = CompositionGeometry.subjectFrameRatio(primary);

    SceneType type;
    double confidence;

    if (personCount == 0) {
      type = SceneType.landscape;
      confidence = 0.4; // low — Day 14 ML classifier will improve
    } else if (personCount == 1) {
      if (isFrontCamera && frameRatio > config.selfieFrontCameraFrameRatio) {
        type = SceneType.selfie;
        confidence = 0.9;
      } else if (frameRatio > 0.50) {
        type = SceneType.portrait;
        confidence = 0.85;
      } else {
        // Check if full body visible: bbox spans most of frame height.
        final b = primary?.boundingBox;
        if (b != null && b.height > 0.75) {
          type = SceneType.fullBody;
          confidence = 0.8;
        } else {
          type = SceneType.portrait;
          confidence = 0.7;
        }
      }
    } else if (personCount == 2) {
      // Check proximity — couple if close, else just two people.
      final p1 = poses[0].boundingBox;
      final p2 = poses[1].boundingBox;
      if (p1 != null && p2 != null) {
        final cx1 = p1.left + p1.width / 2;
        final cx2 = p2.left + p2.width / 2;
        final dist = (cx1 - cx2).abs();
        if (dist < config.coupleProximityRatio) {
          type = SceneType.couple;
          confidence = 0.85;
        } else {
          type = SceneType.group;
          confidence = 0.7;
        }
      } else {
        type = SceneType.couple;
        confidence = 0.6;
      }
    } else {
      type = SceneType.group;
      confidence = 0.9;
    }

    return SceneContext(
      type: type,
      personCount: personCount,
      isFrontCamera: isFrontCamera,
      subjectFrameRatio: frameRatio,
      confidence: confidence,
    );
  }
}
