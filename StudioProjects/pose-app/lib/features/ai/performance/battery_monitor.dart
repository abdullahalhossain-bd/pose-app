import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks battery level via `battery_plus` (added in Day 9 when we
/// pull in real plugins). For Day 8, it's a static stub so the
/// pipeline's battery-saver branch is reachable.
class BatteryMonitor extends StateNotifier<BatterySnapshot> {
  BatteryMonitor() : super(const BatterySnapshot(level: 100, charging: false));

  void update({required int level, required bool charging}) {
    state = BatterySnapshot(level: level, charging: charging);
  }
}

class BatterySnapshot {
  const BatterySnapshot({required this.level, required this.charging});
  final int level; // 0..100
  final bool charging;

  bool get shouldTriggerBatterySaver => !charging && level <= 20;
}

final batteryMonitorProvider =
    StateNotifierProvider<BatteryMonitor, BatterySnapshot>(
        (ref) => BatteryMonitor());
