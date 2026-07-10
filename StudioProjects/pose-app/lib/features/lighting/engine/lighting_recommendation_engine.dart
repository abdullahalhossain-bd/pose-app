import '../config/lighting_config.dart';
import '../domain/entities/lighting_score.dart';
import '../domain/enums/lighting_enums.dart';
import 'lighting_analyzer.dart';

/// Converts a [LightingScore] into a single [LightingRecommendation]
/// for the UI. Same pattern as Day 10's GuidanceEngine:
/// 1. Pick the highest-priority issue
/// 2. Apply confidence gate
/// 3. If no issues → affirmation
class LightingRecommendationEngine {
  LightingRecommendationEngine({
    required this.config,
    required this.analyzer,
  });

  final LightingConfig config;
  final LightingAnalyzer analyzer;

  LightingRecommendation decide(LightingScore score) {
    // Golden hour is a strong positive — surface it even if no issues.
    if (score.goldenHourActive && score.issues.isEmpty) {
      return _build(
        LightingRecommendationType.useGoldenHour,
        LightingPriority.affirmation,
        confidence: 0.95,
        rule: 'golden_hour_active',
      );
    }

    if (score.issues.isEmpty) {
      return _build(
        LightingRecommendationType.greatLighting,
        LightingPriority.affirmation,
        confidence: 0.9,
        rule: 'no_issues',
      );
    }

    final top = score.issues.first;

    // Confidence gate.
    if (top.confidence < config.minConfidenceToDisplay) {
      return _build(
        LightingRecommendationType.greatLighting,
        LightingPriority.affirmation,
        confidence: top.confidence,
        rule: 'low_confidence_suppress',
      );
    }

    // Special-case low light → suggest flash.
    if (score.exposureState == ExposureState.severelyUnderexposed ||
        score.exposureState == ExposureState.underexposed) {
      return _build(
        LightingRecommendationType.stepIntoLight,
        top.priority,
        confidence: top.confidence,
        rule: 'low_light_step_into',
      );
    }

    final type = _issueToRecommendation(top.kind, score);
    return _build(
      type,
      top.priority,
      confidence: top.confidence,
      rule: top.rule,
    );
  }

  LightingRecommendationType _issueToRecommendation(
    LightingIssueKind kind,
    LightingScore score,
  ) {
    return switch (kind) {
      LightingIssueKind.underexposed =>
        LightingRecommendationType.stepIntoLight,
      LightingIssueKind.overexposed =>
        LightingRecommendationType.moveAwayFromLight,
      LightingIssueKind.highlightClipping =>
        LightingRecommendationType.moveAwayFromLight,
      LightingIssueKind.shadowClipping =>
        LightingRecommendationType.stepIntoLight,
      LightingIssueKind.lowContrast =>
        LightingRecommendationType.findSofterLight,
      LightingIssueKind.highContrast =>
        LightingRecommendationType.avoidDirectSun,
      LightingIssueKind.narrowDynamicRange =>
        LightingRecommendationType.findSofterLight,
      LightingIssueKind.backlight =>
        LightingRecommendationType.reduceBacklight,
      LightingIssueKind.harshShadows =>
        LightingRecommendationType.findSofterLight,
      LightingIssueKind.poorFaceLighting =>
        LightingRecommendationType.turnTowardWindow,
      LightingIssueKind.coolTint =>
        LightingRecommendationType.greatLighting, // informational only
      LightingIssueKind.warmTint =>
        LightingRecommendationType.greatLighting, // informational only
    };
  }

  LightingRecommendation _build(
    LightingRecommendationType type,
    LightingPriority priority, {
    required double confidence,
    required String rule,
  }) {
    final copy = lightingRecommendationCopy[type]!;
    return LightingRecommendation(
      type: type,
      priority: priority,
      confidence: confidence,
      rule: rule,
      shortText: copy.$1,
      longText: copy.$2,
    );
  }
}

/// N-frame confirmation + cooldown stability filter. Same pattern
/// as Day 10's GuidanceStabilityFilter.
class LightingStabilityFilter {
  LightingStabilityFilter({
    required this.confirmationFrames,
    required this.cooldownFrames,
    required this.maxPerMinute,
  });

  final int confirmationFrames;
  final int cooldownFrames;
  final int maxPerMinute;

  LightingRecommendation _displayed = LightingRecommendation.empty;
  LightingRecommendation _candidate = LightingRecommendation.empty;
  int _candidateCount = 0;
  int _framesSinceSwitch = 0;
  final List<int> _emitHistory = [];

  LightingRecommendation process(LightingRecommendation incoming,
      {int? frameId}) {
    final fid = frameId ?? 0;

    if (_isSame(incoming, _candidate)) {
      _candidateCount++;
    } else {
      _candidate = incoming;
      _candidateCount = 1;
    }
    _framesSinceSwitch++;

    final sameAsDisplayed = _isSame(_candidate, _displayed);
    if (!sameAsDisplayed &&
        _candidateCount >= confirmationFrames &&
        _framesSinceSwitch >= cooldownFrames &&
        _withinRateLimit(fid)) {
      _displayed = _candidate;
      _framesSinceSwitch = 0;
      _emitHistory.add(fid);
      _pruneHistory(fid);
    }
    return _displayed;
  }

  bool _isSame(LightingRecommendation a, LightingRecommendation b) =>
      a.type == b.type;

  bool _withinRateLimit(int now) {
    _pruneHistory(now);
    return _emitHistory.length < maxPerMinute;
  }

  void _pruneHistory(int now) {
    const sixtySecondsFrames = 900;
    _emitHistory.removeWhere((t) => now - t > sixtySecondsFrames);
  }

  LightingRecommendation get current => _displayed;

  void reset() {
    _displayed = LightingRecommendation.empty;
    _candidate = LightingRecommendation.empty;
    _candidateCount = 0;
    _framesSinceSwitch = 0;
    _emitHistory.clear();
  }
}
