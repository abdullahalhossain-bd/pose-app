# AI Pose Guidance Engine — Day 10

> Transforms Day 9's raw pose landmarks into calm, professional
> photography coaching. The first AI feature users experience.

## Module layout

```
lib/features/guidance/
├── config/
│   └── guidance_config.dart         # All thresholds + UX tunables
├── domain/
│   ├── entities/
│   │   └── pose_quality_result.dart # PoseMetric, PoseIssue, PoseQualityResult + issue→instruction dictionary
│   └── enums/
│       └── guidance_enums.dart      # GuidanceSignal, Priority, Status, Instruction, Direction
├── engine/
│   ├── pose_quality_scorer.dart     # Geometry-based pose analyzer (head/shoulders/hips/arms/legs/framing)
│   ├── guidance_engine.dart         # Pick top-1 instruction from issues
│   ├── guidance_stability_filter.dart # N-frame confirmation + cooldown + rate limit
│   └── guidance_pipeline_stage.dart # Wires engine + filter + feedback services
├── services/
│   └── guidance_feedback_services.dart # Audio + Haptic interfaces + stubs
├── overlays/
│   ├── guidance_painters.dart       # ArrowPainter + TargetRingPainter
│   └── guidance_overlay_layer.dart  # Composite overlay: badge + text + arrow + meter
├── utils/
│   └── pose_geometry.dart           # Pure geometry helpers (angles, distances, tilts)
└── presentation/
    └── providers/
        └── guidance_providers.dart  # Riverpod composition root
```

## Decision flow

```
Smoothed PoseSample (from Day 9 pose stage)
       │
       ▼  PoseQualityScorer.evaluate
   List<PoseMetric>  (head_tilt, shoulder_tilt, hip_tilt, arm_angle, stance_ratio, ...)
   List<PoseIssue>   (sorted by priority → severity)
       │
       ▼  GuidanceEngine.decide
   GuidanceSignal    (single candidate instruction)
       │
       ▼  GuidanceStabilityFilter.process
   GuidanceSignal    (stable, displayed signal)
       │
       ▼  Riverpod state (guidanceSignalProvider)
   GuidanceOverlayLayer + AiDebugHud
       │
       ▼  (when signal changes)
   GuidanceAudioService.speak + GuidanceHapticService.onNewSignal
```

## Pose evaluation logic

Every metric is computed via pure geometry in `pose_geometry.dart`:

| Area        | Metric                          | Issue when                                         |
| ----------- | ------------------------------- | -------------------------------------------------- |
| Head        | `head_tilt_deg`                 | \|tilt\| > 12° → `headTiltedLeft` / `headTiltedRight` |
| Head        | `chin_offset` (nose vs shoulders) | < 0.06 → `chinTooLow` · > 0.25 → `chinTooHigh`     |
| Shoulders   | `shoulder_tilt_deg`             | \|tilt\| > 8° → `shouldersTilted`                    |
| Shoulders   | `shoulder_width / hip_width`    | < 0.55 → `bodyRotatedLeft` / `bodyRotatedRight`     |
| Shoulders   | visibility asymmetry            | \|Δlikelihood\| > 0.35 → body rotated (fallback)    |
| Hips        | `hip_tilt_deg`                  | \|tilt\| > 10° → `hipsNotLevel`                      |
| Arms        | `left/right_elbow_angle`        | < 30° or > 170° → bad bend                          |
| Arms        | wrist-to-opposite-shoulder dist | < 0.15 → `armsCrossed`                              |
| Legs        | `stance_to_shoulder_ratio`      | < 0.15 → `stanceTooNarrow` · > 0.55 → `stanceTooWide` |
| Framing     | `subject_area_ratio`            | > 0.94 → `tooCloseToCamera` · < 0.35 → `tooFarFromCamera` |
| Framing     | `subject_off_center`            | \|Δcenter\| > 0.18 → `offCenterLeft` / `offCenterRight` |
| Framing     | `head_room` (nose Y)            | < 0.08 → `insufficientHeadRoom` · > 0.30 → `tooMuchHeadRoom` |

Every threshold lives in `GuidanceConfig` — none hardcoded.

## Priority + UX principles

**Priority bands** (single instruction shown at a time):

1. `critical` — must fix before capture (e.g. too close to camera)
2. `high` — significant quality impact (e.g. shoulders tilted, chin too low)
3. `medium` — worth fixing (e.g. off-center, hips not level)
4. `low` — nice-to-have polish (e.g. stance width, headroom too much)
5. `affirmation` — pose is good ("Looks great — hold still")

