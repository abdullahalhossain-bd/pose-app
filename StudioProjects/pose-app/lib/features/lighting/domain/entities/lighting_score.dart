import 'package:flutter/foundation.dart';

import '../enums/lighting_enums.dart';

/// A single lighting factor's sub-score.
@immutable
class LightingFactorScore {
  const LightingFactorScore({
    required this.factor,
    required this.score,
    required this.weight,
    this.note,
  });

  final LightingFactor factor;
  final double score;       // [0..1]
  final double weight;      // normalized
  final String? note;

  double get contribution => score * weight;
}

/// A single issue found by the analyzer.
@immutable
class LightingIssue {
  const LightingIssue({
    required this.kind,
    required this.priority,
    required this.severity,
    required this.confidence,
    required this.rule,
  });

  final LightingIssueKind kind;
  final LightingPriority priority;
  final double severity;     // [0..1]
  final double confidence;   // [0..1]
  final String rule;
}

/// Full output of the LightingAnalyzer.
@immutable
class LightingScore {
  const LightingScore({
    required this.factors,
    required this.issues,
    required this.overallScore,
    required this.exposureState,
    required this.lightDirection,
    required this.lightType,
    required this.colorTemp,
    required this.shadowStatus,
    required this.avgLuminance,
    required this.timestamp,
    this.goldenHourActive = false,
    this.blueHourActive = false,
  });

  final List<LightingFactorScore> factors;
  final List<LightingIssue> issues;
  final double overallScore;
  final ExposureState exposureState;
  final LightSourceDirection lightDirection;
  final LightSourceType lightType;
  final ColorTemperatureCategory colorTemp;
  final ShadowStatus shadowStatus;
  final double avgLuminance; // 0..255
  final int timestamp;
  final bool goldenHourActive;
  final bool blueHourActive;

  bool get isAcceptable =>
      issues.every((i) => i.priority == LightingPriority.low ||
                         i.priority == LightingPriority.affirmation);

  bool get isLowLight => exposureState == ExposureState.severelyUnderexposed ||
      exposureState == ExposureState.underexposed;
}

/// A recommendation ready for the overlay.
@immutable
class LightingRecommendation {
  const LightingRecommendation({
    required this.type,
    required this.priority,
    required this.confidence,
    required this.rule,
    this.shortText,
    this.longText,
  });

  final LightingRecommendationType type;
  final LightingPriority priority;
  final double confidence;
  final String rule;
  final String? shortText;
  final String? longText;

  static const LightingRecommendation empty = LightingRecommendation(
    type: LightingRecommendationType.greatLighting,
    priority: LightingPriority.affirmation,
    confidence: 0,
    rule: 'noop',
    shortText: 'Lighting looks great',
  );
}

/// User-facing copy for each recommendation type.
const Map<LightingRecommendationType, (String, String)>
    lightingRecommendationCopy = {
  LightingRecommendationType.stepIntoLight: (
    'Step into the light',
    'Move toward a brighter area for a clearer photo.',
  ),
  LightingRecommendationType.moveAwayFromLight: (
    'Move back from the light',
    'You\'re too close to a strong light source.',
  ),
  LightingRecommendationType.reduceBacklight: (
    'Reduce backlight',
    'The light behind you is too strong — turn around or move.',
  ),
  LightingRecommendationType.findSofterLight: (
    'Find softer light',
    'Harsh shadows — try shaded or diffused lighting.',
  ),
  LightingRecommendationType.turnTowardWindow: (
    'Turn toward the window',
    'Face the window for even, natural light.',
  ),
  LightingRecommendationType.turnOnFlash: (
    'Try the flash',
    'It\'s quite dark — the flash can help here.',
  ),
  LightingRecommendationType.useGoldenHour: (
    'Golden hour — perfect light',
    'This warm, low-angle light is ideal for portraits.',
  ),
  LightingRecommendationType.waitForBlueHour: (
    'Blue hour approaching',
    'Soft blue light is coming — wait a few minutes for magical tone.',
  ),
  LightingRecommendationType.avoidDirectSun: (
    'Avoid direct sun',
    'Move to open shade for softer, more flattering light.',
  ),
  LightingRecommendationType.moveOutOfShadow: (
    'Move out of the shadow',
    'Step into the light for a brighter photo.',
  ),
  LightingRecommendationType.greatLighting: (
    'Great lighting',
    'The light is balanced and flattering — ready to capture.',
  ),
};
