# Composition Intelligence & Scene Understanding — Day 12

> The AI now understands *whether the current framing creates a
> beautiful photograph* — not just whether a person is in frame.

## Module layout

```
lib/features/composition/
├── config/
│   └── composition_config.dart              # Weights + thresholds + scene rules
├── domain/
│   ├── entities/
│   │   ├── composition_score.dart           # CompositionScore + FactorScore + Issue
│   │   └── composition_recommendation.dart  # Recommendation + copy dictionary
│   └── enums/
│       ├── composition_enums.dart           # Factor, IssueKind, Priority, RecommendationType
│       └── scene_type.dart                  # SceneType + SceneContext
├── engine/
│   ├── composition_scorer.dart              # 7-factor analyzer (thirds/symmetry/horizon/...)
│   ├── scene_classifier.dart                # Heuristic scene derivation
│   ├── composition_recommendation_engine.dart # Top-1 issue picker + stability filter
│   └── (composition_pipeline_stage embedded in guidance stage)
├── overlays/
│   ├── composition_grid_painter.dart        # 5 grid types: thirds/golden/center/horizon/safe
│   └── composition_overlay_layer.dart       # Grid + recommendation card + scene tag + horizon badge
├── storage/
│   └── composition_prefs.dart               # Grid type + hints visibility
├── presentation/
│   └── providers/
│       └── composition_providers.dart       # Riverpod composition root
└── utils/
    └── composition_geometry.dart            # Pure geometry (thirds distance, symmetry, horizon, neg space)
```

## Pipeline data flow

```
Smoothed PoseSample (from Day 9 pose stage)
       │
       ▼  GuidancePipelineStage.onCaptureScore hook (Day 11)
   pushPosesToComposition(ref, poses, luma, ...)
       │
       ▼  CompositionRecommendationEngine.evaluate
   CompositionScorer.evaluate
       │
       ├── 1. Subject placement    (center offset from 0.5, 0.5)
       ├── 2. Rule of thirds       (distance to nearest intersection)
       ├── 3. Symmetry             (left/right luminance asymmetry)
       ├── 4. Horizon              (tilt angle via edge gradient)
       ├── 5. Headroom             (bbox.top distance)
       ├── 6. Subject size         (bbox.area)
       └── 7. Negative space       (variance outside bbox)
       │
       ▼  Weighted sum → CompositionScore (overall + issues + horizonAngle)
   SceneClassifier.classify
       │
       ▼  SceneContext (portrait/selfie/couple/group/fullBody/landscape)
   CompositionRecommendationEngine.decide
       │
       ▼  Top-1 issue → recommendation type (scene-aware priority boost)
   CompositionStabilityFilter.process
       │
       ▼  Stable recommendation (4-frame confirmation + 6-frame cooldown)
   Riverpod state (compositionScoreProvider, sceneContextProvider, compositionRecommendationProvider)
       │
       ▼  Consumed by:
   ├── CompositionOverlayLayer     (grid + card + scene tag + horizon badge)
   ├── AiDebugHud                   (Comp / Scn / Hzn / Rec rows)
   └── CaptureDecisionEngine       (composition factor score replaces Day 11 stub)
```

## Composition factors

| Factor              | Source                              | Weight | Issue when                                  |
| ------------------- | ----------------------------------- | ------ | ------------------------------------------- |
| Subject placement   | bbox center offset from (0.5, 0.5)  | 0.25   | dx > 0.20 → off-center; dy > 0.20 → too high/low |
| Rule of thirds      | Distance to nearest thirds intersection | 0.20 | dist > 0.08 → not on thirds               |
| Symmetry            | \|leftAvg - rightAvg\| / total luminance | 0.15 | asymmetry > 0.10                          |
| Horizon             | Tilt angle from edge gradient       | 0.15   | \|tilt\| > 2.5° → tilted left/right         |
| Headroom            | bbox.top                            | 0.10   | < 0.08 → insufficient; > 0.30 → excessive  |
| Subject size        | bbox.area                           | 0.10   | < 0.10 → too small; > 0.85 → too large     |
| Negative space      | Low-variance cells outside bbox     | 0.05   | < 0.15 → cluttered; > 0.55 → too empty     |

