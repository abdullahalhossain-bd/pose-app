/// Lighting factors the engine scores.
enum LightingFactor {
  brightness,      // overall scene luminance
  exposure,        // under / over / balanced
  contrast,        // p90 - p10 spread
  dynamicRange,    // usable highlight-to-shadow range
  faceLighting,    // subject region brightness (proxy until face mesh)
  shadowSoftness,  // harsh vs soft shadow variance
}

/// Exposure classification. Drives the primary guidance.
enum ExposureState {
  severelyUnderexposed,
  underexposed,
  balanced,
  overexposed,
  severelyOverexposed,
}

/// Estimated dominant light source direction.
enum LightSourceDirection {
  front,       // light comes from camera side
  back,        // backlight — subject in shadow
  leftSide,
  rightSide,
  overhead,
  ambient,     // diffuse — no clear direction
  unknown,
}

/// Estimated light source type.
enum LightSourceType {
  naturalDaylight,
  goldenHour,
  blueHour,
  windowLight,
  artificialIndoor,
  mixedLighting,
  lowLight,
  unknown,
}

/// Color temperature category (NOT a Kelvin value — guidance only).
enum ColorTemperatureCategory {
  cool,    // blue-ish
  neutral,
  warm,    // orange-ish
}

/// Shadow quality on the subject.
enum ShadowStatus {
  none,
  soft,    // gentle gradient
  harsh,   // hard-edged dark patches
  racoonEyes,  // deep eye shadows (proxy)
}

/// Catalog of lighting issues the analyzer can detect.
enum LightingIssueKind {
  underexposed,
  overexposed,
  highlightClipping,
  shadowClipping,
  lowContrast,
  highContrast,
  narrowDynamicRange,
  backlight,
  harshShadows,
  poorFaceLighting,
  coolTint,
  warmTint,
}

/// Priority bands for lighting recommendations.
enum LightingPriority {
  critical, // severely bad exposure
  high,     // significant quality issue
  medium,   // worth fixing
  low,      // polish
  affirmation,
}

/// Recommendation types the engine can emit.
enum LightingRecommendationType {
  stepIntoLight,
  moveAwayFromLight,
  reduceBacklight,
  findSofterLight,
  turnTowardWindow,
  turnOnFlash,
  useGoldenHour,
  waitForBlueHour,
  avoidDirectSun,
  moveOutOfShadow,
  greatLighting,
}
