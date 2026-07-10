# AI Visual Director — Engineering Foundation

> **Day 1 — Foundation Sprint Complete.**
> Day 2 (Design System) and beyond build on top of this layer.

## Architecture

Feature-first + Clean Architecture. Every feature owns its own
`presentation` / `domain` / `data` layers as needed. Cross-cutting
concerns live under `core/`.

```
lib/
├── main.dart                       # Bootstrap (zone-guarded)
├── app.dart                        # MaterialApp.router root
│
├── core/                           # Cross-cutting (no business logic)
│   ├── config/                     # AppConfig, AppEnv (flavors)
│   ├── constants/                  # App-wide constants
│   ├── theme/                      # Material 3 theme system
│   │   └── extensions/             # ThemeExtension tokens
│   ├── routing/                    # GoRouter + paths + names
│   ├── di/                         # Riverpod composition root
│   ├── error/                      # Failures, exceptions, ErrorHandler
│   ├── logging/                    # AppLogger facade + adapter
│   ├── extensions/                 # BuildContext helpers
│   ├── utils/                      # Pure helpers (validators, etc.)
│   └── network/                    # Dio client (Day 8+)
│
├── features/                       # One folder per feature
│   ├── splash/
│   ├── onboarding/
│   ├── auth/
│   │   ├── domain/                 # entities, repositories, use-cases
│   │   ├── data/                   # datasources, models, repos
│   │   └── presentation/           # screens, widgets, providers
│   ├── home/
│   ├── camera/
│   └── ...
│
└── shared/                         # Truly cross-feature primitives
    ├── widgets/                    # (Day 2)
    ├── models/
    └── providers/
```

## Key Decisions

| Concern              | Choice                          | Why                                         |
| -------------------- | ------------------------------- | ------------------------------------------- |
| State management     | Riverpod 2.x                    | Compile-safe, testable, no BuildContext dep |
| Routing              | GoRouter                        | Official, declarative, deep-link ready      |
| DI                   | Riverpod providers              | Avoids dual `get_it` + Riverpod systems     |
| Theme                | Material 3 + ThemeExtension     | Semantic tokens, dark-mode lerp             |
| Env config           | `flutter_dotenv` + `dart-define` | Multi-flavor, CI-overridable                |
| Logging              | `logger` + `AppLogger` facade   | Swap impls without touching call sites      |
| Error handling       | `Either<Failure, T>` (fpdart)   | Errors as values; UI never sees exceptions  |

## Running

```bash
# Install dependencies
flutter pub get

# Run in a flavor
flutter run --dart-define=ENV=dev      # default
flutter run --dart-define=ENV=staging
flutter run --dart-define=ENV=prod

# Analyze
flutter analyze

# Run code generation (when adding @riverpod annotations later)
dart run build_runner watch --delete-conflicting-outputs
```

## Quality Checklist (Day 1)

- [x] Clean Architecture folder structure
- [x] Material 3 theme system with semantic tokens
- [x] GoRouter with named routes + auth guard
- [x] Riverpod as DI + state management
- [x] Environment configuration (3 flavors)
- [x] Constants centralized
- [x] Logging facade (Crashlytics-ready)
- [x] Error handling: `Failure` sealed class + `ErrorHandler`
- [x] Extensions for terse widget code
- [x] Bootstrap error handling (FlutterError + PlatformDispatcher)
- [x] All screens compile (placeholders for Day 3-5 work)
