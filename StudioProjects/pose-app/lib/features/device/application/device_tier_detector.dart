import 'dart:io';

import '../domain/device_tier.dart';

/// Classifies the running device into a coarse [DeviceTier].
///
/// HONEST LIMITATION, stated per this pass's own instruction not to
/// pretend precision it doesn't have: this uses ONLY
/// `Platform.numberOfProcessors` (core count) from `dart:io` — no new
/// plugin dependency, no RAM query, no GPU benchmark, no thermal
/// sensing. Core count is a real, if crude, proxy for device tier (a
/// 4-core budget phone and an 8-core flagship really do differ in
/// available headroom), but it is NOT a real benchmark. Two devices
/// with the same core count can perform very differently. A proper
/// device-tier system would run a short calibration (e.g. time N
/// pose-detector calls on first launch and classify from measured
/// latency) — genuinely more work and out of scope for this pass. This
/// is the "don't attempt to perfectly benchmark every Android device"
/// version explicitly permitted by the spec ("Do NOT attempt to
/// perfectly benchmark every Android device"), not a shortcut taken
/// silently.
///
/// Thresholds are centralized here (spec: "Never make the app unusable
/// on LOW devices... thresholds/configuration centralized") — this is
/// the one place to adjust them.
DeviceTier detectDeviceTier() {
  final cores = Platform.numberOfProcessors;
  if (cores <= 4) return DeviceTier.low;
  if (cores <= 6) return DeviceTier.medium;
  return DeviceTier.high;
}
