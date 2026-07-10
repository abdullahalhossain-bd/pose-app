/// High-level scene categories the engine recognizes. Drives
/// scene-aware composition guidance.
///
/// Day 12 derives these heuristically from pose count + camera lens
/// + framing. Day 14+ will plug in an ML scene classifier (Google
/// ML Kit Image Labeling) — the enum stays the same.
enum SceneType {
  portrait,      // 1 person, upper body, back camera
  selfie,        // 1 person, front camera, close framing
  couple,        // 2 persons, close proximity
  group,         // 3+ persons
  fullBody,      // 1 person, full body visible
  landscape,     // no person, wide framing (Day 14 classifier)
  indoor,        // (Day 14 classifier)
  outdoor,       // (Day 14 classifier)
  nature,        // (Day 14 classifier)
  city,          // (Day 14 classifier)
  unknown,       // not enough signal to classify
}

/// Context derived from the current frame: scene type + signals
/// used to derive it. Drives scene-aware guidance.
class SceneContext {
  const SceneContext({
    required this.type,
    required this.personCount,
    required this.isFrontCamera,
    required this.subjectFrameRatio,
    required this.confidence,
  });

  final SceneType type;
  final int personCount;
  final bool isFrontCamera;
  final double subjectFrameRatio; // bounding box area / frame area
  final double confidence; // [0..1]

  /// Whether the scene prioritizes face framing over body framing.
  bool get prioritizesFace =>
      type == SceneType.portrait ||
      type == SceneType.selfie ||
      type == SceneType.couple;

  /// Whether the scene prioritizes horizon/balance.
  bool get prioritizesHorizon =>
      type == SceneType.landscape ||
      type == SceneType.fullBody;

  /// Whether the scene prioritizes equal spacing.
  bool get prioritizesSpacing => type == SceneType.group;
}
