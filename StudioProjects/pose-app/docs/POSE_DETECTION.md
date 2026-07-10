# Pose Detection & Human Tracking — Day 9

> First production AI module. Built on the Day 8 AI Foundation
> without modifying the base pipeline.

## Module layout

```
lib/features/pose/
├── domain/
│   ├── entities/
│   │   ├── pose_sample.dart      # PoseSample, PoseLandmark, PoseBoundingBox
│   │   └── pose_state.dart       # sealed PoseState tree + PoseContext
│   └── enums/
│       └── pose_landmark_type.dart  # 33-point ML Kit enum + skeleton connections
├── data/
│   ├── datasources/
│   │   └── mlkit_pose_backend.dart     # InferenceBackend impl using google_mlkit_pose_detection
│   └── repositories/
│       ├── pose_processor.dart         # Edge-case classifier (too close / far / occluded / etc.)
│       └── pose_pipeline_stage.dart    # Post-inference stage: track → smooth → decide
├── smoothing/
│   ├── one_euro_filter.dart            # Casiez et al. adaptive low-pass
│   └── pose_smoother.dart              # Per-landmark filter bank
├── tracking/
│   └── pose_tracker.dart               # IoU-based stable ID assignment
├── utils/
│   └── pose_coordinate_mapper.dart     # AI → preview → overlay transform
└── presentation/
    ├── providers/
    │   └── pose_providers.dart         # Riverpod composition root
    └── overlays/
        ├── pose_skeleton_painter.dart  # Bones + joints renderer
        └── pose_overlay_layer.dart     # Widget that hosts the painter
```

## Pipeline data flow

```
Camera YUV420 frame (CameraImage)
       │
       ▼  CameraNotifier._handleCameraImage
   AiFrame (platform-agnostic)
       │
       ▼  AiPipeline.submit (Day 8 back-pressure gate)
   MlKitPoseBackend.infer
       │
       ▼  Returns List<DetectionResult> with metadata['pose'] = PoseSample
   PosePipelineStage.process
       │
       ├── 1. Extract PoseSamples (kind == 'person')
       ├── 2. Filter noisy landmarks (likelihood < 0.3 dropped)
       ├── 3. PoseTracker.update → assign stable IDs (IoU matching)
       ├── 4. PoseSmoother.smooth → per-landmark One-Euro filter
       └── 5. PoseProcessor.classify + decide → PoseState + PoseContext
       │
       ▼  Riverpod state update (poseSamplesProvider, poseStateProvider, poseContextProvider)
   PoseOverlayLayer + PoseTrackingIndicator + AiDebugHud
```

## Backend choice justification

**Decision:** Google ML Kit Pose Detection, streaming mode, base model.

| Considered            | Verdict |
| --------------------- | ------- |
| **ML Kit** ✅         | Cross-platform from one Dart API, no model files shipped in app, streaming mode optimizes for camera frames, no API key, free |
| MediaPipe Tasks       | Equivalent model quality but requires shipping `.tflite` model file (~10 MB), per-platform GPU delegation quirks, more build complexity |
| TFLite MoveNet        | Lightning model is faster but only 17 keypoints; we want face landmarks for Day 10 guidance ("raise chin"). Also requires our own preprocessing pipeline |
| Cloud (REST)          | Wrong latency profile for real-time camera feedback; we'd add 80–200 ms RTT |

ML Kit's base model returns the full 33-point BlazePose topology at
~30 FPS on mid-range devices with ~30 ms median inference latency.

## Coordinate transformation

Three coordinate spaces, one mapper (`PoseCoordinateMapper`):

1. **AI space** — normalized [0..1] over the (rotated) model input
2. **Preview space** — pixels over the native camera sensor output
3. **Overlay space** — pixels over the `AiOverlayLayer` widget

The mapper handles:
- Sensor rotation (0/90/180/270°)
- Front camera X-mirror
- BoxFit.cover / contain / fill scaling

Widgets MUST NOT consume raw AI coordinates — they always go through
the mapper. This is enforced by `PoseOverlayLayer` constructing the
mapper and passing it to the painter.

## Tracking strategy

**IoU-based ID assignment** (single-frame matching):

1. Sort incoming detections by confidence (descending).
2. For each detection, find the existing track with the highest IoU
   above 0.3 — claim it.
3. Unmatched detections spawn new track IDs.
4. Tracks not matched in this frame "coast" for up to 30 frames
   (~1 s at 30 FPS) before being declared lost.

**Why not DeepSORT / appearance embedding?** Overkill for MVP —
single-subject is the dominant use case, and IoU matching is
deterministic + ~0 ms compute. Day 11+ (Smart Auto Capture in
crowded scenes) will swap in an appearance embedding model behind
the same `PoseTracker` interface.

## Smoothing strategy

**One-Euro filter** per landmark (Casiez, Rouisel, Vogel 2012):
- Adaptive low-pass: aggressive smoothing at low velocity (no jitter
  when subject is still), permissive at high velocity (no lag when
  subject moves fast)
