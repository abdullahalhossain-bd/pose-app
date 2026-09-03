import 'package:flutter_test/flutter_test.dart';
import 'package:ai_visual_director/features/capture/application/auto_capture_engine.dart';
import 'package:ai_visual_director/features/capture/domain/auto_capture_state.dart';

/// A controllable fake clock so the countdown logic can be tested
/// without real Duration-based delays in the test suite.
class _FakeClock {
  DateTime now = DateTime(2026, 1, 1, 12, 0, 0);
  DateTime call() => now;
  void advance(Duration d) => now = now.add(d);
}

void main() {
  group('AutoCaptureEngine — disabled by default', () {
    test('a brand-new engine is disabled and never captures', () {
      final engine = AutoCaptureEngine();
      final result = engine.evaluate(true);
      expect(result.state.status, AutoCaptureStatus.disabled);
      expect(result.shouldCapture, false);
    });

    test('stays disabled even with a sustained hold until explicitly enabled', () {
      final engine = AutoCaptureEngine();
      for (var i = 0; i < 10; i++) {
        final result = engine.evaluate(true);
        expect(result.shouldCapture, false);
      }
    });
  });

  group('AutoCaptureEngine — countdown behavior', () {
    test('waiting when enabled but pose is not holding', () {
      final engine = AutoCaptureEngine();
      engine.setEnabled(true);
      final result = engine.evaluate(false);
      expect(result.state.status, AutoCaptureStatus.waiting);
      expect(result.shouldCapture, false);
    });

    test('counts down once the pose starts holding', () {
      final clock = _FakeClock();
      final engine = AutoCaptureEngine(
        holdDuration: const Duration(seconds: 2),
        clock: clock.call,
      );
      engine.setEnabled(true);

      final first = engine.evaluate(true);
      expect(first.state.status, AutoCaptureStatus.countingDown);
      expect(first.state.secondsRemaining, 2);
      expect(first.shouldCapture, false);

      clock.advance(const Duration(seconds: 1));
      final second = engine.evaluate(true);
      expect(second.state.secondsRemaining, 1);
      expect(second.shouldCapture, false);
    });

    test('triggers shouldCapture exactly once when the hold duration elapses', () {
      final clock = _FakeClock();
      final engine = AutoCaptureEngine(
        holdDuration: const Duration(seconds: 2),
        clock: clock.call,
      );
      engine.setEnabled(true);
      engine.evaluate(true); // starts the timer

      clock.advance(const Duration(seconds: 2));
      final triggered = engine.evaluate(true);
      expect(triggered.shouldCapture, true);

      // The very next evaluation, even with the same clock time, must
      // not trigger a second capture — cooldown should have started.
      final again = engine.evaluate(true);
      expect(again.shouldCapture, false);
      expect(again.state.status, AutoCaptureStatus.cooldown);
    });

    test('losing the hold before the countdown finishes resets it (no partial credit)', () {
      final clock = _FakeClock();
      final engine = AutoCaptureEngine(
        holdDuration: const Duration(seconds: 3),
        clock: clock.call,
      );
      engine.setEnabled(true);
      engine.evaluate(true);
      clock.advance(const Duration(seconds: 2));
      engine.evaluate(true); // 1 second left

      // Pose breaks.
      final broken = engine.evaluate(false);
      expect(broken.state.status, AutoCaptureStatus.waiting);

      // Resuming the hold must restart the full countdown, not resume
      // from where it left off.
      final resumed = engine.evaluate(true);
      expect(resumed.state.secondsRemaining, 3);
    });
  });

  group('AutoCaptureEngine — cooldown', () {
    test('does not start a new countdown during cooldown even if still holding', () {
      final clock = _FakeClock();
      final engine = AutoCaptureEngine(
        holdDuration: const Duration(seconds: 1),
        cooldownDuration: const Duration(seconds: 3),
        clock: clock.call,
      );
      engine.setEnabled(true);
      engine.evaluate(true);
      clock.advance(const Duration(seconds: 1));
      engine.evaluate(true); // triggers capture, enters cooldown

      clock.advance(const Duration(seconds: 1));
      final stillCoolingDown = engine.evaluate(true);
      expect(stillCoolingDown.state.status, AutoCaptureStatus.cooldown);
      expect(stillCoolingDown.shouldCapture, false);
    });

    test('resumes normal countdown behavior once cooldown expires', () {
      final clock = _FakeClock();
      final engine = AutoCaptureEngine(
        holdDuration: const Duration(seconds: 1),
        cooldownDuration: const Duration(seconds: 2),
        clock: clock.call,
      );
      engine.setEnabled(true);
      engine.evaluate(true);
      clock.advance(const Duration(seconds: 1));
      engine.evaluate(true); // triggers, enters cooldown

      clock.advance(const Duration(seconds: 3)); // past cooldown
      final result = engine.evaluate(true);
      expect(result.state.status, AutoCaptureStatus.countingDown);
    });
  });

  group('AutoCaptureEngine — disabling mid-flight', () {
    test('setEnabled(false) immediately clears an in-progress countdown', () {
      final clock = _FakeClock();
      final engine = AutoCaptureEngine(clock: clock.call);
      engine.setEnabled(true);
      engine.evaluate(true);

      engine.setEnabled(false);
      final result = engine.evaluate(true);
      expect(result.state.status, AutoCaptureStatus.disabled);
      expect(result.shouldCapture, false);
    });

    test('re-enabling starts a fresh countdown, not a resumed one', () {
      final clock = _FakeClock();
      final engine = AutoCaptureEngine(
        holdDuration: const Duration(seconds: 3),
        clock: clock.call,
      );
      engine.setEnabled(true);
      engine.evaluate(true);
      clock.advance(const Duration(seconds: 2));
      engine.evaluate(true);

      engine.setEnabled(false);
      engine.setEnabled(true);
      final result = engine.evaluate(true);
      expect(result.state.secondsRemaining, 3);
    });
  });

  group('AutoCaptureEngine.reset()', () {
    test('reset() clears an in-progress countdown without disabling the feature', () {
      final clock = _FakeClock();
      final engine = AutoCaptureEngine(
        holdDuration: const Duration(seconds: 3),
        clock: clock.call,
      );
      engine.setEnabled(true);
      engine.evaluate(true);
      clock.advance(const Duration(seconds: 2));

      engine.reset();
      final result = engine.evaluate(true);
      expect(result.state.status, AutoCaptureStatus.countingDown);
      expect(result.state.secondsRemaining, 3);
    });
  });
}
