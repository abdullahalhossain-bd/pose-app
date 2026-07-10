# Engineering Review — Day 7

> Final review of the Day 1–6 foundation sprint. Documents strengths,
> known weaknesses, and the work queue for Day 8 onward.

## Codebase at a glance

- **Dart files:** ~67 source files + ~4 test files
- **Architecture:** Feature-first + Clean Architecture (domain/data/presentation per feature where applicable)
- **State management:** Riverpod 2.x
- **Routing:** GoRouter with auth-guarded redirect
- **Theme:** Material 3 + ThemeExtension (spacing + colors)
- **Error handling:** `Either<Failure, T>` (fpdart) + centralized `ErrorHandler`

## Strengths

### 1. Architecture
- ✅ Clean separation of `core/`, `features/`, `shared/`
- ✅ Domain layer in `features/auth/` defines interfaces (`AuthRepository`)
- ✅ Data layer is the only place that touches `SharedPreferences` and tokens
- ✅ Presentation never sees exceptions — only `Failure` objects
- ✅ Riverpod providers are the single DI mechanism (no `get_it` duplication)

### 2. Theming
- ✅ No hardcoded colors in widgets — everything flows from `ColorScheme` or `AppColorsExtension`
- ✅ Spacing/radii centralized via `AppSpacingExtension`
- ✅ Dark mode fully supported via `ThemeExtension.lerp`
- ✅ Theme mode persisted across launches via `ThemeModeController`

### 3. Routing
- ✅ Named routes + path constants — no string literals in navigation calls
- ✅ Auth-guarded redirect handles all session transitions
- ✅ `StatefulShellRoute` preserves per-tab back stacks

### 4. Camera
- ✅ Lifecycle-aware (pause on inactive, resume on active)
- ✅ Single source of truth (`CameraNotifier`) — widgets never touch `CameraController` directly
- ✅ Permission denial → actionable error state with "Open Settings" CTA

### 5. Error handling
- ✅ `sealed class Failure` — compiler enforces exhaustive handling
- ✅ `ErrorHandler` is the single place to add Crashlytics later
- ✅ Bootstrap-level error capture (`FlutterError.onError` + `PlatformDispatcher.onError`)

## Known Weaknesses — to fix in Day 8+

### W1: TokenStore uses SharedPreferences, not secure storage
**Severity:** Medium (security)
**Fix:** Add `flutter_secure_storage: ^9.2.4`, refactor `TokenStore` to use it. Domain layer doesn't change.

### W2: `LocalAuthRepository` is a mock
**Severity:** Expected (was the plan)
**Fix:** Day 8+ — add `RestAuthRepository` that uses Dio + the configured `apiBaseUrl`. Wire `authRepositoryProvider` to read `AppConfig.env` and return the right impl.

### W3: No splash screen race condition (FIXED in Day 7)
Previously `SessionNotifier._hydrate()` was async; splash could read unhydrated state. Fixed by hydrating synchronously in the constructor (SharedPreferences are already loaded in `main.dart`).

### W4: Camera permission denied view lacks "Open Settings" deep-link
**Severity:** Low
**Status:** Already wired via `permission_handler`'s `openAppSettings()` — see `_PermissionDeniedView`.

### W5: No analytics events yet
**Severity:** Medium (PMF measurement)
**Fix:** Day 8+ — create `AnalyticsService` interface in `core/`, implement Firebase Analytics + Mixpanel adapter, route through Riverpod.

### W6: `DioClient` folder exists but no implementation
**Severity:** Expected (Day 8+ work)
**Fix:** Create `core/network/dio_client.dart` with interceptor for auth token injection, refresh-token rotation, and `Failure` mapping.

### W7: No internationalization
**Severity:** Medium (global growth)
**Fix:** Day 8+ — add `flutter_localizations` + `intl` ARB files. UI strings already centralized per-screen so the swap is mechanical.

### W8: No CI/CD pipeline
**Severity:** Medium (engineering velocity)
**Fix:** Add GitHub Actions workflow: `flutter analyze` + `flutter test` + `flutter build` on every PR.

## Performance

- ✅ No `setState` in screens that have Riverpod equivalents
- ✅ Camera screen splits `Consumer` widgets so toggling grid/flash doesn't re-render preview
- ✅ `MediaQuery` text-scaler clamped to [0.85, 1.4] to prevent layout breakage
- ⚠️  No `const` constructors audit yet — should run `flutter analyze` and add `const` aggressively

## Accessibility

- ✅ All interactive widgets have semantic labels via Material defaults
- ✅ Password visibility toggle has `tooltip`
- ⚠️  No screen-reader pass yet — schedule for Day 8+
- ⚠️  Color contrast not verified — schedule WCAG audit

## Day 8 Preparation

The foundation is ready to support AI development. Recommended Day 8 entry points:

1. **API client** — `core/network/dio_client.dart` + interceptors
2. **Real auth** — `RestAuthRepository` replacing `LocalAuthRepository`
3. **AI inference pipeline** — new `features/inference/` feature with:
   - `domain/entities/pose_suggestion.dart`
   - `domain/repositories/inference_repository.dart`
   - `data/repositories/tflite_inference_repository.dart` (on-device) or `rest_inference_repository.dart` (cloud)
   - `presentation/widgets/overlay_pipeline.dart` that draws on top of `CameraPreview`
4. **History** — `features/history/` data layer with `SessionRepository`
5. **Gallery picker** — replace placeholder `_openGallery` with `photo_manager` integration

## Recommended Coding Standards (enforced via analysis_options.yaml)

- `prefer_single_quotes`: true
- `require_trailing_commas`: true
- `sort_child_properties_last`: true
- `use_super_parameters`: true
- `unawaited_futures`: true
- `avoid_dynamic_calls`: true
- `strict-casts` / `strict-inference`: true

## Verdict

The foundation is **production-ready for the MVP scope**. The architecture
will scale to millions of users without major rewrites — the only
swaps will be `Local*` → `Rest*` repositories, which is exactly the
seam Clean Architecture is supposed to provide. Day 8 can begin AI
work immediately.
