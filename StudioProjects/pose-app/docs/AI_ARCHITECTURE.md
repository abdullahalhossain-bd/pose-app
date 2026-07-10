# AI Architecture — Day 8 Foundation

> The AI infrastructure that supports every future AI capability of
> AI Visual Director. Built for 10-year longevity, not for a demo.

## Module layout

```
lib/features/ai/
├── config/
│   └── ai_config.dart            # AiConfig (immutable), AiPerformanceMode, ThermalPolicy
├── state/
│   ├── ai_state.dart             # sealed AiState tree + AiFeedback
│   └── ai_state_controller.dart  # StateNotifier<AiState> — single owner of transitions
├── domain/
│   ├── entities/
│   │   ├── ai_frame.dart         # AiFrame + AiFramePlane (platform-agnostic)
│   │   └── detection.dart        # DetectionResult, BoundingBox, Keypoint, PoseConnection
│   └── repositories/
│       └── inference_backend.dart # InferenceBackend interface + InferenceCapabilities
├── data/
│   └── datasources/
│       └── stub_inference_backend.dart # Day 8 stub; Day 9+ replaces with TFLite/MLKit
├── pipeline/
│   └── ai_pipeline.dart          # Orchestrator: collect→select→preprocess→infer→decide
├── performance/
│   ├── ai_performance_monitor.dart # FPS / latency / drop rate
│   ├── thermal_monitor.dart        # /sys/class/thermal reader (Android) — platform-stub otherwise
│   └── battery_monitor.dart        # BatterySnapshot stub (battery_plus Day 9)
├── presentation/
│   ├── providers/
│   │   ├── ai_providers.dart     # All Riverpod providers for the AI feature
│   │   └── ai_camera_bridge.dart # Glues camera frame stream → pipeline
│   ├── overlays/
│   │   ├── ai_overlay_painters.dart # BoundingBoxPainter, PoseLinePainter, DirectionArrowPainter
│   │   └── ai_overlay_layer.dart    # SafeDrawingLayer widget
│   └── widgets/
│       └── ai_status_banner.dart  # Top banner showing AI state to user
├── debug/
│   └── ai_debug_hud.dart         # On-screen FPS / latency overlay
└── utils/                        # Day 9+ (image utils, isolate runner)
```

## Data flow

```
Camera plugin (CameraImage)
       │
       ▼  CameraNotifier._handleCameraImage (data layer)
   AiFrame  (domain entity, platform-agnostic)
       │
       ▼  AiPipeline.submit
   Frame selector (drop if back-pressured, or below frameSkip budget)
       │
       ▼  AiPipeline._preprocess
   AiFrame  (rotated / resized; Day 9 isolate-bound)
       │
       ▼  InferenceBackend.infer
   Either<Failure, List<DetectionResult>>
       │
       ▼  AiPipeline._filterByConfidence + NMS
   List<DetectionResult>
       │
       ▼  AiPipeline._decide
   AiState  (Ready / NoSubject / LowLight / CaptureReady / Error)
       │
       ▼  AiStateController.transitionTo + onResult
   Riverpod state (aiStateProvider, aiDetectionsProvider)
       │
       ▼  Widgets rebuild only what they consume
   AiOverlayLayer + AiStatusBanner + AiDebugHud
```

## Extension points

### Add a new inference backend (Day 9)

1. Implement `InferenceBackend` (e.g. `TfLiteMoveNetBackend`).
2. Override `inferenceBackendProvider` in `main.dart` based on `AppConfig.env`:
   ```dart
   inferenceBackendProvider.overrideWith((ref) => TfLiteMoveNetBackend()),
   ```
3. Done. The pipeline, state machine, overlays — nothing else changes.

### Add a new overlay type

1. Extend `AiOverlayPainter` (e.g. `HeatmapPainter`).
2. Add an opt-in flag on `AiOverlayLayer` (e.g. `showHeatmap`).
3. Add a `CustomPaint` to the `Stack` in `ai_overlay_layer.dart`.

### Add a new AI state

1. Add a class extending `AiState` in `ai_state.dart`.
2. Add a transition method to `AiStateController`.
3. Update the exhaustive `switch` in `AiStatusBanner` (the compiler
   will force you — that's the safety net).

### Add a new performance preset

1. Add the value to `AiPerformanceMode`.
2. Add a `factory AiConfig.forMode` case.
3. Wire the user toggle in Settings (Day 6 settings screen).

## Performance goals

| Metric                          | Target | Mechanism                                   |
| ------------------------------- | ------ | ------------------------------------------- |
| Steady-state FPS (balanced)     | 15     | `processingIntervalMs = 66` + frame skip    |
| Inference latency (balanced)    | <50ms  | Isolate-bound backend (Day 9)               |
| Frame drop rate under load      | <10%   | Back-pressure gate in `AiPipeline.submit`   |
| UI jank (frames ≥ 16ms)         | <1%    | Overlays are pure painters; no widget rebuild on detection |
| Battery impact (battery saver)  | <2%/h  | Drop to 6 FPS, smaller input, isolate sleep |
| Thermal response                | auto   | `ThermalMonitor` → `ThermalPolicy` → pause  |

## Day 8 → Day 9 transition checklist

Before Day 9 (real-time pose detection) starts:

- [ ] Add `tflite_flutter: ^0.11.0` to pubspec
- [ ] Add `google_mlkit_pose_detection: ^0.12.0` as alternative backend
- [ ] Add `device_info_plus` + `battery_plus` for real monitoring
- [ ] Implement `TfLiteMoveNetBackend` extending `InferenceBackend`
- [ ] Move `_handleCameraImage` preprocessing to a `ComputeIsolate`
- [ ] Add sensor rotation lookup from `CameraDescription.sensorOrientation`
- [ ] Define COCO-17 `PoseConnection` list in `domain/entities/pose_connections.dart`
- [ ] Add pose-quality scoring to `AiPipeline._decide`
- [ ] Override `inferenceBackendProvider` based on `AppConfig.env`
- [ ] Add `showDebugOverlay` toggle to Settings UI

The Day 8 foundation is built so that ALL of the above is additive —
no refactoring of pipeline / state / overlays required.
