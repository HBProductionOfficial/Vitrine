import 'dart:math';

import 'package:flutter/foundation.dart';

enum TelemetryField { batteryLevel, temperature, cpuLoad, wifiSignal }

@immutable
class Telemetry {
  const Telemetry({
    required this.batteryLevel,
    required this.temperature,
    required this.cpuLoad,
    required this.wifiSignal,
  });

  /// Percent, 0 to 100.
  final int batteryLevel;

  /// Degrees Celsius, one decimal.
  final double temperature;

  /// Percent, 0 to 100.
  final int cpuLoad;

  /// dBm, from about -90 (weak) to -30 (strong).
  final int wifiSignal;

  Telemetry copyWith({int? batteryLevel, double? temperature, int? cpuLoad, int? wifiSignal}) => Telemetry(
        batteryLevel: batteryLevel ?? this.batteryLevel,
        temperature: temperature ?? this.temperature,
        cpuLoad: cpuLoad ?? this.cpuLoad,
        wifiSignal: wifiSignal ?? this.wifiSignal,
      );

  Object valueOf(TelemetryField field) => switch (field) {
        TelemetryField.batteryLevel => batteryLevel,
        TelemetryField.temperature => temperature,
        TelemetryField.cpuLoad => cpuLoad,
        TelemetryField.wifiSignal => wifiSignal,
      };
}

/// Fake sensor readings for the devices marked as live. Each tick moves one
/// to three readings by a plausible step, the way a real device would drift.
class TelemetrySimulator {
  TelemetrySimulator([Random? random]) : _random = random ?? Random();

  final Random _random;

  Telemetry initial() => Telemetry(
        batteryLevel: 55 + _random.nextInt(40),
        temperature: _round(32 + _random.nextDouble() * 6),
        cpuLoad: 10 + _random.nextInt(40),
        wifiSignal: -75 + _random.nextInt(20),
      );

  (Telemetry, Set<TelemetryField>) next(Telemetry current) {
    final fields = [...TelemetryField.values]..shuffle(_random);
    final changed = fields.take(1 + _random.nextInt(3)).toSet();
    var t = current;
    for (final field in changed) {
      t = switch (field) {
        TelemetryField.batteryLevel => t.copyWith(batteryLevel: (t.batteryLevel + _step(-4, 3)).clamp(5, 100)),
        TelemetryField.temperature => t.copyWith(temperature: _round((t.temperature + _step(-15, 15) / 10).clamp(28.0, 48.0))),
        TelemetryField.cpuLoad => t.copyWith(cpuLoad: (t.cpuLoad + _step(-20, 20)).clamp(2, 98)),
        TelemetryField.wifiSignal => t.copyWith(wifiSignal: (t.wifiSignal + _step(-7, 7)).clamp(-90, -35)),
      };
    }
    // A step can be zero or get clamped, so report only values that moved.
    changed.removeWhere((field) => t.valueOf(field) == current.valueOf(field));
    return (t, changed);
  }

  int _step(int min, int max) => min + _random.nextInt(max - min + 1);

  double _round(double v) => (v * 10).roundToDouble() / 10;
}
