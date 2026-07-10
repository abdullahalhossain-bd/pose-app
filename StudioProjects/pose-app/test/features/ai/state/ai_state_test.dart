import 'package:ai_visual_director/features/ai/state/ai_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiState', () {
    test('Idle renders no overlay, cannot capture', () {
      const s = AiIdle();
      expect(s.rendersOverlay, false);
      expect(s.canCapture, false);
    });

    test('CaptureReady is the only state that allows capture', () {
      const ready = AiReady(feedback: []);
      const captureReady = AiCaptureReady(feedback: []);
      expect(ready.canCapture, false);
      expect(captureReady.canCapture, true);
    });

    test('Detecting / Analyzing / Tracking / Ready render overlays', () {
      expect(const AiDetecting(sinceEpoch: 0).rendersOverlay, true);
      expect(const AiAnalyzing().rendersOverlay, true);
      expect(const AiTracking().rendersOverlay, true);
      expect(const AiReady(feedback: []).rendersOverlay, true);
    });

    test('NoSubject / LowLight do NOT render overlays', () {
      expect(const AiNoSubject().rendersOverlay, false);
      expect(const AiLowLight(lux: 10).rendersOverlay, false);
    });

    test('AiError carries kind + canRetry', () {
      const e = AiError(
        kind: AiErrorKind.inferenceFailed,
        message: 'boom',
        canRetry: false,
      );
      expect(e.kind, AiErrorKind.inferenceFailed);
      expect(e.canRetry, false);
      expect(e.label, contains('boom'));
    });
  });
}
