/// Approximate device capability classification (spec Phase 9 of the
/// P1-completion pass: "classify approximately: LOW / MEDIUM / HIGH").
/// Deliberately coarse — see device_tier_detector.dart for why.
enum DeviceTier { low, medium, high }
