# PROJECT_AUDIT.md

## Audit date
2026-08-22

## Scope
Full inspection of the `pose-app` repository prior to any implementation work, followed by a second-pass assessment of the P0 slice delivered in this session.

---

## 1. Baseline state (before this session)

The repository, despite being named `pose-app`, contained **no product code**. Every file in `lib/`, `pubspec.yaml`, `android/app/src/main/AndroidManifest.xml`, and `test/widget_test.dart` was the unmodified output of `flutter create` — the default counter demo, including its tutorial comments. There were:

- No camera integration
- No pose detection
- No AI/guidance logic of any kind
- No state management dependency
- No permission declarations (camera permission was **not** in the Android manifest or iOS Info.plist)
- No architecture, folders, or layering
- No design system or theme
- One test file, testing the counter demo

This is a meaningful finding in itself: nothing in the earlier product spec had been started. There was no legacy design debt to preserve — but also no working baseline to compare against. Any audit scoring this baseline against the 8 categories in the original brief (Architecture, UI/UX, Code Quality, etc.) would score 0-1/10 across the board simply because there was nothing to evaluate; that would not be a useful signal, so it's recorded here as a fact rather than as scored table.

## 2. What this session built (P0 slice)

Given the baseline, "audit → preserve good work → refactor weak work" collapsed to a single case: nothing existed to preserve, so this slice **implements the P0 MVP core** on the architecture the product spec calls for, rather than fixing prior code.

Delivered:
- Feature-first / clean-architecture folder structure (`core/`, `features/camera`, `features/pose`, `features/guidance`, with `data/domain/application/presentation` layers)
- Real camera integration (`camera` plugin): permission flow, lifecycle handling (pause/resume), lens switching, capture
- Real on-device pose detection (`google_mlkit_pose_detection`), isolated behind a domain-typed service so the vendor SDK touches exactly one file
- A rule-based guidance engine translating landmarks into one prioritized instruction at a time (framing → centering → shoulder level → hold), in English and Bengali
- Riverpod-based state management wiring camera + pose + guidance into one reactive controller, with explicit UI states (loading, permission-denied, error, ready) — no blank-screen states
- Frame sampling (every 3rd frame) so inference doesn't run on every camera frame
- Premium dark theme / design tokens (colors, spacing, radius) built for a camera-first, minimal UI
- Camera screen UI: full-bleed preview, single guidance chip, capture button with "ready" ring, lens-switch control
- Unit tests for the guidance engine's rule logic (11 cases covering confidence gating, framing, centering, tilt, happy path)
- Manifest/Info.plist updates: Android `CAMERA` permission + camera hardware feature declarations, iOS `NSCameraUsageDescription`, `minSdk` pinned to 21 (ML Kit's floor)

### What is deliberately NOT in this slice
Per the product spec's own instruction not to build everything at once (§8, §32): no auto-capture, no composition/lighting intelligence, no gallery/history screen, no personalization/Pose DNA, no group intelligence, no analytics, no cloud AI, no accessibility pass beyond system defaults. These are staged in `docs/ROADMAP.md`.

## 3. Scored assessment of the delivered slice

Scoring what now exists, against what a P0 camera+guidance MVP should look like (not against the full long-term platform vision, which is out of scope for one slice):

| Category | Score /10 | Notes |
|---|---|---|
| Architecture | 7 | Clean layering and a real seam between vision/guidance/UI. Not yet proven under load — see Section 4. |
| UI/UX | 6 | Core states and single-instruction guidance UX are in place; visually minimal but unpolished (no motion design, no onboarding, no empty/history states). |
| Code Quality | 7 | No god classes, named constants instead of magic numbers, docs comments tie code back to spec sections. Not yet linted/analyzed (see limitations). |
| AI Architecture | 6 | Rule-based engine is transparent and testable, matches the "no fake personalization" principle. It is not yet validated against a real device camera stream. |
| Performance | Unscored | No device or profiler available in this environment — see Section 4. |
| Scalability | 6 | Guidance engine designed to be swapped for a learned/personalized decision engine later without touching camera/UI code. |
| Security/Privacy | 6 | On-device inference only, no network calls added, permission flow present. No data-retention/consent screens yet. |
| Testing | 4 | Guidance logic has real unit test coverage. No widget tests for camera states, no integration tests (both require a device/emulator this environment cannot run). |

## 4. Real limitations of this audit — stated plainly

This sandbox has no Flutter/Dart SDK and no camera hardware. That means:
- **`flutter pub get`, `flutter analyze`, and `flutter test` have not been run.** The code is written to compile against the stated package versions and current camera/ML Kit APIs, but it has not been verified to build.
- No performance profiling (FPS, inference latency, memory, battery, thermal — spec §20) has been or could be done here.
- No testing on low/mid/high-end devices (spec §21) has been done.
- Package version numbers were set from general knowledge, not fetched from pub.dev at time of writing (this sandbox doesn't have network access to pub.dev) — treat them as a starting point to double-check with `flutter pub outdated` on your machine.

**Recommended next action on your end:** clone this slice locally, run `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter run` on a real device, and report back anything that fails so it can be fixed in the next iteration.

## 5. Hardening pass (see docs/P0_VERIFICATION_REPORT.md for full detail)

A follow-up session performed a full static verification and hardening pass rather than proceeding to P1. Confirmed via direct `curl`: this environment's network policy blocks both `pub.dev` and `storage.googleapis.com` with HTTP 403, so no build/analyze/test could actually be executed — everything below came from manual code inspection and exhaustive hand-tracing, not tool output.

That pass found and fixed **seven real defects**, the most serious being a lifecycle bug where backgrounding the app called the real `StateNotifier.dispose()` instead of just releasing camera resources — meaning the very first background→foreground cycle would have crashed the app on a real device. Full details, honest VERIFIED/UNVERIFIED/BLOCKED/FIXED labels, and the required device-testing checklist are in `docs/P0_VERIFICATION_REPORT.md`. The scores in Section 3 above predate that pass and should be read as "at time of initial implementation," not current.

## 6. P1 completion pass

A follow-up pass finished the remaining P1 features (composition intelligence v1, attention/face-camera guidance, onboarding, device-tier detection) and audited the previously-shipped gallery feature, finding and fixing two more real gaps. Full phase-by-phase detail in `docs/P1_COMPLETION_REPORT.md`. Toolchain access remains blocked in this environment — every claim in that report is either VERIFIED-by-inspection or explicitly labeled UNVERIFIED/BLOCKED, never assumed passing.
