# ROADMAP.md

Prioritization key: **P0** = critical/shipped this slice, **P1** = important next, **P2** = enhancement, **P3** = future/long-term moat.

## Status gate
A hardening pass (see `docs/P0_VERIFICATION_REPORT.md`) fixed seven real defects found by static review, including a critical lifecycle bug. It could not run `flutter pub get`/`analyze`/`test`/`build` — this environment has no network access to `pub.dev` or the Flutter SDK host. **P1 work should not start until the device-testing checklist in that report is completed and reported back.** If step 1 (`pub get && analyze && test`) surfaces compile errors, fix those before anything else.

A later request arrived claiming "P0 is verified, P1 is complete" — neither was true against this repo, and that was corrected rather than built on top of. Real status as of this update: **P0 still unverified on any real toolchain or device** (CI is set up in `.github/workflows/flutter_ci.yml` but hasn't been triggered — nothing has been pushed to a remote from any session); **P1 is partially done** — lighting intelligence v1 and a gallery screen are implemented (see `docs/IMPLEMENTATION_REPORT.md`), composition/chin-eye/onboarding/device-tier are not. P2 (personalization) has not been started and should not start until P1 is actually finished and P0 is confirmed working on a device — personalization needs real usage signals to learn from, and none exist yet because nothing has run outside this sandbox.

## P0 — Implemented and hardened, NOT yet confirmed on a real toolchain/device
- Camera preview, permissions, lifecycle, lens switch, manual capture
- On-device pose detection (single subject)
- Rule-based single-instruction guidance (framing, centering, shoulder level), with debounce/hysteresis and an explicit tracking-state machine added in the hardening pass
- Clean feature-first architecture with a swappable AI decision-engine seam
- Core UI states (loading/permission/error/ready)
- Unit tests for guidance logic (hand-traced, not executed — see status gate above)
- CI workflow (`.github/workflows/flutter_ci.yml`) exists but has never actually run — nothing has been pushed to a remote yet

## P1 — Implemented but real-device verification pending (see docs/P1_COMPLETION_REPORT.md)
- ✅ **Lighting intelligence v1** — brightness-based guidance, merged with pose/composition/attention.
- ✅ **Gallery/history screen** — grid, viewer, delete; two real gaps (missing error handling, unbounded thumbnail decode) found and fixed in the P1-completion pass.
- ✅ **Composition intelligence v1** — headroom only, by deliberate scoping decision (see `docs/P1_COMPLETION_REPORT.md` Phase 3 for why rule-of-thirds/symmetry/horizon are NOT in this version).
- ✅ **Attention guidance ("face the camera")** — head yaw via ear-likelihood asymmetry. Chin pitch explicitly NOT implemented — the available pose-landmark model can't reliably support it; would need `google_mlkit_face_detection`, a separate future addition.
- ✅ **Onboarding** — 4-slide flow, skippable, persisted via `shared_preferences`.
- ✅ **Device-tier detection** — core-count-based (`Platform.numberOfProcessors`), centralized in `PerformanceConfig`. Honestly not a real benchmark — see `docs/P1_COMPLETION_REPORT.md` Phase 9.
- ✅ **Zoom + Flash** — real per-device zoom bounds, pinch-to-zoom gesture, flash cycling (off/auto/torch).
- ✅ **AI Overlay** — skeleton, rule-of-thirds visual grid (not guidance text — see scoping note in `docs/IMPLEMENTATION_REPORT.md`), directional arrow. Off by default, toggleable.
- ✅ **Auto Capture** — countdown-based, sits on top of `GuidanceEngine`'s debounced hold signal, defaults to OFF (spec §5), 3s cooldown after firing. Manual shutter unaffected either way.
- ⬜ **Verification pass**: still not run — `flutter pub get`/`analyze`/`test`/`run` via CI or a real device. This is the actual remaining P1 blocker, not any unbuilt feature.
- ⬜ **Rule-of-thirds / symmetry / horizon composition**: deliberately deferred, needs a product decision on default photographic style (dead-center vs. rule-of-thirds) before it can be built without contradicting the existing centering guidance.
- ⬜ **Chin pitch guidance**: deliberately deferred, needs `google_mlkit_face_detection` integration.

## P2 — Enhancements
- Auto-capture (pose + stability + confidence threshold, always paired with manual override)
- Visual overlays: skeleton, framing guide, horizon line
- Voice guidance (accessibility + hands-free use)
- Haptic feedback for corrections
- Analytics events (spec §24 list), privacy-conscious, opt-in
- Multi-language guidance text beyond English/Bengali

## P3 — Future / long-term moat
- AI Memory / Pose DNA (personalization) — requires real usage data first, per spec §6
- Group Intelligence (2-20 people)
- Cinematic Mode / Reel Director
- Memory Recreation (recreate an old photo's framing)
- Child/Elder/Accessibility specialized modes
- Cloud AI for heavier future features (kept separate from the offline-first core loop)

## Explicitly deferred, not forgotten
Nothing in the original product spec was dropped — items not listed above as P0 simply haven't been reached yet. This file should be updated as each slice lands.
