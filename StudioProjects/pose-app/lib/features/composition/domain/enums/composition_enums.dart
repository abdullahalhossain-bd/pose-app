/// Composition factors the engine scores.
enum CompositionFactor {
  subjectPlacement,  // subject position relative to ideal zones
  ruleOfThirds,      // proximity to thirds intersections
  symmetry,          // left/right visual weight balance
  horizon,           // horizon tilt + position
  headroom,          // space above subject's head
  subjectSize,       // subject occupies ideal frame fraction
  negativeSpace,     // breathing room around subject
}

/// Catalog of composition issues the scorer can detect. Each maps
/// to a user-facing recommendation.
enum CompositionIssueKind {
  // Subject placement
  subjectOffCenterLeft,
  subjectOffCenterRight,
  subjectTooHigh,
  subjectTooLow,
  // Rule of thirds
  notOnThirdsIntersection,
  // Symmetry
  asymmetricalBalance,
  // Horizon
  horizonTiltedLeft,
  horizonTiltedRight,
  horizonTooHigh,
  horizonTooLow,
  // Headroom / footroom
  insufficientHeadroom,
  excessiveHeadroom,
  croppedFeet,
  // Subject size
  subjectTooSmall,
  subjectTooLarge,
  // Negative space
  tooCluttered,
  tooMuchEmptySpace,
}

/// Priority bands for composition recommendations. Lower priority
/// items yield to higher when multiple issues are present.
enum CompositionPriority {
  critical, // cropping issue — fix before capture
  high,     // significant framing issue
  medium,   // improvement worth making
  low,      // polish
  affirmation,
}

/// Recommendation the engine surfaces to the UI.
enum CompositionRecommendationType {
  moveLeft,
  moveRight,
  moveUp,
  moveDown,
  centerSubject,
  placeOnThirds,
  straightenHorizon,
  raiseCamera,
  lowerCamera,
  stepBack,
  stepCloser,
  fillFrame,
  openUpSpace,
  greatComposition,
}
