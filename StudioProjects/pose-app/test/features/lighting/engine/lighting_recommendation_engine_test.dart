import 'package:ai_visual_director/features/lighting/config/lighting_config.dart';
import 'package:ai_visual_director/features/lighting/domain/entities/lighting_score.dart';
import 'package:ai_visual_director/features/lighting/domain/enums/lighting_enums.dart';
import 'package:ai_visual_director/features/lighting/engine/lighting_analyzer.dart';
import 'package:ai_visual_director/features/lighting/engine/lighting_recommendation_engine.dart';
import 'package:flutter_test/flutter_test.dart';

LightingScore _score({
  List<LightingIssue> issues = const [],
  double overall = 0.9,
  ExposureState exposure = ExposureState.balanced,
  bool goldenHour = false,
}) {
  return LightingScore(
    factors: const [],
    issues: issues,
    overallScore: overall,
    exposureState: exposure,
    lightDirection: LightSourceDirection.front,
    lightType: LightSourceType.naturalDaylight,
    colorTemp: ColorTemperatureCategory.neutral,
    shadowStatus: ShadowStatus.none,
    avgLuminance: 128,
    timestamp: 0,
    goldenHourActive: goldenHour,
  );
}

void main() {
  late LightingRecommendationEngine engine;

  setUp(() => engine = LightingRecommendationEngine(
        config: const LightingConfig(),
        analyzer: LightingAnalyzer(const LightingConfig()),
      ));

  test('no issues + no golden hour → greatLighting affirmation', () {
    final r = engine.decide(_score());
    expect(r.type, LightingRecommendationType.greatLighting);
    expect(r.priority, LightingPriority.affirmation);
  });

  test('golden hour active → useGoldenHour affirmation', () {
    final r = engine.decide(_score(goldenHour: true));
    expect(r.type, LightingRecommendationType.useGoldenHour);
  });

  test('underexposed → stepIntoLight', () {
    final r = engine.decide(_score(
      exposure: ExposureState.underexposed,
      issues: [
        LightingIssue(
          kind: LightingIssueKind.underexposed,
          priority: LightingPriority.high,
          severity: 0.7,
          confidence: 0.85,
          rule: 'exposure_under',
        ),
      ],
    ));
    expect(r.type, LightingRecommendationType.stepIntoLight);
  });

  test('backlight issue → reduceBacklight', () {
    final r = engine.decide(_score(
      issues: [
        LightingIssue(
          kind: LightingIssueKind.backlight,
          priority: LightingPriority.high,
          severity: 0.7,
          confidence: 0.8,
          rule: 'face_backlit',
        ),
      ],
    ));
    expect(r.type, LightingRecommendationType.reduceBacklight);
  });

  test('harsh shadows → findSofterLight', () {
    final r = engine.decide(_score(
      issues: [
        LightingIssue(
          kind: LightingIssueKind.harshShadows,
          priority: LightingPriority.high,
          severity: 0.7,
          confidence: 0.75,
          rule: 'shadow_harsh',
        ),
      ],
    ));
    expect(r.type, LightingRecommendationType.findSofterLight);
  });

  test('low confidence → suppressed to affirmation', () {
    final r = engine.decide(_score(
      issues: [
        LightingIssue(
          kind: LightingIssueKind.underexposed,
          priority: LightingPriority.high,
          severity: 0.7,
          confidence: 0.3, // below 0.55 threshold
          rule: 'test',
        ),
      ],
    ));
    expect(r.type, LightingRecommendationType.greatLighting);
  });

  test('high contrast → avoidDirectSun', () {
    final r = engine.decide(_score(
      issues: [
        LightingIssue(
          kind: LightingIssueKind.highContrast,
          priority: LightingPriority.medium,
          severity: 0.5,
          confidence: 0.7,
          rule: 'contrast_high',
        ),
      ],
    ));
    expect(r.type, LightingRecommendationType.avoidDirectSun);
  });
}
