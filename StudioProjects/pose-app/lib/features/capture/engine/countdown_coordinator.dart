import 'dart:async';

import '../config/capture_config.dart';
import '../domain/entities/capture_score.dart';
import '../domain/enums/capture_enums.dart';

/// টিক-ভিত্তিক কাউন্টডাউন। স্টেট প্রতি 100ms আপডেট হয়। ক্যানসেল করা যায়
/// যেকোনো সময়, এবং স্কোর ড্রপ করলে স্বয়ংক্রিয়ভাবে ক্যানসেল হয়ে যায়।
class CountdownCoordinator {
  CountdownCoordinator({
    required this.config,
    required this.onTick,
    required this.onComplete,
    required this.onCancel,
  });

  final CaptureConfig config;
  final void Function(int remainingMs) onTick;
  final void Function() onComplete;
  final void Function(CaptureSuppressReason reason) onCancel;

  Timer? _timer;
  int _remainingMs = 0;
  double _scoreAtStart = 0;
  bool _active = false;

  bool get isActive => _active;
  int get remainingMs => _remainingMs;

  /// `durationSeconds` 0 হলে তাৎক্ষণিক ক্যাপচার শুরু করুন।
  void start({
    required int durationSeconds,
    required CaptureScore currentScore,
  }) {
    cancel(reason: CaptureSuppressReason.manualCancel);

    if (durationSeconds <= 0) {
      onComplete();
      return;
    }

    _active = true;
    _remainingMs = durationSeconds * 1000;
    _scoreAtStart = currentScore.overall;
    onTick(_remainingMs);

    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      _remainingMs -= 100;
      if (_remainingMs <= 0) {
        t.cancel();
        _active = false;
        onComplete();
        return;
      }
      onTick(_remainingMs);
    });
  }

  /// প্রতি ফ্রেমে কল করুন যাতে কোঅর্ডিনেটর স্কোর ড্র়প হলে
  /// স্বয়ংক্রিয়ভাবে ক্যানসেল করতে পারে।
  void observeScore(CaptureScore score) {
    if (!_active) return;
    final drop = _scoreAtStart - score.overall;
    if (drop > config.countdownCancelDropThreshold ||
        score.suppressReason != CaptureSuppressReason.none) {
      cancel(reason: score.suppressReason == CaptureSuppressReason.none
          ? CaptureSuppressReason.poseUnstable
          : score.suppressReason);
    }
  }

  void cancel({CaptureSuppressReason reason = CaptureSuppressReason.manualCancel}) {
    _timer?.cancel();
    _timer = null;
    final wasActive = _active;
    _active = false;
    _remainingMs = 0;
    if (wasActive) {
      onCancel(reason);
    }
  }
}