**Confidence gate**: if evaluation confidence < `minAggregateConfidence`
(default 0.55) OR reliable landmark count < `minLandmarksForGuidance`
(default 11), the engine suppresses strong instructions and shows
"Hold still" instead.

**Stability filter** prevents flickering:
- `confirmationFrames` (default 5, ≈300ms @ 15 FPS): a new instruction
  must be the top candidate for N consecutive frames before it's
  promoted.
- `cooldownFrames` (default 8, ≈530ms): after a switch, no new switch
  for N frames.
- `maxInstructionPerMinute` (default 30): hard rate limit so the
  engine can't chatter even if frames bounce.

**Copy style** (in `_instructionMap`):
- ❌ "Rotate body 12 degrees"
- ✅ "Turn a little to your left"
- Short, action-first, human-friendly, ≤ 5 words for `shortText`
- `longText` is a complete sentence for voice guidance

## Visual feedback

**Status badge** (top-right):
- Green ● + "G" = good
- Amber ▲ + "A" = needs improvement
- Red ■ + "R" = incorrect

Three redundant signals (color + shape + letter) so the badge is
legible for color-blind users and on bright outdoor screens.

**Guidance card** (bottom center):
- Direction icon (if applicable) + short text
- Bordered with status color
- Never blocks the subject's face (positioned below 2/3 height)

**Direction arrow** (subject position):
- Painted at `targetX, targetY` when the signal has a target
- 8 directions: up / down / left / right / diagonals

**Confidence meter** (top center):
- Subtle 100×4 px bar
- Fills proportional to `signal.confidence`

## Audio & haptic

`GuidanceAudioService` and `GuidanceHapticService` are interfaces;
Day 10 ships `StubGuidanceAudioService` and `StubGuidanceHapticService`.
Real TTS (flutter_tts) and vibration (`HapticFeedback.mediumImpact`)
land in Day 14 alongside user prefs UI.

Why stubs now? Because:
1. The architecture must be in place before users get to toggle audio
   in settings.
2. Tests can swap stubs without touching real plugins.
3. Day 14 won't change a single call site — just register a new
   provider override.

## Debug HUD

When `AiConfig.showDebugOverlay` is true, the HUD shows:

```
FPS: 15        ← pipeline throughput
Lat: 32ms      ← inference latency
Drop: 4.2%     ← dropped frame rate
LM: 17         ← reliable landmark count
Trk: TRK#1     ← current track ID
─────────────
Q: 78%         ← pose overall score
Cnf: 92%       ← evaluation confidence
Iss: 2         ← issue count
T: 1.4ms       ← guidance evaluation latency
Rul: chin_too_low  ← active rule
```

Hidden in production via `kReleaseMode` check.

## Extension points

### Add a new rule
1. Add a `PoseIssueKind` value.
2. Add the rule logic in `PoseQualityScorer._evaluate*`.
3. Add the user-facing copy in `_instructionMap`.
4. Done. Stability filter, overlay, debug HUD all auto-adapt.

### Personalize guidance (Day 14+)
Replace `GuidanceEngine` with one that loads per-user weights from
the future Pose DNA module. The `_instructionMap` becomes a
user-tunable dictionary; rule severities get personalization weights.

### Swap audio/haptic impls
Override `guidanceAudioServiceProvider` / `guidanceHapticServiceProvider`
in `main.dart` with concrete classes. Day 10's call sites are unchanged.

## Performance

- `PoseQualityScorer` is O(landmarks) per frame — ~17 metrics computed
  in <2 ms on a mid-range device.
- `GuidanceEngine.decide` is O(issues) — typically <5 issues.
- `GuidanceStabilityFilter` is O(1) per frame.
- Overlays are pure painters; no widget rebuilds on signal updates
  except the small guidance card.

## Day 11 preparation

Day 11 (Smart Auto Capture) will:

1. Add `CaptureDecisionEngine` that reads:
   - `guidanceSignalProvider` (current guidance)
   - `poseContextProvider` (edge cases)
   - `poseStateProvider` (PoseReady?)
2. Emit a `CaptureOpportunity` event when:
   - Pose state is `PoseReady`
   - No critical/high issues for N consecutive frames
   - Optional composition rule passes (rule of thirds, leading space)
3. Add a "Smart Capture" toggle in settings (off by default — user
   must opt in to auto-capture).
4. Surface a capture-countdown overlay (3..2..1) when the engine
   fires.

All additive — pose detection, tracking, smoothing, guidance are
unchanged.
