# P0_VERIFICATION_REPORT.md

## Audit date
2026-08-22 (hardening pass, following the initial P0 implementation)

## How to read this report
Every finding below is labeled honestly:
- **VERIFIED** — actually confirmed true by running something or by exhaustive manual trace.
- **UNVERIFIED** — plausible/likely correct based on documented library behavior, but not confirmed on a device or by a compiler in this session.
- **BLOCKED** — could not be checked at all in this environment, and why.
- **FIXED** — a real defect was found and corrected in code.
- **KNOWN LIMITATION** — a real gap that is being deliberately left for a later pass, with the reason stated.

Nothing in this report claims a PASS that wasn't actually produced by a tool or an exhaustive trace.

---

## 1. Build verification — BLOCKED

This sandbox's egress proxy returns HTTP 403 for both `pub.dev` and `storage.googleapis.com` (confirmed by direct `curl` before writing anything below) — the two hosts Flutter needs to resolve packages and install the SDK, respectively. There is no Flutter/Dart toolchain available here, and none can be installed.

As a result:

| Command | Status |
|---|---|
| `flutter pub get` | **BLOCKED** — no network access to pub.dev |
| `flutter analyze` | **BLOCKED** — no Flutter SDK in this environment |
| `flutter test` | **BLOCKED** — same |
| `flutter build apk --debug` | **BLOCKED** — same |

**What was done instead, per the task's own fallback instruction:** a full manual static review of every file — import-by-import, symbol-by-symbol — cross-checking against the actual public API surface of `camera`, `google_mlkit_pose_detection`, and `flutter_riverpod`/`state_notifier` as documented, and hand-tracing the new unit tests against the implementation line by line rather than assuming they'd pass.

**This is not a substitute for a real build.** Treat every "UNVERIFIED" label below as a required check on your machine before this code is trusted.

## 2. Real bugs found and fixed this pass

These aren't style nits — each one would have caused a real, user-visible failure.

