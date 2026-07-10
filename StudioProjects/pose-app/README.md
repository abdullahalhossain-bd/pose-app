# AI Visual Director

A Personal Photography Intelligence Platform.

Built on Flutter with Material 3, Riverpod, GoRouter, and Clean Architecture.

> **Status:** Day 1–7 Foundation Sprint complete.
> See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) and
> [`docs/ENGINEERING_REVIEW.md`](docs/ENGINEERING_REVIEW.md) for full details.

## Quick Start

```bash
flutter pub get
flutter run --dart-define=ENV=dev
```

## Tech Stack

- **Flutter** (stable, SDK ≥ 3.12)
- **Riverpod 2.x** — state management + DI
- **GoRouter** — declarative routing with auth guard
- **Material 3** — theme system with `ThemeExtension` design tokens
- **fpdart** — `Either<Failure, T>` for error-as-values
- **flutter_dotenv** — multi-flavor environment config
- **shared_preferences** — local persistence (session, theme mode)
- **dio** — HTTP client (wired on Day 8+)
- **camera** — capture pipeline
- **permission_handler** — runtime permissions
- **photo_manager** — gallery (Day 8+)

## Project Layout

Feature-first + Clean Architecture. See
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Sprint Roadmap

| Day | Focus                                                    | Status |
| --- | -------------------------------------------------------- | ------ |
| 1   | Foundation (Clean Arch, Material 3, Riverpod, Router)    | ✅     |
| 2   | Design System (reusable widgets)                         | ✅     |
| 3   | Auth flow (splash, onboarding, login, profile setup)     | ✅     |
| 4   | Home module (bottom nav, search, history, settings)      | ✅     |
| 5   | Camera foundation (UI only — no AI yet)                  | ✅     |
| 6   | Polish (animations, accessibility, theme persistence)    | ✅     |
| 7   | Engineering review + refactor                            | ✅     |

## Running Tests

```bash
flutter test
```

Coverage: validators, failures, local auth repository.

## License

Proprietary. All rights reserved.
