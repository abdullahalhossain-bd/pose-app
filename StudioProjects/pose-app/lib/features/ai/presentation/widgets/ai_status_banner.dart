import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/ai_state.dart';
import '../providers/ai_providers.dart';

/// Top-of-screen banner that surfaces the current AI state to the
/// user. Auto-hides when the state is "good" (Idle / Ready /
/// CaptureReady) so it doesn't compete with the camera.
class AiStatusBanner extends ConsumerWidget {
  const AiStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiStateProvider);
    return switch (state) {
      AiIdle() => const SizedBox.shrink(),
      AiReady() => const SizedBox.shrink(),
      AiCaptureReady() => const SizedBox.shrink(),
      AiDetecting() => const SizedBox.shrink(),
      AiAnalyzing() => const SizedBox.shrink(),
      AiTracking() => const SizedBox.shrink(),
      AiPreparing(:final progress) => Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: LinearProgressIndicator(value: progress),
        ),
      AiNoSubject() => _Banner(
          message: state.label,
          color: Colors.amber.shade800,
        ),
      AiLowLight(:final lux) => _Banner(
          message: 'Low light (${lux.toStringAsFixed(0)} lux) — AI paused',
          color: Colors.amber.shade800,
        ),
      AiPermissionMissing() => _Banner(
          message: 'Camera permission required',
          color: Colors.red.shade700,
        ),
      AiError(:final message, :final canRetry) => _Banner(
          message: message,
          color: Colors.red.shade700,
          showRetry: canRetry,
        ),
    };
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.message,
    required this.color,
    this.showRetry = false,
  });
  final String message;
  final Color color;
  final bool showRetry;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        color: color,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
