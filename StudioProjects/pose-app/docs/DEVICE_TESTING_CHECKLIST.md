# DEVICE_TESTING_CHECKLIST.md

Everything below requires a real device or emulator and could not be checked in the development sandbox (see `docs/P0_VERIFICATION_REPORT.md` §1 for why). Run in order — later items assume earlier ones pass.

Run `./scripts/verify.sh` first. If it fails, fix that before starting this list.

## 1. Basic boot
- [ ] `flutter run` launches without crashing
- [ ] Camera permission dialog appears on first launch
- [ ] Denying permission shows the "Camera access needed" screen, not a blank/frozen one
- [ ] Tapping "Allow Camera Access" after a denial re-prompts correctly
- [ ] Granting permission shows the live camera preview within a couple of seconds

## 2. Core guidance loop
- [ ] Standing centered and well-framed eventually shows "চমৎকার। এভাবে থাকুন।" (Perfect. Hold.) with the shutter ring lit
- [ ] Stepping left of frame shows "একটু ডানে যান" (move right)
- [ ] Stepping right of frame shows "একটু বামে যান" (move left)
- [ ] Standing too close shows "একটু পিছনে যান" (step back)
- [ ] Standing too far shows "একটু কাছে আসুন" (step closer)
- [ ] Tilting shoulders shows "কাঁধ সোজা রাখুন" (level your shoulders)
- [ ] Walking out of frame shows "ফ্রেমের মধ্যে আসুন" (step into frame), not a frozen or blank state

## 3. Stability (this is what the hardening pass specifically targeted)
- [ ] Standing near the left/right centering boundary does NOT flicker rapidly between "move left" and "move right"
- [ ] Standing near the close/far framing boundary does NOT flicker between "step closer" and "step back"
- [ ] Guidance does not visibly stutter or lag more than ~0.5s behind actual movement

## 4. Front camera — HIGHEST PRIORITY, this is the least-confident fix in the whole pass
- [ ] Switch to front camera via the lens-switch button
- [ ] Physically move to your right (the direction YOU experience as right, looking at the mirrored preview)
- [ ] Confirm the app says "move left" (একটু বামে যান) — i.e., guidance direction matches what you see in the mirrored preview, not the raw sensor
- [ ] If this is backwards, the mirroring fix in `pose_detection_service.dart` needs its sign flipped — report back immediately, this is a trust-damaging bug if wrong

## 5. Lifecycle — this is what was actually broken before the hardening pass
- [ ] Start the camera, background the app (home button), wait a few seconds, reopen it
- [ ] Confirm the app does NOT crash and the camera preview resumes
- [ ] Repeat the background/resume cycle 3-4 times in a row
- [ ] Revoke camera permission from system settings while the app is backgrounded, then resume — confirm it shows the permission-denied screen, not a crash
- [ ] Force another camera app open briefly (or trigger a phone call) while this app is in the foreground, confirm no crash and a sensible error/recovery

## 6. Capture
- [ ] Manual shutter button captures a photo even when guidance isn't showing "Perfect"
- [ ] Capturing does not freeze the preview for more than ~1 second
- [ ] Guidance resumes after a capture completes

## 7. Device tier (no profiling was possible without hardware)
- [ ] Test on at least one lower/mid-tier Android device, not just a flagship
- [ ] Note whether the preview stays smooth (no visible stutter) with guidance running
- [ ] Note approximate battery drain over a 5-minute session, if noticeable

## 8. Low-confidence handling
- [ ] Point the camera at a wall / empty room — confirm it shows "step into frame," not a wrong/confident-sounding instruction
- [ ] Very low light — confirm guidance degrades to "step into frame" rather than guessing

---

Report back pass/fail for each numbered section, not just item-by-item — that's enough for a fast go/no-go on P1 readiness.