### FIXED — Critical: background/resume crashed the app
**Where:** `camera_screen.dart` → `didChangeAppLifecycleState`, `camera_session_controller.dart`.
**What was wrong:** backgrounding the app called `ref.read(cameraSessionProvider.notifier).dispose()` — the real `StateNotifier.dispose()`. `StateNotifier` is terminal: once disposed, any further `state = ...` assignment throws (`Bad state: Tried to use CameraSessionController after dispose() was called`). Resuming the app then called `.initialize()` on that same, already-disposed notifier, which would throw as soon as it tried to set state.
**Fix:** split camera-resource teardown from notifier disposal. Added `pauseSession()` / `resumeSession()`, which only release/reacquire the `CameraController` and image stream; the `StateNotifier` itself is never disposed until Riverpod tears down the provider for good. `didChangeAppLifecycleState` now calls these instead.
**Confidence:** VERIFIED by trace (the old code path is unambiguous — `StateNotifier`'s dispose contract is documented and this is a direct violation of it). Still needs a real background/foreground cycle on a device to confirm the fix, which is UNVERIFIED beyond the trace.

### FIXED — Likely compile error: reference to a `mounted` getter that doesn't exist
**Where:** `camera_session_controller.dart`, original `_onFrame`.
**What was wrong:** `if (pose == null || !mounted) return;` — `StateNotifier` (from the `state_notifier` package that backs Riverpod's `StateNotifierProvider`) does not expose a public `mounted` getter in its documented API. This was very likely an analyzer/compile error waiting to be caught by `flutter analyze`, which this session couldn't run.
**Fix:** replaced with an explicit `_disposed` boolean the controller manages itself, checked before every `state =` assignment that follows an `await` or an async callback.
**Confidence:** UNVERIFIED that it would have failed to compile (BLOCKED on toolchain access), but the replacement is unambiguously correct either way, so this is fixed regardless of whether the original was actually a compile error.

### FIXED — High risk: NV21 image bytes potentially truncated before reaching ML Kit
**Where:** `pose_detection_service.dart`, `_toInputImage`.
**What was wrong:** the original code passed only `image.planes.first.bytes` to `InputImage.fromBytes`. On Android, `ImageFormatGroup.nv21` can be delivered as multiple planes on some plugin/device combinations; sending only the first plane would silently drop the chroma (UV) data, feeding ML Kit a truncated/garbage buffer.
**Fix:** defensively concatenate all planes' bytes when more than one is present (matches the pattern used in ML Kit's own official Flutter samples). Degrades to a no-op in the single-plane case.
**Confidence:** UNVERIFIED — genuinely device/plugin-version dependent and cannot be confirmed without running on real Android hardware. The fix is strictly safer than the original in every case, so it's a correct defensive change regardless.

### FIXED — High risk: front camera guidance direction likely mirrored
**Where:** `pose_detection_service.dart`, landmark extraction.
**What was wrong:** ML Kit returns landmark coordinates in the unmirrored sensor image's pixel space; `CameraPreview` renders the front camera mirrored (so the user sees a normal mirror image of themselves). Without correcting for this, "move left" guidance would point the wrong direction whenever the front camera is active.
**Fix:** flip the normalized x-coordinate (`1 - x`) for all landmarks when `lensDirection == CameraLensDirection.front`.
**Confidence:** UNVERIFIED. This mirroring behavior is the commonly documented contract for this plugin combination, but it has NOT been confirmed against a real front camera on a real device. **This is the single highest-priority item for device QA before shipping**, because a wrong-direction bug here actively damages user trust (spec §23) rather than just looking unpolished.

### FIXED — Real logic bug in the new hysteresis code (found via test tracing, not by running tests)
**What was wrong:** the first draft of the "how long since a confident detection" counter reset to 0 on any frame with non-empty landmarks — including low-confidence ones — then incremented in the low-confidence handler. Net effect: the counter could never exceed 1, so sustained low-confidence input would get stuck showing "searching" forever and never correctly escalate to "low confidence".
**Fix:** the reset now only happens on a genuinely confident detection; both "no landmarks" and "landmarks but below threshold" share one `_handleGap()` path that increments the counter.
**Confidence:** VERIFIED by hand-tracing every new unit test against the corrected implementation, frame by frame. Not VERIFIED by actually executing the test suite (BLOCKED on toolchain).

### FIXED — Real gap against the required lifecycle scenario list: "camera becomes unavailable"
**What was wrong:** nothing listened to `CameraController`'s own error signal (`value.hasError` / `errorDescription`). If the camera hardware became unavailable mid-session (another app took it, an OEM-specific failure), the preview would freeze with no error state and no way for the user to recover.
**Fix:** added a `CameraController` listener that transitions to `CameraSessionStatus.error` with the plugin's own error description when `hasError` becomes true. Listener is correctly attached/detached across `initialize()`, `switchLens()`, `pauseSession()`, and `dispose()` to avoid leaking a stale listener on a disposed controller.
**Confidence:** UNVERIFIED — this failure mode is inherently hard to trigger without a real device and another app fighting for the camera.

### FIXED — Unnecessary full-screen rebuilds on every pose frame
**What was wrong:** `CameraScreen.build` watched the entire `CameraSessionState` object, which changes 6-10 times/second once pose detection is running. Every guidance update rebuilt the whole widget tree, including `CameraPreview`.
**Fix:** switched to `ref.watch(cameraSessionProvider.select(...))` at three separate scopes — screen-level status (rare changes), the camera preview (only rebuilds when `controller` identity changes), and two small leaf widgets (`_GuidanceOverlayBinding`, `_CaptureButtonBinding`) that alone absorb the frequent guidance/capture updates.
**Confidence:** VERIFIED as a correct use of Riverpod's `select` API by inspection; the actual rebuild-frequency improvement is UNVERIFIED without a profiler (BLOCKED — no device).

### FIXED — Removed a dead/unused import
`camera_session_controller.dart` imported `guidance_message.dart` without referencing any symbol from it after refactoring — would have been an `unused_import` analyzer warning. Removed.

## 3. Frame processing / backpressure — VERIFIED by trace, UNVERIFIED on device

The pipeline now has two independent "latest-frame-wins" guards:
1. `PoseDetectionService._isBusy` — the detector itself won't accept a new frame while a previous `processImage` call is in flight.
2. `CameraSessionController._isProcessingFrame` — an additional controller-level guard so that even if two frame callbacks fire in quick succession before the first `.then()` resolves, only one is actually forwarded to the pose service.

Combined with frame sampling (every 3rd frame), frames are never queued — a frame arriving while busy is simply dropped, not buffered. This was traced by reading the code path, not measured on a device (no profiler access — BLOCKED).

## 4. Guidance stability — VERIFIED by exhaustive unit-test trace

Every test in `test/guidance_engine_test.dart` was traced by hand against the corrected `GuidanceEngine` implementation (constant-by-constant, frame-by-frame), including the debounce/hysteresis tests specifically designed to catch the "flickers between move left and move right" failure mode the task called out. All traced correctly to their expected assertions after the counter bug (§2 above) was fixed. This is NOT the same as having actually run `flutter test` — that remains BLOCKED.

The explicit state machine required by the task (`PoseTrackingState`: `noPerson`, `searching`, `lowConfidence`, `guidance`, `ready`, `hold`, `error`) is now implemented and returned by every code path in `GuidanceEngine.evaluate()`.

## 5. Coordinate transformation / rotation / mirroring — PARTIALLY VERIFIED, real gaps remain

- **Front-camera mirroring:** addressed (§2 above), UNVERIFIED on device.
- **NV21 plane handling:** hardened defensively (§2 above), UNVERIFIED on device.
- **Device rotation (landscape):** **KNOWN LIMITATION, deliberately deferred.** The rotation passed to ML Kit (`sensorOrientation`) does not account for the device's current physical orientation, only the camera sensor's fixed mounting angle. Full correctness requires tracking device orientation (accelerometer or platform orientation channel) and combining it with sensor orientation and lens direction — real complexity that wasn't part of this hardening pass's scope (the task explicitly says not to add new features). Instead, **the app is now locked to portrait orientation** on both Android (`android:screenOrientation="portrait"`) and iOS (`Info.plist` trimmed to portrait-only) and at the Flutter level (`SystemChrome.setPreferredOrientations`). This doesn't fix rotation handling — it removes the scenario where the bug would manifest, which is the honest, bounded thing to do in a hardening pass rather than silently shipping a latent bug.

## 6. Privacy review — VERIFIED by code inspection

- No network calls exist anywhere in the camera/pose/guidance pipeline — confirmed by grepping for `http`, `Uri`, `Dio`, `Socket` across `lib/features/` (none found outside this report itself).
- No frame or landmark data is persisted to disk — only explicit user captures are written to the app's documents directory via `capturePhoto()`.
- No `print`/`debugPrint`/`log` calls exist that would leak frame data, landmark coordinates, or file paths to system logs — confirmed by grep.
- Camera permission is requested explicitly and denial is handled with a dedicated UI state, not silently ignored.

## 7. Android / iOS configuration review

- `minSdk` pinned to 21 (ML Kit's documented floor) — **UNVERIFIED** that this doesn't conflict with any other plugin's requirement (would need `flutter pub get` to resolve the full dependency graph — BLOCKED).
- Camera permission + hardware features declared in the Android manifest — VERIFIED present by inspection (were absent before the original P0 slice).
- `NSCameraUsageDescription` present in iOS `Info.plist` — VERIFIED present by inspection.
- No ProGuard/R8 rules added. **KNOWN LIMITATION:** ML Kit's on-device models sometimes need explicit `-keep` rules for release builds to avoid reflection-related crashes after minification. Not addressed in this pass because it only manifests in `flutter build apk --release` (not `--debug`), and release-build hardening is reasonably scoped to a later pass focused specifically on release readiness.

## 8. Test coverage added this pass

| File | What it covers | Hardware needed? |
|---|---|---|
| `test/guidance_engine_test.dart` | State machine transitions, confidence gating, framing/centering/tilt rules, hold-streak debounce, direction-switch debounce, hysteresis band, error handling, reset | No |
| `test/camera_state_test.dart` | `CameraSessionState.copyWith` semantics, including a documented quirk (`errorMessage` doesn't self-preserve like other fields) | No |
| `test/guidance_overlay_widget_test.dart` | `GuidanceOverlay` renders nothing/correction/confirmation correctly | No |
| `test/permission_request_view_widget_test.dart` | Permission UI shows the right action for first-request vs. permanently-denied, and calls back correctly | No |
| `test/widget_test.dart` | App boots into a loading state without throwing | No |

None of these were actually executed (BLOCKED on toolchain) — all were hand-traced against the implementation. **Not tested at all, and not testable without a device:** anything touching the real `camera` plugin or the real ML Kit detector (permission dialogs, actual frame capture, actual pose inference, actual lifecycle transitions end-to-end).

## 9. Performance — UNVERIFIED / BLOCKED

No FPS measurement, no inference-latency measurement, no memory/battery/thermal profiling was possible in this environment. The architectural choices made (frame sampling at 1-in-3, medium resolution preset, latest-frame-wins backpressure, scoped Riverpod rebuilds) are reasoned engineering decisions, not measured results. Treat every performance claim in `docs/PROJECT_AUDIT.md` the same way.

---

# P0 VERIFICATION SUMMARY

Build: **BLOCKED** (no toolchain/network access in this environment)
Analyze: **BLOCKED**
Tests: **BLOCKED** (written and hand-traced, not executed)
Debug APK: **BLOCKED**
Camera: **UNVERIFIED** (lifecycle bug found and fixed by trace; real device confirmation still required)
Pose: **UNVERIFIED** (two real correctness risks found and defensively fixed — NV21 planes, front-camera mirroring — neither confirmed on device)
Guidance: **VERIFIED by exhaustive trace** (state machine + debounce/hysteresis logic correct against all written tests; not confirmed by actually running them)
Performance: **UNVERIFIED / BLOCKED** (no profiling possible)
Privacy: **VERIFIED by code inspection** (no network calls, no unnecessary persistence, no sensitive logging)
Architecture: **VERIFIED by inspection** — clean layering held up under a real hardening pass; the one critical lifecycle bug was a usage mistake at the call site, not a structural architecture problem, and was straightforward to fix without restructuring anything

## Critical Issues
All identified critical issues (background/resume crash, likely `mounted` compile error, NV21 truncation risk, front-camera mirroring risk, hysteresis counter bug, missing camera-error handling, unnecessary rebuilds) have been **fixed in code** — see §2. None remain open at the "critical" severity.

## Fixed Issues
Seven concrete defects, listed in full in §2, all fixed in this pass.

## Remaining Issues
- Device rotation / landscape support is not implemented — mitigated by locking to portrait, not solved (§5).
- ProGuard/R8 keep rules for ML Kit not yet added — only matters for release builds (§7).
- No gallery/history UI for captured photos (already known, out of scope — see `docs/ROADMAP.md`).

## Device Testing Required
Before this is trusted as working software, the following MUST be confirmed on real hardware, in this order:
1. `flutter pub get && flutter analyze && flutter test` — confirms the code actually compiles and the traced tests actually pass.
2. `flutter run` on a real Android device — confirms camera opens, permission flow works, guidance appears.
3. Explicitly test: background the app mid-session, then resume — confirms the lifecycle fix actually works (this is the one that would have crashed 100% of the time before this pass).
4. Switch to front camera and physically move left/right — confirms the mirroring fix points the right direction.
5. Test on at least one low/mid-tier Android device — confirms frame sampling keeps the UI responsive (no profiling was possible here).
6. Test with a screen protector / low light / no light — confirms low-confidence handling degrades gracefully rather than giving bad guidance.

## P1 Readiness
**Not yet ready to declare "ready for P1."** The architecture and guidance logic are in good shape and the critical lifecycle bug is fixed, but zero lines of this code have been compiled or run by anything other than a human tracing it by hand. Declaring P1-readiness before Device Testing Required (above) is completed would violate the task's own instruction not to claim success without evidence.

## Exact Next Step
Run the six device-testing steps above, in order, and report back what breaks. Steps 1-3 are the minimum bar — if those three pass cleanly, the foundation is genuinely solid and P1 (chin/eye guidance, composition v1) is a reasonable next move. If step 1 alone surfaces compile errors, fix those first before any device testing.

**Update — this environment has no path to a Flutter toolchain at all**, confirmed again by checking Ubuntu's apt repos (Dart isn't packaged there either — it lives behind the same blocked Google host). So "run this locally and paste results back" was the only route to real verification, which put every future check at the mercy of someone remembering to run it. Three things now exist to fix that:

- `.github/workflows/flutter_ci.yml` — runs `pub get`, `analyze --fatal-infos`, `dart format --check`, `test`, and `build apk --debug` automatically on every push/PR, and uploads the debug APK as a build artifact. This is now the real source of truth for "does it compile," independent of any one machine.
- `scripts/verify.sh` — the identical steps, runnable locally with one command before pushing, so CI failures aren't a surprise.
- `docs/DEVICE_TESTING_CHECKLIST.md` — turns the six items above into a concrete, checkable list ordered by risk. Front-camera mirroring and the background/resume lifecycle fix are flagged as highest priority, since those are the two fixes this pass is least confident about without real hardware.

None of this makes the BLOCKED items above VERIFIED — CI hasn't run yet either, since nothing has been pushed to a remote from this session. It does mean the next real verification doesn't depend on this sandbox: push this branch, let CI run, and paste back either a green check or the failure log.
