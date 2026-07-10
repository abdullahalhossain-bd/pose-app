# Smart Auto Capture & Capture Decision Engine — Day 11

> The most magical part of the MVP. Decides "when is this photo good
> enough to capture?" using a weighted multi-factor score.

## Module layout

```
lib/features/capture/
├── config/
│   └── capture_config.dart           # Weights + thresholds + countdown + sensitivity presets
├── domain/
│   ├── entities/
│   │   ├── capture_score.dart        # CaptureScore + FactorScore
│   │   └── capture_attempt.dart      # CaptureAttempt + sealed CaptureState tree
│   └── enums/
│       └── capture_enums.dart        # CaptureFactor, CaptureSuppressReason, CaptureFailureReason
├── engine/
│   ├── capture_decision_engine.dart  # Weighted multi-factor scoring + EMA + suppress logic
│   ├── stability_detector.dart       # Subject motion + camera shake detection
│   └── countdown_coordinator.dart    # Tick-based countdown + auto-cancel
├── storage/
│   └── capture_prefs.dart            # Versioned SharedPreferences schema
├── presentation/
│   ├── providers/
│   │   └── capture_providers.dart    # Riverpod composition root + CaptureStateController
│   ├── overlays/
│   │   └── capture_overlay_layer.dart # Countdown ring + result card + suppress banner
│   └── widgets/
│       └── capture_settings_section.dart # Embedded in main Settings screen
└── services/                          # (Day 14+ plug real audio/haptic here)
```

## Decision flow

```
PoseSample (from Day 9 pose stage)
       │
       ▼  GuidancePipelineStage.process
   PoseQualityResult + GuidanceSignal
       │
       ▼  onCaptureScore hook (Day 11)
   CaptureDecisionEngine.evaluate
       │
       ├── 1. Pose factor        (from PoseQualityResult.overallScore - penalties)
       ├── 2. Stability factor   (StabilityDetector: pose delta + camera shake)
       ├── 3. Face factor        (faceVisible + eyesOpen — stubbed Day 11)
       ├── 4. Composition factor (stubbed Day 11; Day 12 replaces)
       ├── 5. Framing factor     (subject area in [0.20, 0.60] = perfect)
       ├── 6. Confidence factor  (pose.confidence)
       │
       ▼  Weighted sum → EMA smoothing
   rawScore → _emaScore
       │
       ▼  Suppress checks (priority order)
   multiplePeople → noFace → closedEyes → lowLight → cameraShake → subjectMoving → userExited → lowConfidence
       │
       ▼  Stable-for-N counter
   if no suppress AND emaScore ≥ threshold: _stableForFrames++
   else: _stableForFrames = 0
       │
       ▼  CaptureScore (returned to CaptureStateController)
   Riverpod state update
       │
       ▼  State machine transition
   Idle → Searching → Ready → Countdown → Capturing → Reviewing
```

## Multi-factor scoring

| Factor       | Source                          | Weight (default) | Notes                                  |
| ------------ | ------------------------------- | ---------------- | -------------------------------------- |
| Pose         | PoseQualityResult + penalties   | 0.30             | Critical issues cost 0.50, high 0.25, medium 0.10, low 0.03 |
| Stability    | StabilityDetector               | 0.25             | Combines subject motion + camera shake, averaged over 10-frame window |
| Face         | (stubbed Day 11)                | 0.15             | Day 12+ plugs real face detection     |
| Composition  | (stubbed Day 11)                | 0.15             | Day 12 replaces with rule-of-thirds + leading space |
| Framing      | Bounding box area + position    | 0.10             | Ideal: subject occupies 20–60% of frame |
| Confidence   | Pose detection confidence       | 0.05             | ML Kit's per-detection score           |

All weights live in `CaptureConfig.normalizedWeights` — engine normalizes
so unbalanced configs still produce scores in [0..1].

### EMA smoothing

```
_emaScore = α × rawScore + (1 - α) × _emaScore
```

- `α = 0.35` (default) — moderate smoothing, ~3-frame effective window
- `α = 0.25` (conservative) — smoother, less reactive
- `α = 0.45` (eager) — more reactive, captures faster

### Stable-for-N check

Even with a high EMA, the engine requires `stableFrameRequirement`
consecutive frames above threshold before declaring "ready". Default
is 8 frames (~530ms @ 15 FPS) — short enough to feel responsive,
long enough to filter single-frame noise.

## Stability detection

`StabilityDetector` combines two signals:

1. **Subject motion** — average displacement of reliable landmarks
   between consecutive frames. Above `poseDeltaSuppressDeg` (8°) →
   motion detected.
2. **Camera shake** — pixel-level luminance diff on an 8×8 sampled
   grid of the Y plane. Above `cameraMotionSuppressPx` (24) → shake
   detected.

