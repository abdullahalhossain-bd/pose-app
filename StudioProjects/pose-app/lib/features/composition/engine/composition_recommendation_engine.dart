import '../config/composition_config.dart';
import '../domain/entities/composition_recommendation.dart';
import '../domain/entities/composition_score.dart';
import '../domain/enums/composition_enums.dart';
import '../domain/enums/scene_type.dart';
import 'composition_scorer.dart';
import 'scene_classifier.dart';

/// একটি [CompositionScore] কে একটি একক [CompositionRecommendation]-এ রূপান্তর করে।
/// Day 10-এর GuidanceEngine-এর একই প্যাটার্ন:
/// 1. সর্বোচ্চ-অগ্রাধিকার সমস্যা বাছাই করুন
/// 2. কনফিডেন্স গেট প্রয়োগ করুন
/// 3. যদি কিছু না থাকে তবে নিশ্চিতকরণ দেখান
class CompositionRecommendationEngine {
  CompositionRecommendationEngine({
    required this.config,
    required this.scorer,
    required this.sceneClassifier,
  });

  final CompositionConfig config;
  final CompositionScorer scorer;
  final SceneClassifier sceneClassifier;

  /// একটি ফ্রেমের জন্য সম্পূর্ণ মূল্যায়ন (ডিবাগ HUD প্রকাশ করে)।
  CompositionScore evaluate({
    required dynamic pose,
    required dynamic luma,
    required int lumaWidth,
    required int lumaHeight,
  }) {
    // টাইপ-সেফ র‍্যাপার — কলার থেকে যেকোনো পোজ লিস্ট গ্রহণ করে।
    if (pose is List) {
      // স্কোরার একটি একক প্রাথমিক পোজ আশা করে।
      dynamic primary;
      if (pose.isEmpty) {
        primary = null;
      } else {
        primary = List.from(pose)
          ..sort((a, b) => (b.confidence as double).compareTo(a.confidence));
        primary = primary.first;
      }
      return scorer.evaluate(
        pose: primary,
        luma: luma,
        lumaWidth: lumaWidth,
        lumaHeight: lumaHeight,
      );
    }
    return scorer.evaluate(
      pose: pose,
      luma: luma,
      lumaWidth: lumaWidth,
      lumaHeight: lumaHeight,
    );
  }

  /// প্রদর্শনের জন্য একটি একক রেকমেন্ডেশন বাছাই করুন।
  CompositionRecommendation decide({
    required CompositionScore score,
    required SceneContext scene,
  }) {
    if (score.issues.isEmpty) {
      return _buildRecommendation(
        CompositionRecommendationType.greatComposition,
        CompositionPriority.affirmation,
        confidence: 0.9,
        rule: 'no_issues',
      );
    }

    // দৃশ্য-সচেতন পুনঃঅগ্রাধিকার: দৃশ্যের উপর ভিত্তি করে কিছু সমস্যা বুস্ট করুন।
    final adjusted = _applyScenePriority(score.issues, scene);
    final top = adjusted.first;

    // কনফিডেন্স গেট।
    if (top.confidence < config.minConfidenceToDisplay) {
      return _buildRecommendation(
        CompositionRecommendationType.greatComposition,
        CompositionPriority.affirmation,
        confidence: top.confidence,
        rule: 'low_confidence_suppress',
      );
    }

    final type = _issueToRecommendation(top.kind, scene);
    return _buildRecommendation(
      type,
      top.priority,
      confidence: top.confidence,
      rule: top.rule,
    );
  }

  List<CompositionIssue> _applyScenePriority(
      List<CompositionIssue> issues, SceneContext scene) {
    // দৃশ্য-নির্দিষ্ট পুনঃঅগ্রাধিকার বুস্ট।
    final boosted = issues.map((i) {
      var priority = i.priority;
      if (scene.prioritizesFace) {
        // পোর্ট্রেট/সেলফি: হেডরুম এবং সাবজেক্ট সাইজ বুস্ট করুন।
        if (i.kind == CompositionIssueKind.insufficientHeadroom ||
            i.kind == CompositionIssueKind.excessiveHeadroom ||
            i.kind == CompositionIssueKind.subjectTooSmall ||
            i.kind == CompositionIssueKind.subjectTooLarge) {
          priority = _escalate(priority);
        }
      }
      if (scene.prioritizesHorizon) {
        if (i.kind == CompositionIssueKind.horizonTiltedLeft ||
            i.kind == CompositionIssueKind.horizonTiltedRight) {
          priority = _escalate(priority);
        }
      }
      return CompositionIssue(
        kind: i.kind,
        priority: priority,
        severity: i.severity,
        confidence: i.confidence,
        rule: i.rule,
      );
    }).toList();

    boosted.sort((a, b) {
      final p = a.priority.index.compareTo(b.priority.index);
      if (p != 0) return p;
      return b.severity.compareTo(a.severity);
    });
    return boosted;
  }

