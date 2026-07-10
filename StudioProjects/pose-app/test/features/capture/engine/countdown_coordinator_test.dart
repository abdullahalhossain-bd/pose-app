import 'dart:async';

import 'package:ai_visual_director/features/capture/config/capture_config.dart';
import 'package:ai_visual_director/features/capture/domain/entities/capture_score.dart';
import 'package:ai_visual_director/features/capture/domain/enums/capture_enums.dart';
import 'package:ai_visual_director/features/capture/engine/countdown_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

CaptureScore _score(double overall,
    {CaptureSuppressReason reason = CaptureSuppressReason.none}) {
  return CaptureScore(
    factors: const [],
    overall: overall,
    suppressReason: reason,
    stableForFrames: 10,
    timestamp: 0,
  );
}

void main() {
  group('CountdownCoordinator', () {
    test('calls onComplete when timer elapses', () async {
      var completed = false;
      final c = CountdownCoordinator(
        config: const CaptureConfig(),
        onTick: (_) {},
        onComplete: () => completed = true,
        onCancel: (_) {},
      );

      c.start(
        durationSeconds: 1,
        currentScore: _score(0.9),
      );
      expect(c.isActive, isTrue);

      await Future.delayed(const Duration(milliseconds: 1200));
      expect(completed, isTrue);
      expect(c.isActive, isFalse);
    });

    test('cancels when score drops below threshold', () {
      CaptureSuppressReason? cancelReason;
      final c = CountdownCoordinator(
        config: const CaptureConfig(countdownCancelDropThreshold: 0.15),
        onTick: (_) {},
        onComplete: () {},
        onCancel: (r) => cancelReason = r,
      );

      c.start(durationSeconds: 3, currentScore: _score(0.85));
      // Drop by 0.20 → exceeds 0.15 threshold.
      c.observeScore(_score(0.65));
      expect(cancelReason, CaptureSuppressReason.poseUnstable);
      expect(c.isActive, isFalse);
    });

    test('cancels when suppress reason appears', () {
      CaptureSuppressReason? cancelReason;
      final c = CountdownCoordinator(
        config: const CaptureConfig(),
        onTick: (_) {},
        onComplete: () {},
        onCancel: (r) => cancelReason = r,
      );

      c.start(durationSeconds: 3, currentScore: _score(0.85));
      c.observeScore(_score(0.85, reason: CaptureSuppressReason.cameraShake));
      expect(cancelReason, CaptureSuppressReason.cameraShake);
    });

    test('does not cancel when score stays high', () {
      var cancelled = false;
      final c = CountdownCoordinator(
        config: const CaptureConfig(countdownCancelDropThreshold: 0.15),
        onTick: (_) {},
        onComplete: () {},
        onCancel: (_) => cancelled = true,
      );

      c.start(durationSeconds: 3, currentScore: _score(0.85));
      c.observeScore(_score(0.80));
      c.observeScore(_score(0.78));
      expect(cancelled, isFalse);
    });

    test('zero-second duration calls onComplete immediately', () async {
      var completed = false;
      final c = CountdownCoordinator(
        config: const CaptureConfig(),
        onTick: (_) {},
        onComplete: () => completed = true,
        onCancel: (_) {},
      );

      c.start(durationSeconds: 0, currentScore: _score(0.9));
      expect(completed, isTrue);
      expect(c.isActive, isFalse);
    });

    test('manual cancel triggers onCancel', () {
      CaptureSuppressReason? reason;
      final c = CountdownCoordinator(
        config: const CaptureConfig(),
        onTick: (_) {},
        onComplete: () {},
        onCancel: (r) => reason = r,
      );

      c.start(durationSeconds: 3, currentScore: _score(0.9));
      c.cancel();
      expect(reason, CaptureSuppressReason.manualCancel);
    });
  });
}
