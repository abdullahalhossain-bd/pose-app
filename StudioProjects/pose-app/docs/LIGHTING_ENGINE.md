# Lighting Intelligence & Computational Photography Foundation — Day 13

> The AI now understands *whether the lighting is good* — before the
> shutter is pressed. Apple Camera + Adobe Lightroom-inspired
> behavior: short, natural, actionable guidance.

## Module layout

```
lib/features/lighting/
├── config/
│   └── lighting_config.dart                  # 30+ thresholds + weights + golden hour offsets
├── domain/
│   ├── entities/
│   │   └── lighting_score.dart               # LightingScore + FactorScore + Issue + Recommendation + copy dict
│   └── enums/
│       └── lighting_enums.dart               # Factor, ExposureState, LightSourceDirection, LightSourceType, ColorTemp, ShadowStatus, IssueKind, Priority, RecommendationType
├── engine/
│   ├── lighting_analyzer.dart                # 6-factor analyzer + exposure classifier + light direction + color temp + golden hour
│   └── lighting_recommendation_engine.dart   # Top-1 issue picker + stability filter
├── overlays/
│   └── lighting_overlay_layer.dart           # Exposure meter + light direction + recommendation card + golden hour badge
├── presentation/
│   └── providers/
│       └── lighting_providers.dart           # Riverpod composition root
└── utils/
    └── lighting_geometry.dart                # Pure helpers: histogram, percentiles, brightness centroid, region variance, R/B ratio
```

## Pipeline data flow

```
Camera YUV420 frame (CameraImage)
       │
       ▼  CameraNotifier._handleCameraImage (Day 9)
   AiFrame { planes: [Y, U, V] }
       │
       ▼  GuidancePipelineStage.onCaptureScore hook
   pushLightingFrame(ref, luma, uPlane, vPlane, pose)
       │
       ▼  LightingAnalyzer.analyze
   ┌─── 1. Brightness         (avgLuminance)
   ├─── 2. Exposure           (avg + highlight/shadow clipping)
   ├─── 3. Contrast           (p90 - p10)
   ├─── 4. Dynamic range      (p90 - p10 spread)
   ├─── 5. Face lighting      (subject region avg vs scene avg)
   └─── 6. Shadow softness    (subject region variance)
       │
       ▼  + Light source direction (brightness centroid vs subject)
       ▼  + Light source type (golden hour / blue hour / daylight / indoor / low light)
       ▼  + Color temperature (R/B ratio → cool/neutral/warm)
       ▼  + Golden hour check (time-of-day heuristic)
   LightingScore
       │
       ▼  LightingRecommendationEngine.decide
   Top-1 issue → recommendation type
       │
       ▼  LightingStabilityFilter.process
   Stable recommendation (4-frame confirmation + 8-frame cooldown + 10/min rate limit)
       │
       ▼  Riverpod state (lightingScoreProvider, lightingRecommendationProvider)
       │
       ▼  Consumed by:
   ├── LightingOverlayLayer       (exposure meter + direction + card + golden hour badge)
   ├── AiDebugHud                 (Lit / Exp / Lum / Dir / Shd / Tmp / lRec rows)
   └── CaptureDecisionEngine      (lowLight state replaces Day 11 false stub)
```

## Lighting factors

| Factor           | Source                              | Weight | Issue when                                  |
| ---------------- | ----------------------------------- | ------ | ------------------------------------------- |
| Brightness       | avgLuminance                        | 0.25   | < 60 → under; > 200 → over                  |
| Exposure         | avg + clipping fractions            | 0.25   | severe under/over + clipping flags          |
| Contrast         | p90 - p10                           | 0.15   | < 40 → low; > 160 → high                    |
| Dynamic range    | p90 - p10                           | 0.10   | < 80 → narrow                              |
| Face lighting    | subject region avg vs scene avg     | 0.15   | delta < -30 → backlight; < 60 → poor face   |
| Shadow softness  | subject region variance             | 0.10   | var > 800 + dark → harsh                    |

All weights normalized at runtime.

## Exposure classification

```
avgLum < 30  OR shadowClip > 40%  → severelyUnderexposed (critical)
avgLum < 60                        → underexposed (high)
avgLum in [90, 180]                → balanced
avgLum > 200                       → overexposed (high)
avgLum > 230 OR highlightClip > 30% → severelyOverexposed (critical)
```

Plus highlight clipping (pixels > 245) and shadow clipping (pixels < 15) flags.

## Light source detection

Brightness centroid relative to subject bbox center:

