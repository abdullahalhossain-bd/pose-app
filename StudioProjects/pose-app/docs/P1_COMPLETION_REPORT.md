# P1_COMPLETION_REPORT.md

## Phase 0 — status at the start of this pass (verified against actual code, not prior docs)

| Layer | Status |
|---|---|
| P0 (camera, pose, guidance core) | IMPLEMENTED, hardened in a prior pass. UNVERIFIED — no toolchain/device access has ever run `pub get`/`analyze`/`test`/`build`, and nothing has been pushed to trigger the CI workflow that exists for this purpose. |
| P1: Lighting v1 | IMPLEMENTED (prior pass). UNVERIFIED. Two real bugs from that pass (format-detection, chroma-byte contamination) were re-checked this pass and confirmed still fixed. |
| P1: Gallery | IMPLEMENTED (prior pass). UNVERIFIED. Two new real gaps found and fixed this pass (see Phase 7 below). |
| P1: Composition | NOT IMPLEMENTED at start of this pass. |
| P1: Chin/eye guidance | NOT IMPLEMENTED at start of this pass. |
| P1: Onboarding | NOT IMPLEMENTED at start of this pass. |
| P1: Device-tier detection | NOT IMPLEMENTED at start of this pass. |
| P2 (personalization) | NOT IMPLEMENTED. Correctly not started. |

## Phase 1 — toolchain verification

**BLOCKED**, unchanged from every prior pass: this sandbox has no network access to `pub.dev` or the Flutter SDK host, and no physical device. `flutter pub get`/`analyze`/`test`/`build apk`/`devices`/`run` were not executed. Everything below comes from static code review and hand-tracing, explicitly marked as such.

## Phase 2 — re-checking the previously-found lighting bugs

Confirmed by direct code inspection (not assumed): `camera_session_controller.dart`'s `_sampleLighting` still dispatches on `image.format.group == ImageFormatGroup.bgra8888` (not plane count), and still clips NV21 luma to exactly `width * height` bytes via `Uint8List.sublistView` before analysis. **FIXED, still fixed.** No equivalent format-guessing bug was found elsewhere — `pose_detection_service.dart`'s NV21 handling was checked too and doesn't make the same mistake (it defensively concatenates all planes rather than guessing a format from plane count, a different and still-correct strategy for its different requirement — ML Kit needs the full YUV buffer, not isolated luma).

## Phase 3 — Composition Intelligence v1

Implemented, scoped narrowly to **headroom only** — not the full list in the spec (rule-of-thirds, symmetry, horizon alignment). This is a deliberate product/architecture decision, not a shortcut, documented in full in `composition_analyzer.dart`'s class doc:

- Rule-of-thirds horizontal placement would directly contradict `GuidanceEngine`'s existing centering logic (which targets dead-center). Shipping both means the app sometimes says "center yourself" and sometimes says "move off-center" — a coherence bug. Resolving it needs a product decision about the app's default photographic style, not just code.
- Horizon alignment needs a device-tilt or scene-level horizontal reference that doesn't exist in this pipeline; faking it from shoulder tilt would just duplicate `GuidanceEngine`'s existing shoulder-level check under a new name.
- Symmetry needs scene-level (not pose-landmark) analysis, out of scope for this analyzer.
- Footroom is intentionally not duplicated — `GuidanceEngine`'s existing subject-height/framing check already covers it.

Headroom uses the nose landmark as a proxy, with the same hysteresis/debounce pattern used in `LightingEngine` (separate implementation, not a shared base class — see the class doc for why). 10 unit tests hand-traced against the implementation.

## Phase 4 — Guidance priority (4-way merge)

`GuidanceEngine` was **not modified** — per this pass's own explicit instruction not to casually rewrite the hand-verified engine. Instead, `mergeGuidance()` in `guidance_coordinator.dart` was extended from a 2-way (pose/lighting) to a 4-way pure merge function: pose correction → attention (face the camera) → composition → lighting → pose confirmation. Each source keeps its own debounce/hysteresis history; the merge step is stateless and only picks between four already-stable outputs. 8 unit tests cover every ordering pair, plus the specific requirement that a secondary nudge (lighting/composition/attention) preserves the underlying pose `state` so the capture-ready ring doesn't turn off for a minor suggestion.

## Phase 5 — Chin & eye guidance

**PARTIAL, honestly scoped down — not silently skipped.**

