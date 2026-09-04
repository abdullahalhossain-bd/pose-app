# Pose

Pose is a mobile-first fitness product focused on helping people improve exercise form with camera-based pose analysis.

## Current status

**MVP foundation — not production ready yet.**

The app now has a polished product shell, local workout history, progress tracking, and an exercise-expansion architecture for squat, push-up, and lunge.

## Product loop

1. User chooses an exercise.
2. User grants camera permission.
3. On-device pose estimation tracks body landmarks.
4. An exercise-specific analyzer evaluates movement phases and form heuristics.
5. User receives immediate feedback.
6. Rep scores and session results are saved locally.

## Engineering principles

- Prefer on-device inference for privacy and latency.
- Never present uncertain pose estimates as fact; use low-confidence guidance.
- Keep detection, exercise rules, session state and UI separate.
- The core product must work without a paid LLM/API call.
- Validate exercise rules with landmark fixtures before trusting real-time behavior.
- Do not claim production readiness until CI and physical-device camera validation pass.

## Phase 5 — Exercise Expansion

- Squat: existing validated MVP flow.
- Push-up: analyzer, rep phases, depth/alignment scoring and live feedback.
- Lunge: analyzer, rep phases, depth/torso scoring and live feedback.
- Exercise catalog and registry for scalable additions.
- Generic live exercise camera flow.
- Exercise-aware local session summaries and progress breakdown.
- Automated analyzer tests and Flutter CI.

### Remaining validation gate

- `flutter analyze` must pass.
- `flutter test` must pass.
- Physical Android device must confirm camera permission, preview, pose detection, rep counting, confidence fallback and session persistence.
- Push-up/lunge thresholds remain beta heuristics until real-device fixture testing is completed.

## Run locally

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```