| Direction | Condition                                          |
| --------- | -------------------------------------------------- |
| overhead  | centroid.cy < subject.cy - 0.15                     |
| leftSide  | (centroid.cx - subject.cx) < -0.10                 |
| rightSide | (centroid.cx - subject.cx) > 0.10                  |
| back      | subject significantly darker than centroid         |
| front     | centroid near center + subject well-lit            |
| ambient   | no clear direction                                  |

Light source type derived from direction + exposure + time:
- `lowLight` — severely underexposed or avg < 40
- `goldenHour` — within golden hour time window
- `blueHour` — within blue hour time window
- `naturalDaylight` — front light + avg > 100
- `artificialIndoor` — avg < 80
- `unknown` — fallback

## Color temperature

R/B ratio from YUV chroma planes (V ≈ R-Y, U ≈ B-Y):
- R/B < 0.85 → cool
- R/B > 1.20 → warm
- otherwise → neutral

Used only for guidance — no white balance correction.

## Golden hour & blue hour

Time-of-day heuristic (Day 14+ plugs in real GPS + sun position):
- Golden hour: 60 min before to 30 min after sunset (default 18:30)
- Blue hour: 90 to 60 min before sunset

When golden hour is active and no issues, the engine emits
`useGoldenHour` as a positive affirmation.

## Smart guidance

Same pattern as Day 10/12:
1. Pick highest-priority issue
2. Apply confidence gate (suppress if < 0.55)
3. If no issues → affirmation ("Great lighting")
4. Stability filter: 4-frame confirmation + 8-frame cooldown + 10/min rate limit

11 recommendation types → user-facing copy in `lightingRecommendationCopy` map (i18n-ready).

Edge cases:
- Severe underexposure → "Step into the light" (overrides normal issue picker)
- Golden hour active + no issues → "Golden hour — perfect light" affirmation

## Integration with capture engine (Day 11)

`GuidancePipelineStage.onCaptureScore` now:
1. Pushes luma + chroma to `pushLightingFrame()` (computes LightingScore)
2. Pulls `lightingScoreProvider` and uses `isLowLight` for the capture engine's `lowLight` parameter (replaces Day 11 hardcoded `false` stub)
3. When `lowLight = true` + `suppressInLowLight = true`, the capture engine suppresses auto capture

## Integration with composition engine (Day 12)

`pushPosesToComposition` now receives real luma (currently null — Day 14 wires the actual camera stream). When luma is present, the composition engine's horizon + symmetry + negative space factors use real data instead of neutral fallbacks.

## Performance

- `LightingAnalyzer.analyze` is O(samples) ≈ <2 ms per frame on mid-range Android
- Sampling stride = 4 → 1/16th of pixels processed
- `LightingGeometry.brightnessCentroid` uses stride = 8 for further speedup
- All overlays are pure painters; no widget rebuilds except small cards
- Histogram + percentile + clipping all in single pass where possible

## Edge cases

| Case                | Handling                                                |
| ------------------- | ------------------------------------------------------- |
| Night scenes        | severelyUnderexposed → "Step into the light"            |
| Sunset/sunrise      | Golden hour detection → positive affirmation            |
| Indoor low light    | lowLight → capture suppressed + "Step into the light"   |
| Strong sunlight     | highContrast → "Avoid direct sun"                       |
| Flash enabled       | (Day 14 — flash state integration)                      |
| Mixed lighting      | (Day 14 — ML white balance classifier)                  |
| Colored lights      | Color temperature detected → informational only          |
| Extreme contrast    | highContrast + narrowDynamicRange → "Find softer light" |
| No luma available   | All metrics fall back to neutral (0.5 score)             |

## Day 14 preparation

Day 14 (MVP Integration, QA, Performance Optimization & Closed Alpha Readiness) will:

1. **Wire real luma forwarding** from `CameraNotifier._handleCameraImage` to the guidance stage's `onCaptureScore` hook — currently uses synthetic null luma. This is the single biggest Day 14 task.
2. **Face mesh integration** — plug ML Kit Face Detection into the face/eyes stubs in the capture pipeline so `faceVisible` and `eyesOpen` become real signals.
3. **GPS + sun position** — replace time-of-day golden hour heuristic with real sun elevation calculation.
4. **Performance pass** — profile on mid-range Android, tune sampleStride + histogramBuckets for 30 FPS target.
5. **QA + closed alpha readiness** — fix any crashes, add error boundaries, write integration tests.
6. **Documentation consolidation** — single README pointing to all 13 day docs.

All additive — lighting engine, capture engine, state machines unchanged.