  CompositionPriority _escalate(CompositionPriority p) {
    return p.index == 0 ? p : CompositionPriority.values[p.index - 1];
  }

  CompositionRecommendationType _issueToRecommendation(
      CompositionIssueKind kind, SceneContext scene) {
    return switch (kind) {
      CompositionIssueKind.subjectOffCenterLeft =>
        CompositionRecommendationType.moveRight,
      CompositionIssueKind.subjectOffCenterRight =>
        CompositionRecommendationType.moveLeft,
      CompositionIssueKind.subjectTooHigh =>
        CompositionRecommendationType.moveDown,
      CompositionIssueKind.subjectTooLow =>
        CompositionRecommendationType.moveUp,
      CompositionIssueKind.notOnThirdsIntersection =>
        CompositionRecommendationType.placeOnThirds,
      CompositionIssueKind.asymmetricalBalance =>
        CompositionRecommendationType.centerSubject,
      CompositionIssueKind.horizonTiltedLeft ||
      CompositionIssueKind.horizonTiltedRight =>
        CompositionRecommendationType.straightenHorizon,
      CompositionIssueKind.horizonTooHigh =>
        CompositionRecommendationType.moveDown,
      CompositionIssueKind.horizonTooLow =>
        CompositionRecommendationType.moveUp,
      CompositionIssueKind.insufficientHeadroom =>
        CompositionRecommendationType.raiseCamera,
      CompositionIssueKind.excessiveHeadroom =>
        CompositionRecommendationType.lowerCamera,
      CompositionIssueKind.croppedFeet =>
        CompositionRecommendationType.stepBack,
      CompositionIssueKind.subjectTooSmall =>
        scene.isFrontCamera
            ? CompositionRecommendationType.fillFrame
            : CompositionRecommendationType.stepCloser,
      CompositionIssueKind.subjectTooLarge =>
        CompositionRecommendationType.stepBack,
      CompositionIssueKind.tooCluttered =>
        CompositionRecommendationType.openUpSpace,
      CompositionIssueKind.tooMuchEmptySpace =>
        CompositionRecommendationType.fillFrame,
    };
  }

  CompositionRecommendation _buildRecommendation(
    CompositionRecommendationType type,
    CompositionPriority priority, {
    required double confidence,
    required String rule,
  }) {
    final copy = recommendationCopy[type]!;
    return CompositionRecommendation(
      type: type,
      priority: priority,
      confidence: confidence,
      rule: rule,
      shortText: copy.$1,
      longText: copy.$2,
    );
  }
}

/// রেকমেন্ডেশন ফ্লিকারিং রোধ করতে N-ফ্রেম কনফারমেশন + কুলডাউন।
/// Day 10-এর GuidanceStabilityFilter-এর প্যাটার্ন।
class CompositionStabilityFilter {
  CompositionStabilityFilter({
    required this.confirmationFrames,
    required this.cooldownFrames,
  });

  final int confirmationFrames;
  final int cooldownFrames;

  CompositionRecommendation _displayed = CompositionRecommendation.empty;
  CompositionRecommendation _candidate = CompositionRecommendation.empty;
  int _candidateCount = 0;
  int _framesSinceSwitch = 0;

  CompositionRecommendation process(CompositionRecommendation incoming) {
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
        _framesSinceSwitch >= cooldownFrames) {
      _displayed = _candidate;
      _framesSinceSwitch = 0;
    }
    return _displayed;
  }

  bool _isSame(CompositionRecommendation a, CompositionRecommendation b) =>
      a.type == b.type;

  CompositionRecommendation get current => _displayed;

  void reset() {
    _displayed = CompositionRecommendation.empty;
    _candidate = CompositionRecommendation.empty;
    _candidateCount = 0;
    _framesSinceSwitch = 0;
  }
}

// dart:collection import ছিল কিন্তু অব্যবহৃত — নীরবে সরানো হয়েছে।
