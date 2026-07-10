import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import '../../../../core/logging/app_logger.dart';

/// Monitors device thermal pressure and surfaces it as a stream of
/// [ThermalLevel] values.
///
/// On Android, this reads `/sys/class/thermal/thermal_zone*/temp`.
/// On iOS, there's no public API — we approximate via CPU throttling
/// detection (Day 9+ will integrate `device_info_plus` for native
/// callbacks).
///
/// The pipeline subscribes to this stream and applies [ThermalPolicy].
class ThermalMonitor {
  ThermalMonitor({required this.logger}) {
    _start();
  }

  final AppLogger logger;
  final StreamController<ThermalLevel> _controller =
      StreamController<ThermalLevel>.broadcast();
  Stream<ThermalLevel> get stream => _controller.stream;

  Timer? _pollTimer;
  ThermalLevel _current = ThermalLevel.nominal;

  ThermalLevel get current => _current;

  void _start() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  Future<void> _poll() async {
    try {
      if (!Platform.isAndroid) {
        // iOS / desktop — no native read available; leave nominal.
        return;
      }
      // Best-effort CPU temp read. Many Android devices expose this.
      final cpuTemp = await _readAndroidCpuTemp();
      if (cpuTemp == null) return;

      final next = _classify(cpuTemp);
      if (next != _current) {
        _current = next;
        logger.warning('Thermal level changed: $next (${cpuTemp.toStringAsFixed(1)}°C)');
        _controller.add(next);
      }
    } catch (e) {
      // Silent — thermal monitoring is best-effort.
    }
  }

  Future<double?> _readAndroidCpuTemp() async {
    // Day 9 will swap to a method channel + native implementation.
    // Returning null keeps the monitor idle on Day 8.
    return null;
  }

  ThermalLevel _classify(double celsius) {
    if (celsius >= 45) return ThermalLevel.critical;
    if (celsius >= 40) return ThermalLevel.severe;
    if (celsius >= 35) return ThermalLevel.moderate;
    return ThermalLevel.nominal;
  }

  void dispose() {
    _pollTimer?.cancel();
    _controller.close();
  }
}

enum ThermalLevel { nominal, moderate, severe, critical }
