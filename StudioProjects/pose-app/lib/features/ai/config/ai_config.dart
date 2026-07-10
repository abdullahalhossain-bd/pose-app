import 'package:flutter/foundation.dart';

/// Performance presets the user can switch between.
///
/// Each preset tunes the same set of knobs (frame interval, resolution,
/// model variant, etc.) so we can ship one settings UI and never touch
/// the runtime code.
enum AiPerformanceMode {
  /// Max quality, max FPS, full-resolution frames. Use when plugged in
  /// or on flagship devices.
  performance,

  /// Balanced default — good accuracy, ~15 FPS, mid-resolution.
  balanced,

  /// Aggressive throttle for low-end devices or low battery. Still
  /// functional, just less responsive.
  batterySaver,
}

/// What to do when the device reports elevated thermal pressure.
enum ThermalPolicy {
  /// Keep running; let the OS throttle.
  ignore,
  /// Drop to batterySaver mode automatically.
  throttle,
  /// Pause inference entirely until the device cools.
  pause,
}

/// Immutable AI configuration. Loaded once at startup; updates create
/// a new instance via `copyWith`.
///
/// All values are surfaced through `AiConfigProvider` so widgets /
/// pipeline stages never read hardcoded numbers.
@immutable
class AiConfig {
  const AiConfig({
    this.performanceMode = AiPerformanceMode.balanced,
    this.thermalPolicy = ThermalPolicy.throttle,
    // ── Frame pipeline ────────────────────────────────────────────
    this.targetFps = 15,
    this.maxFps = 30,
    this.minFps = 4,
    this.frameSkip = 0,
    this.processingIntervalMs = 66, // ~15 FPS
    // ── Inference ─────────────────────────────────────────────────
    this.confidenceThreshold = 0.5,
    this.iouThreshold = 0.45,
    this.maxDetections = 5,
    this.inputWidth = 256,
    this.inputHeight = 256,
    // ── Environment awareness ─────────────────────────────────────
    this.lowLightLuxThreshold = 50.0,
    this.batterySaverPercent = 20,
    this.thermalThrottleCelsius = 38.0,
    this.thermalPauseCelsius = 42.0,
    // ── Overlay ───────────────────────────────────────────────────
    this.overlayFadeMs = 200,
    this.showConfidence = true,
    this.showDebugOverlay = false,
    // ── Recovery ──────────────────────────────────────────────────
    this.maxReconnectAttempts = 3,
    this.reconnectBackoffMs = 800,
    // ── Debug ─────────────────────────────────────────────────────
    this.enableLatencyLogging = !kReleaseMode,
    this.enableFrameMetrics = !kReleaseMode,
  });

  /// Per-preset factory.
  factory AiConfig.forMode(AiPerformanceMode mode) {
    return switch (mode) {
      AiPerformanceMode.performance => const AiConfig(
          performanceMode: AiPerformanceMode.performance,
          targetFps: 30,
          maxFps: 30,
          minFps: 10,
          processingIntervalMs: 33,
          inputWidth: 320,
          inputHeight: 320,
          confidenceThreshold: 0.45,
        ),
      AiPerformanceMode.balanced => const AiConfig(),
      AiPerformanceMode.batterySaver => const AiConfig(
          performanceMode: AiPerformanceMode.batterySaver,
          targetFps: 6,
          maxFps: 10,
          minFps: 2,
          processingIntervalMs: 166,
          frameSkip: 1,
          inputWidth: 192,
          inputHeight: 192,
          confidenceThreshold: 0.55,
        ),
    };
  }

  final AiPerformanceMode performanceMode;
  final ThermalPolicy thermalPolicy;

  // Frame pipeline
  final int targetFps;
  final int maxFps;
  final int minFps;
  final int frameSkip;
  final int processingIntervalMs;

  // Inference
  final double confidenceThreshold;
  final double iouThreshold;
  final int maxDetections;
  final int inputWidth;
  final int inputHeight;

  // Environment
  final double lowLightLuxThreshold;
  final int batterySaverPercent;
  final double thermalThrottleCelsius;
  final double thermalPauseCelsius;

  // Overlay
  final int overlayFadeMs;
  final bool showConfidence;
  final bool showDebugOverlay;

  // Recovery
  final int maxReconnectAttempts;
  final int reconnectBackoffMs;

  // Debug
  final bool enableLatencyLogging;
  final bool enableFrameMetrics;

  /// Whether inference should run on a background isolate. On-device
  /// inference is always isolate-bound; cloud inference is not.
  bool get useIsolate => true;

  AiConfig copyWith({
    AiPerformanceMode? performanceMode,
    ThermalPolicy? thermalPolicy,
    int? targetFps,
    int? maxFps,
    int? minFps,
    int? frameSkip,
    int? processingIntervalMs,
    double? confidenceThreshold,
    double? iouThreshold,
    int? maxDetections,
    int? inputWidth,
    int? inputHeight,
    double? lowLightLuxThreshold,
    int? batterySaverPercent,
    double? thermalThrottleCelsius,
    double? thermalPauseCelsius,
    int? overlayFadeMs,
    bool? showConfidence,
    bool? showDebugOverlay,
    int? maxReconnectAttempts,
    int? reconnectBackoffMs,
    bool? enableLatencyLogging,
    bool? enableFrameMetrics,
  }) {
    return AiConfig(
      performanceMode: performanceMode ?? this.performanceMode,
      thermalPolicy: thermalPolicy ?? this.thermalPolicy,
      targetFps: targetFps ?? this.targetFps,
      maxFps: maxFps ?? this.maxFps,
      minFps: minFps ?? this.minFps,
      frameSkip: frameSkip ?? this.frameSkip,
      processingIntervalMs: processingIntervalMs ?? this.processingIntervalMs,
      confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
      iouThreshold: iouThreshold ?? this.iouThreshold,
      maxDetections: maxDetections ?? this.maxDetections,
      inputWidth: inputWidth ?? this.inputWidth,
      inputHeight: inputHeight ?? this.inputHeight,
      lowLightLuxThreshold: lowLightLuxThreshold ?? this.lowLightLuxThreshold,
      batterySaverPercent: batterySaverPercent ?? this.batterySaverPercent,
      thermalThrottleCelsius: thermalThrottleCelsius ?? this.thermalThrottleCelsius,
      thermalPauseCelsius: thermalPauseCelsius ?? this.thermalPauseCelsius,
      overlayFadeMs: overlayFadeMs ?? this.overlayFadeMs,
      showConfidence: showConfidence ?? this.showConfidence,
      showDebugOverlay: showDebugOverlay ?? this.showDebugOverlay,
      maxReconnectAttempts: maxReconnectAttempts ?? this.maxReconnectAttempts,
      reconnectBackoffMs: reconnectBackoffMs ?? this.reconnectBackoffMs,
      enableLatencyLogging: enableLatencyLogging ?? this.enableLatencyLogging,
      enableFrameMetrics: enableFrameMetrics ?? this.enableFrameMetrics,
    );
  }
}
