# Pose

Pose is a mobile-first fitness product focused on helping people improve exercise form with camera-based pose analysis.

## Current status

**MVP foundation — not production ready yet.**

The repository started as the default Flutter counter application. This branch replaces that starter screen with the first product shell: dashboard, pose-check entry point, workout area, progress area and profile area.

## Product direction

The core loop should eventually be:

1. User chooses an exercise.
2. User grants camera permission.
3. Pose estimation tracks body landmarks on-device.
4. The app evaluates exercise-specific form rules.
5. User receives immediate, understandable feedback.
6. A session score and history are saved for progress tracking.

## MVP priorities

### P0 — must work
- Camera permission and camera preview.
- On-device pose landmark detection.
- Exercise-specific form rules, starting with squat.
- Real-time feedback with confidence thresholds and safe fallbacks.
- Session start/stop and summary.
- Local session history.

### P1 — retention
- More exercises.
- Progress charts and personal bests.
- Simple onboarding and goals.
- Better feedback explanations.

### P2 — business
- Freemium limits.
- Premium exercise programs.
- Analytics that respect user privacy.
- Crash/performance monitoring.

## Engineering principles

- Prefer on-device inference for privacy and latency where practical.
- Never present uncertain pose estimates as fact; expose an appropriate "move into frame" or "low confidence" state.
- Keep pose detection, exercise rules, session state and UI separate so new exercises do not require rewriting the app.
- Do not add an AI/LLM API merely for marketing value. The core product must work deterministically without a paid LLM call.
- Test exercise rules with recorded landmark fixtures before trusting real-time behavior.

## Run locally

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Roadmap

**Phase 1:** Product shell and architecture  ← current

**Phase 2:** Camera + pose estimation

**Phase 3:** Squat analysis + session scoring

**Phase 4:** History + progress

**Phase 5:** Beta testing, performance, privacy and store readiness