- **Implemented:** head yaw detection ("face the camera"), using a genuinely reliable signal — ML Kit's per-landmark confidence (`likelihood`) drops sharply for the far-side ear when a person turns their head away from the camera. Sustained asymmetry between left/right ear likelihood, with persistence-based hysteresis matching every other engine in this codebase, triggers the guidance.
- **Not implemented, on purpose:** chin pitch (raise/lower chin). `google_mlkit_pose_detection`'s body-pose landmarks (nose, eyes, ears as coarse 2D skeleton points) do not contain a reliable signal for "chin tilted up vs down" — any heuristic built from this landmark set would either be confusable with the subject's height in frame or would flicker constantly even with hysteresis. Doing this properly needs `google_mlkit_face_detection` (a different model, a new dependency, its own frame-processing budget) — a real feature addition, not a quick extension. This directly follows this pass's own instruction: "do not claim precise facial analysis if the available model cannot reliably support it... if uncertain, say nothing." 6 unit tests for the yaw detector.

## Phase 6 — Hysteresis / stability audit

Every guidance source in the pipeline now follows the same pattern (enter/clear thresholds wider apart than a single boundary, persistence counts before flipping): `GuidanceEngine` (from the P0 hardening pass), `LightingEngine`, `CompositionEngine`, `AttentionEngine` (both new this pass). No guidance source was found using a bare single-threshold check that could flicker. The 4-way merge itself doesn't need its own hysteresis — it's deterministic given four already-debounced inputs.

## Phase 7 — Gallery audit

Checked against the spec's own checklist, not assumed clean:

| Check | Finding |
|---|---|
| Images actually persisted | Confirmed — same path `CameraService.capturePhoto()` writes to. |
| Deterministic naming | Confirmed — `avd_<millis>.jpg`. |
| Missing/corrupt file handling | **Gap found and fixed.** Grid tiles had an `errorBuilder`; the full-screen viewer did not — if a file vanished between the grid load and opening the viewer (race with deletion, or another process), `Image.file` would have thrown uncaught. Added an `errorBuilder` there too. |
| Permissions | Correct — app-private documents directory, no storage permission needed. |
| Empty/loading/error states | All three present and correct. |
| Deletion safety | Confirmed — existence check before delete, confirmation dialog before deleting from the UI. |
| Large galleries not fully loaded into memory | **Gap found and fixed.** `GridView.builder` already lazily builds only visible tiles, but `Image.file` had no `cacheWidth`, meaning every visible thumbnail was decoded at full capture resolution just to render a few centimeters across. Added `cacheWidth: 300`. **Known limitation, not fixed:** `listCaptures()` still lists every file in the directory in one pass (cheap for file metadata, but not paginated) — acceptable for MVP scale, worth revisiting if galleries grow into the thousands. |

## Phase 8 — Onboarding

