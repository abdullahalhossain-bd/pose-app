import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/di/providers.dart';
import '../../../guidance/engine/guidance_engine.dart';
import '../../../guidance/presentation/providers/guidance_providers.dart';
import '../../../pose/presentation/providers/pose_providers.dart';

import '../../config/capture_config.dart';
import '../../domain/entities/capture_attempt.dart';
import '../../domain/entities/capture_score.dart';
import '../../domain/enums/capture_enums.dart';
import '../../engine/capture_decision_engine.dart';
import '../../engine/countdown_coordinator.dart';
import '../../engine/stability_detector.dart';
import '../../storage/capture_prefs.dart';

/// ── কনফিগ (ব্যবহারকারীর সংবেদনশীলতা পছন্দ থেকে প্রাপ্ত) ──────────
final captureConfigProvider = Provider<CaptureConfig>((ref) {
  final prefs = ref.watch(capturePrefsProvider);
  return CaptureConfig.forSensitivity(prefs.sensitivity).copyWith(
    defaultCountdownSeconds: prefs.countdownSeconds,
  );
});

/// ── প্রিফারেন্স ────────────────────────────────────────────────
final capturePrefsProvider =
    StateNotifierProvider<CapturePrefsNotifier, CapturePrefs>((ref) {
  return CapturePrefsNotifier(ref.watch(sharedPreferencesProvider));
});

class CapturePrefsNotifier extends StateNotifier<CapturePrefs> {
  CapturePrefsNotifier(this._prefs) : super(const CapturePrefs()) {
    _load();
  }
  final SharedPreferences _prefs;

  Future<void> _load() async {
    state = await CapturePrefs.load(_prefs);
  }

  Future<void> toggleAutoCapture(bool enabled) async {
    state = state.copyWith(autoCaptureEnabled: enabled);
    await state.save(_prefs);
  }

  Future<void> setCountdownSeconds(int s) async {
    state = state.copyWith(countdownSeconds: s.clamp(0, 10));
    await state.save(_prefs);
  }

  Future<void> setVoicePrompts(bool enabled) async {
    state = state.copyWith(voicePromptsEnabled: enabled);
    await state.save(_prefs);
  }

  Future<void> setVibration(bool enabled) async {
    state = state.copyWith(vibrationEnabled: enabled);
    await state.save(_prefs);
  }

  Future<void> setSensitivity(CaptureSensitivity s) async {
    state = state.copyWith(sensitivity: s);
    await state.save(_prefs);
  }
}

/// ── স্টেবিলিটি ডিটেক্টর ───────────────────────────────────────
final stabilityDetectorProvider = Provider<StabilityDetector>((ref) {
  final c = ref.watch(captureConfigProvider);
  return StabilityDetector(
    poseDeltaSuppressDeg: c.poseDeltaSuppressDeg,
    cameraMotionSuppressPx: c.cameraMotionSuppressPx,
    windowFrames: c.stabilityWindowFrames,
  );
});

/// ── ক্যাপচার ডিসিশন ইঞ্জিন ────────────────────────────────────
final captureDecisionEngineProvider = Provider<CaptureDecisionEngine>((ref) {
  return CaptureDecisionEngine(
    config: ref.watch(captureConfigProvider),
    stability: ref.watch(stabilityDetectorProvider),
    guidanceEngine: ref.watch(guidanceEngineProvider),
  );
});

/// ── কাউন্টডাউন কোয়ার্ডিনেটর ─────────────────────────────────
final countdownCoordinatorProvider = Provider<CountdownCoordinator>((ref) {
  final c = ref.watch(captureConfigProvider);
  final controller = ref.watch(captureStateProvider.notifier);
  return CountdownCoordinator(
    config: c,
    onTick: (ms) => controller.onCountdownTick(ms),
    onComplete: () => controller.onCountdownComplete(),
    onCancel: (reason) => controller.onCountdownCancel(reason),
  );
});

/// ── ক্যাপচার স্টেট ────────────────────────────────────────────
final captureStateProvider =
    StateNotifierProvider<CaptureStateController, CaptureState>(
  (ref) => CaptureStateController(ref),
);

/// ── সর্বশেষ স্কোর (ডিবাগ HUD দ্বারা ব্যবহৃত) ────────────────────
final captureScoreProvider =
    StateProvider<CaptureScore?>((ref) => null);

/// ── সর্বশেষ ক্যাপচার প্রচেষ্টা (ফলাফল কার্ড দ্বারা ব্যবহৃত) ─────
final lastCaptureAttemptProvider =
    StateProvider<CaptureAttempt?>((ref) => null);

/// রিভারপড কন্ট্রোলার যা লাইফসাইকেল পরিচালনা করে। গাইডেন্স স্টেজ
/// এই কন্ট্রোলারে পুশ করা ডেটা পাঠায়।
class CaptureStateController extends StateNotifier<CaptureState> {
  CaptureStateController(this._ref) : super(const CaptureIdle());

