import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../state/ai_state.dart';

/// Single owner of [AiState] transitions. The pipeline / camera /
/// recovery systems request transitions through this controller; UI
/// only reads.
class AiStateController extends StateNotifier<AiState> {
  AiStateController({
    required this.errorHandler,
    required this.logger,
  }) : super(const AiIdle());

  final ErrorHandler errorHandler;
  final AppLogger logger;

  /// Track how many consecutive errors we've seen for the same kind,
  /// used by recovery logic to decide whether to give up.
  final Map<AiErrorKind, int> _errorStreak = {};

  void transitionTo(AiState next) {
    if (state == next) return;
    logger.debug('AI state: ${state.label} → ${next.label}');
    state = next;
  }

  void reset() {
    _errorStreak.clear();
    transitionTo(const AiIdle());
  }

  void preparing({double progress = 0}) =>
      transitionTo(AiPreparing(progress: progress));

  void detecting() {
    transitionTo(AiDetecting(sinceEpoch: DateTime.now().millisecondsSinceEpoch));
  }

  void analyzing() => transitionTo(const AiAnalyzing());

  void tracking({int? trackId}) => transitionTo(AiTracking(trackId: trackId));

  void ready(List<AiFeedback> feedback) =>
      transitionTo(AiReady(feedback: feedback));

  void captureReady(List<AiFeedback> feedback) =>
      transitionTo(AiCaptureReady(feedback: feedback));

  void noSubject() => transitionTo(const AiNoSubject());

  void lowLight(double lux) => transitionTo(AiLowLight(lux: lux));

  void permissionMissing() => transitionTo(const AiPermissionMissing());

  void error({
    required AiErrorKind kind,
    required String message,
    bool canRetry = true,
  }) {
    _errorStreak[kind] = (_errorStreak[kind] ?? 0) + 1;
    logger.warning('AI error ($kind): $message '
        '[streak=${_errorStreak[kind]}]');
    transitionTo(AiError(
      kind: kind,
      message: message,
      canRetry: canRetry,
    ));
  }

  void clearError(AiErrorKind kind) {
    _errorStreak.remove(kind);
  }

  int errorStreak(AiErrorKind kind) => _errorStreak[kind] ?? 0;
}