All weights normalized at runtime — unbalanced configs still produce [0..1].

## Scene classification

Day 12 derives scene type heuristically:

| Scene      | Rule                                                      |
| ---------- | --------------------------------------------------------- |
| portrait   | 1 person, back camera, frame ratio > 0.50                |
| selfie     | 1 person, front camera, frame ratio > 0.45               |
| fullBody   | 1 person, bbox height > 0.75                              |
| couple     | 2 persons, center distance < 0.30 of frame width         |
| group      | 3+ persons                                                |
| landscape  | 0 persons (low confidence — Day 14 ML classifier refines)|
| indoor / outdoor / nature / city | (Day 14 ML image labeling plugs in here)      |

**Scene-aware priority boost**: portrait/selfie escalates headroom + subject size issues; landscape escalates horizon tilt; group escalates spacing issues (Day 14).

## Dynamic grid overlays

5 toggleable grid types via `CompositionPrefs.enabledGrid`:

1. **Rule of thirds** — 2 vertical + 2 horizontal lines + 4 intersection dots
2. **Golden ratio** — lines at φ⁻¹ ≈ 0.618 (more aesthetically pleasing than thirds)
3. **Center** — crosshair + circle for centered compositions
4. **Horizon** — reference horizontal line + red tilted line when horizon detected off-level
5. **Safe margins** — 8% inset rectangle (broadcast safe area)

All painters are pure `CustomPainter` — zero widget rebuilds on detection updates.

## Recommendation engine

Same pattern as Day 10's GuidanceEngine:

1. Pick highest-priority issue (after scene-aware boosting)
2. Apply confidence gate (suppress if < 0.5)
3. If no issues → affirmation ("Composition looks great")
4. Stability filter: 4-frame confirmation + 6-frame cooldown prevents flickering

13 recommendation types → user-facing copy in `recommendationCopy` map (i18n-ready for Day 14).

## Integration with Day 11 capture engine

`GuidancePipelineStage.onCaptureScore` now:
1. Pushes poses to `pushPosesToComposition()` (computes score + scene + recommendation)
2. Reads `compositionScoreProvider` and forwards `overallScore` as `compositionOverride` to `CaptureDecisionEngine.evaluate()`
3. The capture engine uses this real score instead of the Day 11 `_compositionStub`

This is the only integration point — capture engine, state machine, countdown all unchanged.

## Performance

- `CompositionScorer.evaluate` is O(factors + 64 pixel samples) ≈ <2 ms per frame
- `SceneClassifier.classify` is O(persons) ≈ <0.1 ms
- `CompositionGeometry.detectHorizonTiltDeg` samples every 4th pixel — O(width × height / 16)
- All overlays are pure painters; no widget rebuilds except the small recommendation card

## Edge cases

| Case                | Handling                                                |
| ------------------- | ------------------------------------------------------- |
| Multiple people     | SceneType.group; primary pose used for composition      |
| Extreme lighting    | Symmetry/negative-space metrics degrade gracefully      |
| Rotated device      | Horizon angle still detected from luma gradient         |
| Fast camera movement| Stability filter (Day 11) suppresses capture           |
| Partial subject     | Cropped feet detected as critical issue                 |
| Crowded background  | Negative space < 0.15 → "too cluttered" recommendation  |
| No luma available   | Composition factors fall back to pose-only signals      |

## Day 13 preparation

Day 13 (Lighting Intelligence & Exposure Guidance) will:

1. Add `LightingAnalyzer` that reads the luma plane for:
   - Average scene luminance (lux estimate)
   - Dynamic range (histogram spread)
   - Backlight detection (subject darker than background)
   - Color temperature estimate (R/B ratio from RGB planes)
2. Plug real luma forwarding from `CameraNotifier._handleCameraImage` to the composition + lighting engines (currently null).
3. Add `LightingGuidanceEngine` that emits hints like:
   - "Step into the light"
   - "Avoid backlight — move to the side"
   - "Turn on the flash for better exposure"
4. Replace `lowLight = false` stub in the capture pipeline with real lighting state.
5. Add lighting factor to `CaptureConfig` weights (optional — may stay as a suppress reason only).

All additive — composition engine, capture engine, state machines unchanged.