- Defaults: `minCutoff = 1.0 Hz`, `beta = 0.007` (paper's recommended
  range for human motion)
- Filter resets when a new track ID is assigned (no cross-person
  smoothing)
- Only reliable landmarks (likelihood ≥ 0.5) are smoothed — noisy
  ones pass through unchanged so the overlay doesn't fake confidence

## Pose state machine

```
PoseIdle
  ↓ (camera starts)
PoseSearching
  ↓ (first detection)
PosePersonFound ← confidence > 0.5, reliable ≥ 8
  ↓ (next frame, IoU match)
PoseTracking ← context.isOk == false (e.g. too close)
  ↓ (context.isOk == true)
PoseReady ← canCapture = true
  ↓ (subject lost)
PoseLostTracking (coast up to 30 frames)
  ↓ (no reappearance)
PoseNoPerson
  ↓ (detection but confidence < 0.5)
PoseLowConfidence
```

`PoseContext` carries edge-case flags alongside the state so Day 10's
guidance engine can branch on `tooClose` / `tooFar` / `partialBody` /
`occluded` / `multiplePeople` / `lowLight` without re-deriving them.

## Edge case handling

| Case              | Detection                                            | State outcome        |
| ----------------- | ---------------------------------------------------- | -------------------- |
| Multiple people   | `poses.length > 1`                                   | `PoseTracking` (primary by confidence) |
| Partial body      | `reliableCount < 8`                                  | `PoseLowConfidence`  |
| Too far           | `boundingBox.area < 0.05`                            | `PoseTracking` (context.tooFar = true) |
| Too close         | `boundingBox.area > 0.85`                            | `PoseTracking` (context.tooClose = true) |
| Occlusion         | `reliable / total < 0.4`                             | `PoseLowConfidence`  |
| Fast movement     | One-Euro filter handles automatically                | normal state         |
| Camera rotation   | `PoseCoordinateMapper` applies sensor rotation       | normal state         |
| Portrait / landscape | Mapper uses sensor orientation, not UI orientation | normal state         |

## Performance strategy

- **ML Kit runs on its own native executor** — no Flutter isolate needed for inference
- **Camera frame listener** is the only main-thread work; it constructs an `AiFrame` and pushes to pipeline
- **Day 8 back-pressure gate** drops frames if previous inference is still in flight
- **One-Euro filter** is O(1) per landmark per frame
- **IoU tracker** is O(n²) where n = persons per frame (almost always 1)
- **Overlays are pure `CustomPainter`s** — zero widget rebuilds on detection updates
- **Skeleton painter** skips low-likelihood landmarks (no draw cost)

### Performance targets (Day 9)

| Metric                          | Target  | Mechanism                                |
| ------------------------------- | ------- | ---------------------------------------- |
| Inference latency (median)      | ≤ 35 ms | ML Kit streaming mode                    |
| Steady-state FPS                | 15–30   | Day 8 back-pressure gate + frame skip    |
| Frame drop rate under load      | < 10%   | Back-pressure gate                       |
| Landmark jitter (still subject) | < 2 px  | One-Euro filter at low velocity          |
| Landmark lag (moving subject)   | < 50 ms | One-Euro beta = 0.007 ramps cutoff fast  |
| UI jank (≥ 16 ms frames)        | < 1%    | Pure painters, no widget rebuilds        |

## Known limitations (Day 9)

1. **Low-light detection** — ML Kit's accuracy drops under ~50 lux.
   The pipeline detects this via `AiLowLight` (Day 8) but doesn't
   yet advise the user. Day 13 (Lighting Intelligence) addresses this.
2. **Multi-person tracking** — IoU matching works for 2–3 people
   but will swap IDs in dense crowds. Day 11 adds appearance embedding.
3. **Occlusion recovery** — coast frames (30) cover brief drops;
   longer occlusions spawn new IDs. Acceptable for MVP.
4. **Landscape camera** — works, but the overlay rotation assumes
   portrait sensor orientation. Day 6 polish didn't add a
   `MediaQuery.orientation` listener to the camera screen — schedule
   for Day 14.
5. **ML Kit model size** — first run downloads ~10 MB. We should
   show a one-time "Preparing AI models…" UI; scheduled for Day 14.

## Day 10 preparation

Day 10 (AI Pose Guidance) will add:

1. `PoseQualityScorer` — computes per-joint angle, body symmetry,
   head tilt, limb extension from the smoothed `PoseSample`.
2. `GuidanceEngine` — maps quality scores to actionable hints
   ("Raise chin", "Straighten left arm", "Shift weight to back foot").
3. `GuidanceOverlay` — uses `PoseCoordinateMapper` to place hint
   labels next to the relevant landmark.
4. `PoseState` extension — `PoseGuidanceActive` state when hints
   are being shown.

All of this is **additive** — no changes to the pose detection,
tracking, or smoothing layers. Day 10 reads `poseSamplesProvider`
+ `poseContextProvider` and emits guidance.