The combined score is the **minimum** of the two — either signal can
veto capture. Averaged over `stabilityWindowFrames` (10) so a single
bad frame doesn't kill the score.

## Countdown state machine

```
CaptureIdle
  ↓ (auto capture enabled, no suppress, score above threshold)
CaptureSearching
  ↓ (stableForFrames ≥ requirement)
CaptureReady
  ↓ (immediately)
CaptureCountdown (100ms tick → onTick)
  ↓ (timer elapses OR observeScore keeps it stable)
CaptureCapturing
  ↓ (camera.takePicture())
CaptureReviewing (success or failure)
  ↓ (showResultCardMs elapsed)
CaptureSearching (smart retry) OR CaptureIdle
```

**Auto-cancel**: during countdown, every frame's score is observed.
If the EMA drops by more than `countdownCancelDropThreshold` (0.15)
OR a suppress reason appears, the countdown cancels immediately and
the state returns to `CaptureSuppressed` → `CaptureSearching`.

## Smart retry

If a capture fails (motion blur, encoder error, etc.):
1. `CaptureFailureReason` is recorded in a `CaptureAttempt`.
2. `CaptureStateController.onCaptureFailure()` shows the result card
   with a user-friendly tip.
3. After `showResultCardMs` (2.5s), state returns to `CaptureSearching`.
4. The decision engine keeps running — if conditions improve, it
   re-enters countdown automatically.

`maxRetryAttempts` (default 1) caps consecutive retries to prevent
infinite loops. After the cap, the engine stays in `CaptureSuppressed`
until the user manually retries or conditions improve significantly.

## User preferences

Persisted via `CapturePrefs` (versioned schema, currently v1):

| Pref                  | Default | Storage key                  |
| --------------------- | ------- | ---------------------------- |
| `autoCaptureEnabled`  | false   | `avd_capture_auto_enabled`   |
| `countdownSeconds`    | 3       | `avd_capture_countdown_seconds` |
| `voicePromptsEnabled` | false   | `avd_capture_voice_enabled`  |
| `vibrationEnabled`    | true    | `avd_capture_vibration_enabled` |
| `sensitivity`         | balanced| `avd_capture_sensitivity`    |

Schema version stored at `avd_capture___schema_version`. Migrations
live in `CapturePrefs._migrate` — forward-only, one step at a time.

## Camera integration

The camera screen uses `ref.listenManual(captureStateProvider, ...)` in
`initState` to observe state transitions. When the state becomes
`CaptureCapturing`, it calls `cameraProvider.notifier.capture()` and
forwards the result (success/failure) back to the controller.

This is the only direct coupling between the camera module and the
capture module — everything else flows through Riverpod state.

## Edge cases

| Case                | Handling                                                |
| ------------------- | ------------------------------------------------------- |
| Multiple people     | `suppressReason = multiplePeople` (maxPersonsForAutoCapture = 1) |
| User exits frame    | `suppressReason = userExited` (pose == null)           |
| Fast movement       | Stability score drops → `subjectMoving`                |
| Camera shake        | Stability score drops → `cameraShake`                   |
| Camera rotation     | Handled by `PoseCoordinateMapper` (Day 9)               |
| Permission revoked  | `CaptureError` state + camera permission UI             |
| Low light           | `suppressReason = lowLight` (configurable)             |
| AI failure          | Engine returns score 0 → `lowConfidence` suppress      |
| Countdown quality drop | Auto-cancel → return to `CaptureSearching`           |
| Capture encode fail | `CaptureFailureReason.encoderError` → retry with tip   |

## Performance

- `CaptureDecisionEngine.evaluate` is O(factors) ≈ <1 ms per frame
- `StabilityDetector.process` is O(landmarks + 64 pixel samples) ≈ <0.5 ms
- `CountdownCoordinator` ticks at 100 ms — negligible
- All overlays are pure painters; no widget rebuilds except the small
  countdown ring + result card

## Day 12 preparation

Day 12 (Composition Intelligence) will:

1. Replace `_compositionStub` with a real `CompositionScorer`:
   - Rule of thirds (subject placement on intersection points)
   - Leading space (subject gaze direction + space ahead)
   - Symmetry balance (left/right visual weight)
   - Horizon level (if visible)
2. Plug real face detection into the guidance stage's `onCaptureScore`
   hook (replace `faceVisible` / `eyesOpen` stubs with ML Kit Face
   Detection output).
3. Add a `CompositionFactor` to `CaptureConfig` weights (renamed from
   the current `composition` slot — no schema change needed).
4. Surface composition hints in the guidance overlay (Day 10) when
   the composition factor is the weakest link.

All additive — capture decision engine, state machine, countdown, and
prefs are unchanged.
