import 'package:flutter/foundation.dart';

import '../enums/composition_enums.dart';

/// A recommendation ready for the overlay. Same pattern as Day 10's
/// GuidanceSignal so the UI layer can compose them.
@immutable
class CompositionRecommendation {
  const CompositionRecommendation({
    required this.type,
    required this.priority,
    required this.confidence,
    required this.rule,
    this.shortText,
    this.longText,
  });

  final CompositionRecommendationType type;
  final CompositionPriority priority;
  final double confidence;
  final String rule;
  final String? shortText;
  final String? longText;

  static const CompositionRecommendation empty = CompositionRecommendation(
    type: CompositionRecommendationType.greatComposition,
    priority: CompositionPriority.affirmation,
    confidence: 0,
    rule: 'noop',
    shortText: 'Composition looks great',
  );
}

/// User-facing copy for each recommendation type. Centralized so
/// i18n (Day 14) replaces this with translations.
const Map<CompositionRecommendationType, (String, String)>
    recommendationCopy = {
  CompositionRecommendationType.moveLeft: (
    'Move a little left',
    'Shift left to improve framing.',
  ),
  CompositionRecommendationType.moveRight: (
    'Move a little right',
    'Shift right to improve framing.',
  ),
  CompositionRecommendationType.moveUp: (
    'Raise the camera',
    'Lift the camera slightly.',
  ),
  CompositionRecommendationType.moveDown: (
    'Lower the camera',
    'Drop the camera slightly.',
  ),
  CompositionRecommendationType.centerSubject: (
    'Center the subject',
    'Move the subject to the center of the frame.',
  ),
  CompositionRecommendationType.placeOnThirds: (
    'Place on thirds',
    'Position the subject on a rule-of-thirds intersection.',
  ),
  CompositionRecommendationType.straightenHorizon: (
    'Straighten the horizon',
    'Level the camera — the horizon is tilted.',
  ),
  CompositionRecommendationType.raiseCamera: (
    'Raise the camera',
    'Lift the camera to add headroom.',
  ),
  CompositionRecommendationType.lowerCamera: (
    'Lower the camera',
    'Drop the camera to reduce headroom.',
  ),
  CompositionRecommendationType.stepBack: (
    'Step back',
    'Move back — the subject is too close.',
  ),
  CompositionRecommendationType.stepCloser: (
    'Step closer',
    'Move closer — the subject is too far.',
  ),
  CompositionRecommendationType.fillFrame: (
    'Fill the frame',
    'Get closer so the subject fills more of the frame.',
  ),
  CompositionRecommendationType.openUpSpace: (
    'Open up space',
    'Add breathing room around the subject.',
  ),
  CompositionRecommendationType.greatComposition: (
    'Great composition',
    'Your framing looks balanced — ready to capture.',
  ),
};