  final Ref _ref;

  void onNewScore(CaptureScore score) {
    _ref.read(captureScoreProvider.notifier).state = score;

    // স্টেট ট্রানজিশন।
    final prefs = _ref.read(capturePrefsProvider);
    if (!prefs.autoCaptureEnabled) {
      if (state is! CaptureIdle && state is! CaptureSuppressed) {
        state = const CaptureIdle();
      }
      return;
    }

    if (state is CaptureCapturing || state is CaptureReviewing) {
      return; // ট্রানজিশন চলাকালীন স্কোর উপেক্ষা করুন।
    }

    if (score.suppressReason != CaptureSuppressReason.none) {
      state = CaptureSuppressed(reason: score.suppressReason);
      _ref.read(countdownCoordinatorProvider).cancel(
            reason: score.suppressReason,
          );
      return;
    }

    if (score.stableForFrames >=
        _ref.read(captureConfigProvider).stableFrameRequirement) {
      // ক্যাপচারের জন্য প্রস্তুত।
      if (state is! CaptureCountdown && state is! CaptureReady) {
        state = CaptureReady(score: score);
        final duration = _ref.read(capturePrefsProvider).countdownSeconds;
        _ref.read(countdownCoordinatorProvider).start(
              durationSeconds: duration,
              currentScore: score,
            );
      }
    } else if (state is CaptureCountdown) {
      // ইতিমধ্যে কাউন্টডাউন চলছে — স্কোর পর্যবেক্ষণ করুন।
      _ref.read(countdownCoordinatorProvider).observeScore(score);
    } else {
      state = CaptureSearching(currentScore: score.overall);
    }
  }

  void onCountdownTick(int remainingMs) {
    final score = _ref.read(captureScoreProvider);
    if (score == null) return;
    state = CaptureCountdown(remainingMs: remainingMs, score: score);
  }

  void onCountdownComplete() async {
    state = const CaptureCapturing();
    // ক্যামেরা ক্যাপচার ট্রিগার করা ক্যামেরা স্ক্রিন উইজেট দ্বারা পরিচালিত হয়
    // (এটি এই স্টেট পর্যবেক্ষণ করে)। আমরা একটি সিগন্যাল প্রদান করি।
  }

  void onCountdownCancel(CaptureSuppressReason reason) {
    if (state is CaptureCountdown) {
      state = CaptureSuppressed(reason: reason);
    }
  }

  /// ক্যামেরা স্ক্রিন একটি সফল ক্যাপচারের পরে এটি কল করে।
  void onCaptureSuccess({
    required String imagePath,
    required CaptureScore score,
  }) {
    final attempt = CaptureAttempt(
      id: 'cap-${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now().microsecondsSinceEpoch,
      score: score,
      success: true,
      failureReason: CaptureFailureReason.none,
      imagePath: imagePath,
      pose: null,
      guidanceSignal: null,
      tip: null,
    );
    _ref.read(lastCaptureAttemptProvider.notifier).state = attempt;
    state = CaptureReviewing(attempt: attempt);

    // একটি নির্দিষ্ট সময় পরে স্বয়ংক্রিয়ভাবে ক্লিয়ার করুন।
    Future.delayed(
      Duration(milliseconds: _ref.read(captureConfigProvider).showResultCardMs),
      () {
        if (state is CaptureReviewing) {
          state = const CaptureIdle();
        }
      },
    );
  }

  /// ক্যামেরা স্ক্রিন একটি ব্যর্থ ক্যাপচারের পরে এটি কল করে।
  void onCaptureFailure(CaptureFailureReason reason) {
    final score = _ref.read(captureScoreProvider) ??
        CaptureScore(
          factors: const <FactorScore>[],
          overall: 0,
          suppressReason: CaptureSuppressReason.captureFailed,
          stableForFrames: 0,
          timestamp: 0,
        );
    final attempt = CaptureAttempt(
      id: 'cap-${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now().microsecondsSinceEpoch,
      score: score,
      success: false,
      failureReason: reason,
      imagePath: null,
      pose: null,
      guidanceSignal: null,
      tip: CaptureAttempt.tipForFailure(reason),
    );
    _ref.read(lastCaptureAttemptProvider.notifier).state = attempt;
    state = CaptureReviewing(attempt: attempt);

    // স্মার্ট রিট্রাই: গাইডেন্স মোডে ফিরে যান।
    Future.delayed(
      Duration(milliseconds: _ref.read(captureConfigProvider).showResultCardMs),
      () {
        if (state is CaptureReviewing) {
          state = const CaptureSearching(currentScore: 0);
        }
      },
    );
  }

  void reset() {
    _ref.read(countdownCoordinatorProvider).cancel();
    _ref.read(captureDecisionEngineProvider).reset();
    state = const CaptureIdle();
  }
}