Implemented: 4 slides (what the app does, how guidance works, capture is always manual — correctly not claiming Auto Capture exists, since it doesn't — and on-device processing), skip button, persisted completion via `shared_preferences` (new dependency). Wired into `main.dart` via a `_RootGate` widget that fails open to the camera screen if the persisted-state check errors, so onboarding can never trap a user who already completed it. 3 unit tests against a mocked `SharedPreferences`.

## Phase 9 — Device-tier detection

Implemented, honestly scoped: classification uses only `Platform.numberOfProcessors` (core count) — a real but crude proxy, not a benchmark. Explicitly not implemented: RAM query, GPU capability, thermal sensing, or a calibration pass (timing actual pose-detector calls on first launch). The spec's own instruction ("do not attempt to perfectly benchmark every Android device") is why this stops here rather than going further. `PerformanceConfig` centralizes the tier→sample-rate mapping that used to be hardcoded constants directly in `CameraSessionController`; low tier still samples pose at the same rate the original P0 slice shipped with for all devices, satisfying "never make the app unusable on LOW devices." 4 unit tests.

## Phase 10 — Performance hardening

No new profiling was possible (still no device). Reviewed for the specific anti-patterns the spec calls out: composition and attention analysis were deliberately built to consume the *same* `PoseFrame` pose detection already produces each cycle, at zero additional frame-processing cost — only lighting needs its own separate, far-rarer sampling pass over raw pixel bytes (unchanged from the prior pass). No new unbounded queues, no new simultaneous-inference risk, no repeated image conversions introduced.

## Phase 11 — Tests

32 new test cases added this pass across 5 new files (`composition_analyzer_test.dart`, `attention_engine_test.dart`, `performance_config_test.dart`, `onboarding_state_service_test.dart`, rewritten `guidance_coordinator_test.dart`), plus fixes to `widget_test.dart` for the new onboarding gate. All hand-traced line-by-line against their implementations — none executed (Phase 1, BLOCKED).

## Phase 12 — Privacy

No new network calls, no new persistence beyond a single boolean onboarding flag (`shared_preferences`) and the pre-existing photo-capture storage. Grepped for `http`/`Uri`/logging of frame or landmark data across all new files — none found. Gallery access remains scoped to the app's own private documents directory.

## Phase 13 — UI/UX polish

Added a composition icon to the guidance chip (`Icons.crop_free_rounded`) so the four guidance categories (position/attention/composition/lighting) are visually distinguishable. Onboarding uses the existing design tokens (`AppColors`, `AppSpacing`, `AppRadius`) rather than introducing new styling. No broader redesign attempted, per the instruction not to over-polish.

## Phase 14 — Documentation

This report, plus updates to `docs/ROADMAP.md`, `docs/IMPLEMENTATION_REPORT.md`, and `docs/PROJECT_AUDIT.md` (see those files for the specific diffs).

---

# P1 FINAL STATUS

Camera: UNVERIFIED (implemented, hardened, never run)
Pose: UNVERIFIED (implemented, hand-verified logic, never run)
Guidance: UNVERIFIED (implemented, hand-verified logic including new 4-way merge, never run)
Lighting: UNVERIFIED (implemented, two known bugs fixed and re-confirmed fixed, never run)
Composition: UNVERIFIED (implemented this pass, narrowly scoped to headroom, never run)
Chin/Eye: PARTIAL, UNVERIFIED (yaw/"face the camera" implemented; chin pitch explicitly not implemented — see Phase 5)
Gallery: UNVERIFIED (implemented, two real gaps found and fixed this pass, never run)
Onboarding: UNVERIFIED (implemented this pass, never run)
Performance: UNVERIFIED (no profiling possible without a device)
Tests: UNVERIFIED — meaning "written and hand-traced, not executed," not "unknown quality." (BLOCKED on toolchain, not skipped)
Build: BLOCKED (no network access to pub.dev/Flutter SDK host in this environment)

Overall P1: **IMPLEMENTED BUT REAL-DEVICE VERIFICATION PENDING** — using the exact phrasing this pass's own instructions require rather than "complete," because zero lines of any of this have been compiled or run by anything other than a human reading them.

## 1. Critical bugs found
None new and unfixed. Two were found and fixed mid-implementation this pass (Phase 7's gallery gaps); none rise to the severity of the P0 hardening pass's lifecycle bug.

## 2. Bugs fixed
- Gallery full-screen viewer had no error handling for a vanished file (Phase 7).
- Gallery thumbnails decoded at full resolution instead of a bounded thumbnail size (Phase 7).
- (Re-confirmed still fixed, not new) Lighting format-detection and NV21 chroma-contamination bugs from the prior pass.

## 3. Remaining bugs
None known. The honest caveat is that "none known" reflects the limits of static review — a real device run is what would surface anything this pass couldn't see.

## 4. Real-device tests still required
Everything in `docs/DEVICE_TESTING_CHECKLIST.md`, plus, specific to this pass:
- Composition headroom thresholds (0.04-0.24 range) were chosen by reasoning about normalized coordinates, not measured against real framing — likely need tuning after seeing real footage.
- Attention/yaw detection's ear-likelihood thresholds (0.45 enter / 0.30 clear) are similarly untested against real ML Kit output variance.
- Device-tier thresholds (≤4 cores = low, ≤6 = medium, >6 = high) should be checked against a few real device core counts to confirm the buckets land where intended.
- Onboarding's `shared_preferences` persistence needs a real relaunch test, not just a mocked unit test.

## 5. Architecture risks
None new. The feature-first structure absorbed four new modules (composition, device, onboarding, plus the attention engine inside guidance) without needing to touch `GuidanceEngine`, `CameraService`, or `PoseDetectionService` — the seam the P0 architecture was designed around held up under real pressure to add features fast.

## 6. Exact next milestone
Push to a remote, let `.github/workflows/flutter_ci.yml` actually run, fix whatever it finds, then work through `docs/DEVICE_TESTING_CHECKLIST.md` (extended, if useful, with the four items in section 4 above) on a real device. Only after that should P2 personalization begin — and at that point there will finally be a real app producing real sessions for it to learn from.
