# IMPLEMENTATION_REPORT.md

## Session scope
Implement the P0 MVP core on top of a blank Flutter starter template: real-time camera + on-device pose detection + single-instruction AI guidance, on a clean, feature-first architecture that the rest of the product spec can extend without rewrites.

## Product decisions made and why

**Decision: Rule-based guidance engine, not a learned model.**
The spec explicitly forbids faking personalization before real usage data exists (§6). A transparent rule engine (framing → centering → shoulder tilt → hold) is honest about what it does, is fully unit-testable without a device, and gives a clean seam (`GuidanceEngine`) to later replace with a personalized decision engine — without touching camera or UI code.

**Decision: One instruction at a time, prioritized.**
Per §14, stacking multiple corrections would overwhelm the user. The engine returns exactly one `GuidanceMessage` per evaluation, in priority order matching how a human photographer actually directs someone (can't see you → too far/close → off-center → tilted → hold).

**Decision: Frame sampling instead of processing every camera frame.**
Per §20, running inference on every frame is unnecessary and costly on mid/low-end hardware. Every 3rd frame is sampled, giving roughly 6-10 inferences/sec on a typical 30fps stream — enough for smooth-feeling guidance without pegging the CPU. This threshold is a starting point, not a validated number (see Limitations below).

**Decision: Bengali + English guidance text, not Bengali-only.**
The spec's example phrases are in Bengali, but hardcoding the app to one language would block future localization and make testing/debugging harder for contributors who don't read Bengali. Each `GuidanceMessage` carries both `textBn` and `textEn`; the UI currently renders `textBn` to match the spec's UX examples, but the data model doesn't lock that in.

**Decision: No auto-capture in this slice.**
Auto-capture requires the "Smart Auto Capture" decision logic (pose + stability + eye state + framing + confidence) described in §5 — a materially larger and riskier feature (false triggers actively damage trust, per §23). Shipping a solid manual-capture experience with visible AI feedback (the "ready" ring on the shutter button) first, then layering auto-capture on top of a validated guidance engine, is the lower-risk sequencing.

**Decision: No cloud/backend, no analytics SDK, no gallery screen.**
None of these are needed to answer the MVP's core question (§3): "can this help one person take a better photo without a photographer?" Adding them now would be scope creep against the spec's own instruction (§8) not to build everything at once.

## Files touched

| File | Change |
|---|---|
| `pubspec.yaml` | Added `flutter_riverpod`, `camera`, `google_mlkit_pose_detection`, `permission_handler`, `path_provider` |
| `lib/main.dart` | Replaced counter-demo boilerplate with real app entry point (`ProviderScope` + dark theme + `CameraScreen` as home) |
| `lib/core/theme/app_theme.dart` | New — design tokens and dark theme |
| `lib/features/pose/domain/pose_landmark_data.dart` | New — vendor-agnostic pose/landmark domain types |
| `lib/features/pose/data/pose_detection_service.dart` | New — ML Kit wrapper, the only file that imports the vendor SDK |
| `lib/features/guidance/domain/guidance_message.dart` | New — guidance instruction domain type |
| `lib/features/guidance/application/guidance_engine.dart` | New — rule-based single-instruction decision engine |
| `lib/features/camera/data/camera_service.dart` | New — camera plugin wrapper (permissions, lifecycle, capture) |
| `lib/features/camera/domain/camera_state.dart` | New — camera session UI state model |
| `lib/features/camera/application/camera_session_controller.dart` | New — Riverpod controller orchestrating camera → pose → guidance |
| `lib/features/camera/presentation/screens/camera_screen.dart` | New — main screen, all UI states |
| `lib/features/camera/presentation/widgets/guidance_overlay.dart` | New — single-instruction chip UI |
| `lib/features/camera/presentation/widgets/capture_button.dart` | New — shutter button with capture/ready states |
| `lib/features/camera/presentation/widgets/permission_request_view.dart` | New — permission-denied state UI |
| `android/app/src/main/AndroidManifest.xml` | Added `CAMERA` permission + camera hardware features |
| `android/app/build.gradle.kts` | Pinned `minSdk` to 21 (ML Kit's floor) |
| `ios/Runner/Info.plist` | Added `NSCameraUsageDescription` |
| `test/widget_test.dart` | Replaced stale counter test with a real app-boot smoke test |
| `test/guidance_engine_test.dart` | New — 11 unit tests covering the guidance engine's rule logic |
| `docs/PROJECT_AUDIT.md` | New — honest baseline + scored assessment |
| `docs/ROADMAP.md` | New — prioritized backlog for everything not in this slice |

## Known limitations (see PROJECT_AUDIT.md §4 for full detail)
This code has **not been compiled or run** — this sandbox has no Flutter SDK and no camera hardware. Package versions are best-effort from general knowledge, not verified against pub.dev at write time. Before trusting this as working software, run `flutter pub get && flutter analyze && flutter test && flutter run` on your machine and report back what breaks.

## Hardening pass (session 2)

A follow-up session was scoped explicitly to verification and hardening, not new features. It re-read every file adversarially, hand-traced the pipeline against the actual documented behavior of `camera`, `google_mlkit_pose_detection`, and `flutter_riverpod`/`state_notifier`, and found seven real defects — most notably a lifecycle bug that would have crashed the app on the very first background→foreground cycle. All seven were fixed. Full detail, with honest confidence labels for every claim, is in `docs/P0_VERIFICATION_REPORT.md`.

Files touched in the hardening pass, in addition to the P0 slice above:

| File | Change |
|---|---|
| `lib/features/camera/application/camera_session_controller.dart` | Split `dispose()` (terminal) from new `pauseSession()`/`resumeSession()` (safe to call repeatedly); replaced a reference to a `mounted` getter that `StateNotifier` doesn't expose with an explicit `_disposed` flag; added a camera-controller error listener for the "camera becomes unavailable mid-session" scenario; added a controller-level latest-frame-wins guard; removed a dead import |
| `lib/features/pose/data/pose_detection_service.dart` | Defensive multi-plane byte concatenation for NV21 frames; front-camera landmark x-coordinate mirroring; distinct `PoseDetectionException` for real detector failures vs. busy-skip |
| `lib/features/guidance/domain/guidance_message.dart` | Added `PoseTrackingState` enum (`noPerson`/`searching`/`lowConfidence`/`guidance`/`ready`/`hold`/`error`) required by the hardening spec; added corresponding message constants |
| `lib/features/guidance/application/guidance_engine.dart` | Rewritten as a stateful engine with debounce (won't flip between "move left"/"move right" on a single opposing frame) and hysteresis (wider threshold to re-enter a correction than to clear it); fixed a real bug in the first draft of this logic where the "frames since good detection" counter could never advance past 1 |
| `lib/features/camera/presentation/screens/camera_screen.dart` | Fixed background/resume to call the new pause/resume methods instead of `dispose()`/`initialize()`; scoped Riverpod `watch` calls with `select` so guidance updates (6-10/sec) no longer rebuild the camera preview |
| `android/app/src/main/AndroidManifest.xml` | Locked activity to portrait (`android:screenOrientation="portrait"`) |
| `ios/Runner/Info.plist` | Trimmed supported orientations to portrait-only |
| `lib/main.dart` | Added `SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])` |
| `test/guidance_engine_test.dart` | Rewritten for the new state machine and debounce/hysteresis behavior (was previously testing stateless per-frame logic that no longer exists) |
| `test/camera_state_test.dart` | New — `CameraSessionState.copyWith` unit tests |
| `test/guidance_overlay_widget_test.dart` | New — widget tests for the guidance chip |
| `test/permission_request_view_widget_test.dart` | New — widget tests for the permission-denied UI |
| `docs/P0_VERIFICATION_REPORT.md` | New — full honest verification report |

**Why portrait-lock instead of fixing rotation properly:** correct rotation handling needs device-orientation tracking combined with sensor orientation and lens direction — real new complexity, which this pass was explicitly scoped not to add. Locking orientation removes the scenario where the latent bug would surface, which is the bounded, honest thing to do in a hardening pass rather than leaving it silently broken.

## P1, slice 1: lighting intelligence + gallery

A later request arrived framed as "P0 is verified, P1 is complete, begin P2 personalization" — neither claim was true against this repo (P0's build/test/APK steps were never actually run anywhere, including CI; P1 hadn't been started at all). Rather than build a personalization engine on that premise, the call was to correct the premise and ship a real, bounded P1 slice instead: **lighting intelligence v1** and a **gallery screen**. Composition (rule-of-thirds/headroom), chin/eye-contact guidance, onboarding, and device-tier detection remain explicitly not done — see the updated `docs/ROADMAP.md`.

These two were chosen specifically because neither touches `GuidanceEngine`, which was hand-verified line-by-line in the hardening pass — the goal was additive value without reopening code that's already been through that scrutiny.

### Lighting intelligence v1
New `features/lighting/` module: a pure `LightingAnalyzer` (luma averaging, two entry points for Android's NV21 Y-plane and iOS's BGRA8888) feeding a stateful `LightingEngine` (hysteresis, same debounce pattern as the guidance engine, kept as a separate implementation rather than a shared base class since the two reason about unrelated signals). A new pure function, `mergePoseAndLighting`, combines pose and lighting output into the single message the UI shows, with pose always winning while it needs attention — lighting only surfaces once the pose is "ready" or "hold".

Lighting is sampled far less often than pose (roughly once/second vs. 6-10/sec) via its own frame-counter and its own busy-guard, entirely decoupled from the pose pipeline's timing.

**Two real bugs were found and fixed while building this, before any test was even written:**
1. The first draft dispatched between the Android/iOS luma-extraction code paths by checking `image.planes.length == 1` — wrong signal, since Android NV21 can legitimately arrive as either one or two planes depending on device/plugin version (the same uncertainty already documented in `pose_detection_service.dart` from the P0 pass). Fixed to dispatch on `image.format.group` instead, which is the actual pixel format the camera was configured for.
2. Related: if NV21 does arrive as a single concatenated buffer (Y bytes followed by interleaved UV bytes), averaging across the *whole* buffer would mix ~33% chroma bytes into what's supposed to be a pure brightness reading — not imprecise, just wrong. Fixed by clipping to exactly `width * height` bytes before analysis, which is always the true Y-plane size regardless of how the buffer happens to be laid out.

Both were caught by re-reading the code adversarially, not by running anything — this sandbox still can't run Flutter (see `docs/P0_VERIFICATION_REPORT.md` §1, unchanged).

### Gallery screen
New `features/gallery/` module, reusing the exact directory `CameraService.capturePhoto()` already writes to — no new storage location introduced. `GalleryService.listCaptures()` lists, `delete()` removes; timestamps are recovered from the existing `avd_<millis>.jpg` filename convention via a standalone `parseCaptureTimestamp()` function, pulled out specifically so it's unit-testable without a filesystem or platform channel. The screen itself is a simple grid → full-screen viewer → delete-with-confirmation flow, wired into the camera screen's previously-unused placeholder button.

### Tests added
`test/lighting_analyzer_test.dart` (luma math + hysteresis, including a hand-computed green-pixel luma-weight check), `test/gallery_service_test.dart` (filename timestamp parsing, five cases including malformed input), `test/guidance_coordinator_test.dart` (priority ordering between pose and lighting, including that a lighting nudge preserves the underlying `hold` state so the capture-ready ring doesn't turn off). All hand-traced against the implementation, not executed — same BLOCKED toolchain situation as before.

## P1, slice 2: composition v1, attention (face-camera), onboarding, device-tier

Full detail in `docs/P1_COMPLETION_REPORT.md`, which follows the same phase-by-phase structure the driving prompt requested. Summary of what's new:

- **Composition intelligence v1** (`features/composition/`): headroom-only, by explicit scoping decision — rule-of-thirds would contradict the existing centering-based `GuidanceEngine`, horizon alignment and symmetry need signals this pipeline doesn't have. Same hysteresis pattern as lighting.
- **Attention engine** (`features/guidance/application/attention_engine.dart`): "face the camera" via ear-likelihood asymmetry — a real, reliable signal from existing pose landmarks. Chin pitch explicitly NOT implemented; the current landmark set can't reliably support it, and faking it would violate the product's own "never guess when uncertain" principle. Kept as a sibling to `GuidanceEngine`, not merged into it, so the hand-verified engine from the P0 hardening pass stays untouched.
- **`mergeGuidance()` expanded** from 2-way (pose/lighting) to 4-way (pose → attention → composition → lighting), still a pure function, still preserving the underlying pose `state` so secondary nudges don't turn off the capture-ready ring.
- **Device-tier detection** (`features/device/`): `Platform.numberOfProcessors`-based classification (honestly not a real benchmark — documented as such), feeding a centralized `PerformanceConfig` that replaced hardcoded frame-sample-rate constants in `CameraSessionController`.
- **Onboarding** (`features/onboarding/`): 4-slide flow, `shared_preferences` for persistence (new dependency), fails open to the camera screen if the persisted-state check errors.
- **Gallery audit**: two real gaps found and fixed — no error handling in the full-screen viewer for a vanished file, and thumbnails decoding at full capture resolution instead of a bounded size.

32 new hand-traced tests across 5 new test files. Toolchain remains BLOCKED — nothing in this slice has been compiled or run either.

## UI polish + system fixes pass

Requested as "make the UI more professional, and fix what the system needs" — treated as two linked things: real visual polish, plus an actual audit for gaps rather than only cosmetic changes.

**Found and fixed (system gaps, not just style):**
- `AppColors.scrimTop`/`scrimBottom` were defined in the theme from the very first P0 slice and never once used anywhere — dead design tokens. Wired them into a new `_EdgeScrim` gradient on the camera screen so the guidance chip and bottom controls stay legible over bright backgrounds.
- Icon-only buttons (lens switch, gallery entry, shutter) had no accessibility label or tooltip — a real regression against spec §16 ("support screen readers"), not caught until this pass. Added `Semantics`/`Tooltip` to all three.
- Gallery's AppBar was Flutter's unstyled default — exactly the "looks like a generic Flutter template" the product spec explicitly warns against (§13/§33). Restyled to match the app's flat, tokenized design language, plus a live photo-count in the actions row.

**Visual polish:**
- Guidance chip upgraded from a flat semi-transparent fill to a real backdrop-blur glass effect with a drop shadow and a scale+fade transition, instead of only a fade.
- Shutter button gained genuine tactile feedback: a press-down scale animation and a haptic tick (`HapticFeedback.mediumImpact()`) on capture, plus a soft glow shadow that intensifies when the pose is capture-ready — none of this existed before; it was a static circle with no press feedback at all.

No changes to `GuidanceEngine`, the coordinator, or any of the analysis engines — this pass was scoped to presentation-layer files only, so none of the hand-verified pipeline logic was touched. Toolchain still BLOCKED, so none of this has been visually confirmed on a real screen — the glass-blur effect in particular (`BackdropFilter`) is a place worth checking for performance on a real device, since backdrop blurs are one of the more GPU-intensive Flutter effects.

## Product identity fix

A follow-up "make needed improvements" request led to a full audit for anything still left over from `flutter create`'s defaults, beyond the counter-app boilerplate already replaced in the P0 slice. Found that **every user-and-store-facing identifier was still the literal template default**, despite the app being called "AI Visual Director" everywhere in product docs:

| What | Was | Now |
|---|---|---|
| Android home-screen label | `pose` | `AI Visual Director` |
| Android `applicationId` / `namespace` | `com.example.pose` | `com.aivisualdirector.app` |
| iOS `CFBundleDisplayName` | `Pose` | `AI Visual Director` |
| iOS/macOS bundle identifiers | `com.example.pose` | `com.aivisualdirector.app` |
| Dart package name (`pubspec.yaml`) | `pose` | `ai_visual_director` |
| Web manifest name/title | `pose` | `AI Visual Director` |

This isn't cosmetic: `com.example.*` bundle identifiers are **rejected outright by both the Play Store and App Store** at submission — shipping under them isn't possible, not just unpolished. The Kotlin `MainActivity.kt` was moved to a matching `com/aivisualdirector/app/` package directory (Android requires the file path and the `package` declaration inside it to match `applicationId`/`namespace`, or the build fails). All 12 test files' `package:pose/` imports were updated to `package:ai_visual_director/` to match the renamed Dart package.

**`com.aivisualdirector.app` is a placeholder**, chosen to be plausible and consistent across platforms — replace it with whatever domain/company identifier you actually control before any real store submission; bundle identifiers are difficult to change after an app has real users and reviews attached to a store listing, so getting this right before first release matters more than most other config.

Confirmed via a final repo-wide grep that no `com.example` or bare `"pose"` branding references remain anywhere in the project. Toolchain still BLOCKED — this rename has not been build-verified, and a rename touching `applicationId`/bundle identifiers is exactly the kind of change worth double-checking builds cleanly (Phase 1 of `docs/DEVICE_TESTING_CHECKLIST.md`) before anything else.

## Zoom, Flash, AI Overlay, Auto Capture

Requested directly: add the three Phase-1 items that were flagged as missing (`zoom/flash`, `AI overlay`, `Auto Capture`) in the honest status check that preceded this. All three added; none required touching `GuidanceEngine`.

**Zoom + Flash** (`CameraService`): `setZoomLevel`/`setFlashMode` added, reading real per-device min/max zoom bounds from the plugin on every camera open (not cached once — front/back cameras often differ) and clamping any requested zoom to that range. Flash cycles off → auto → torch (skipping `always`, which fires on every capture rather than staying on — the wrong default for a guidance app the user looks at before shooting). Wired to a real pinch-to-zoom gesture on the preview (`GestureDetector.onScaleUpdate`, computing zoom relative to the level at gesture-start, since `ScaleUpdateDetails.scale` is cumulative) and a top-left flash toggle, both new interactions that didn't exist before.

**AI Overlay** (`PoseOverlayPainter`, a `CustomPainter`): skeleton lines over a deliberately small subset of landmarks (the same ones `GuidanceEngine` already reasons about — nose, shoulders, hips, knees, ankles — not the full ML Kit set, to stay legible), a rule-of-thirds visual grid, and a directional arrow for left/right centering corrections. **Explicit scoping note carried into the code itself:** the grid is purely visual, like a real camera's grid-overlay setting — it does not imply rule-of-thirds *guidance text*, which is still deliberately not implemented (see Composition v1's own scoping decision in `docs/P1_COMPLETION_REPORT.md` — a textual "move to a third" instruction would contradict the centering-based guidance engine; a visual reference line doesn't). The direction arrow recomputes left/right independently from raw pose data rather than reading it off `GuidanceEngine`'s decision, a deliberate lower-stakes duplication — worst case the arrow is briefly imprecise while the actual text instruction (the real guidance channel) stays correct and stable. Off by default, toggleable via a new top-left button, and built as its own isolated `Consumer` so leaving it off costs nothing.

**Auto Capture** (`AutoCaptureEngine`): a new, small state machine — `disabled → waiting → countingDown → cooldown` — that sits *on top of* `GuidanceEngine`'s already-debounced `hold` signal rather than reaching into raw pose data itself, the same "consume, don't own" pattern used for lighting/composition/attention. Uses wall-clock time via an injectable clock (not frame counts), so the 2-second hold requirement means the same thing regardless of device tier / sample rate. **Defaults to disabled** (spec §5: "Auto Capture MUST remain optional") — a brand-new feature that could fire the shutter on its own should never be on without the user explicitly turning it on, which is the only way `setAutoCaptureEnabled(true)` ever gets called. A 3-second cooldown after each automatic capture prevents an immediate second shot on the same held pose. 15 unit tests using a fake clock, hand-traced frame-by-frame against the implementation, cover the countdown, cooldown, reset-on-lost-hold, and disable-mid-flight behaviors specifically because a countdown timer is exactly the kind of logic that's easy to get subtly wrong (off-by-one on the trigger frame, cooldown not actually blocking a second trigger, etc) — traced explicitly rather than assumed correct.

New top-left control row (flash / overlay toggle / auto-capture toggle), a zoom-level indicator (hidden entirely on devices that don't support zoom, rather than showing a meaningless "1.0x"), and a centered auto-capture countdown overlay were all added to `camera_screen.dart`. `CameraSessionState` gained `zoomLevel`, `minZoom`, `maxZoom`, `flashMode`, `autoCapture`, and `showOverlay` fields — all with safe, inert defaults (see the new tests in `test/camera_state_test.dart`), so existing behavior is unchanged unless a user actively opts into the new controls.

Toolchain remains BLOCKED — none of this has rendered on a real screen. The pinch-to-zoom gesture and the pose-overlay `CustomPaint` are the two things in this batch most worth confirming feel right on a real device; gesture math and canvas coordinate mapping are exactly the kind of thing that looks right on paper and needs a real touchscreen to actually validate.
