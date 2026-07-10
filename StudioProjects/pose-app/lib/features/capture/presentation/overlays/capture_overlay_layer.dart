import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../domain/entities/capture_attempt.dart';
import '../../domain/enums/capture_enums.dart';
import '../providers/capture_providers.dart';

/// একটি ফ্যাক্টর স্কোর নিরাপদে খুঁজে আনুন।
double _factorScore(List factors, CaptureFactor f) {
  for (final s in factors) {
    if (s.factor == f) return s.score;
  }
  return 0;
}

String _suppressLabel(CaptureSuppressReason r) => switch (r) {
      CaptureSuppressReason.none => '',
      CaptureSuppressReason.userDisabled => 'auto capture off',
      CaptureSuppressReason.multiplePeople => 'multiple people',
      CaptureSuppressReason.noFace => 'no face visible',
      CaptureSuppressReason.closedEyes => 'eyes closed',
      CaptureSuppressReason.lowLight => 'low light',
      CaptureSuppressReason.subjectMoving => 'subject moving',
      CaptureSuppressReason.cameraShake => 'camera shake',
      CaptureSuppressReason.poseUnstable => 'pose unstable',
      CaptureSuppressReason.lowConfidence => 'low AI confidence',
      CaptureSuppressReason.userExited => 'subject left frame',
      CaptureSuppressReason.manualCancel => 'cancelled',
      CaptureSuppressReason.captureFailed => 'capture failed',
    };

/// ক্যাপচার লাইফসাইকেল অনুযায়ী কাউন্টডাউন রিং, রেজাল্ট কার্ড এবং সাফল্য
/// অ্যানিমেশন রেন্ডার করে। নিষ্ক্রিয় থাকলে কিছুই রেন্ডার করে না।
class CaptureOverlayLayer extends ConsumerStatefulWidget {
  const CaptureOverlayLayer({super.key});

  @override
  ConsumerState<CaptureOverlayLayer> createState() =>
      _CaptureOverlayLayerState();
}

class _CaptureOverlayLayerState extends ConsumerState<CaptureOverlayLayer>
    with TickerProviderStateMixin {
  late final AnimationController _celebration;

  @override
  void initState() {
    super.initState();
    _celebration = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _celebration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(captureStateProvider);

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          switch (state.runtimeType) {
            CaptureCountdown => _CountdownRing(
                remainingMs: (state as CaptureCountdown).remainingMs,
                totalMs: ref.read(capturePrefsProvider).countdownSeconds * 1000,
              ),
            CaptureReviewing => _ResultCard(attempt: (state as CaptureReviewing).attempt),
            CaptureSuppressed => _SuppressedBanner(reason: (state as CaptureSuppressed).reason),
            CaptureReady || CaptureSearching => _ScoreBadge(state: state),
            _ => const SizedBox.shrink(),
          },
        ],
      ),
    );
  }
}

class _CountdownRing extends StatelessWidget {
  const _CountdownRing({required this.remainingMs, required this.totalMs});
  final int remainingMs;
  final int totalMs;

  @override
  Widget build(BuildContext context) {
    final progress = (remainingMs / totalMs).clamp(0.0, 1.0);
    final seconds = (remainingMs / 1000).ceil();

    return Center(
      child: SizedBox(
        width: 160,
        height: 160,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 6,
              backgroundColor: Colors.white.withOpacity(0.2),
              color: Colors.white,
            ),
            Center(
              child: Text(
                '$seconds',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.attempt});
  final CaptureAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final success = attempt.success;
    final accent = success ? const Color(0xFF22C55E) : const Color(0xFFEF4444);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error_outline,
                  color: accent,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  success ? 'Captured!' : attempt.failureLabel,
                  style: TextStyle(
                    color: accent,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ScoreRow(
                label: 'Pose',
                value: _factorScore(attempt.score.factors, CaptureFactor.pose)),
            const SizedBox(height: 8),
            _ScoreRow(label: 'Capture Quality', value: attempt.score.overall),
            const SizedBox(height: 8),
            _ScoreRow(
                label: 'AI Confidence',
                value: _factorScore(attempt.score.factors, CaptureFactor.confidence)),
            if (attempt.tip != null) ...[
              const SizedBox(height: 16),
              Text(
                attempt.tip!,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const Spacer(),
        Text(
          '${(value * 100).round()}%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SuppressedBanner extends StatelessWidget {
  const _SuppressedBanner({required this.reason});
  final CaptureSuppressReason reason;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
          ),
          child: Text(
            _suppressLabel(reason),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.state});
  final CaptureState state;

  @override
  Widget build(BuildContext context) {
    final score = state is CaptureSearching
        ? (state as CaptureSearching).currentScore
        : (state is CaptureReady ? (state as CaptureReady).score.overall : 0.0);

    return Positioned(
      bottom: 220,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Capture score: ${(score * 100).round()}%',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
