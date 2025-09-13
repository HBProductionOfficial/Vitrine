import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vitrine/src/features/devices/domain/telemetry.dart';

void main() {
  test('starting readings look like a device on a desk', () {
    final t = TelemetrySimulator(Random(1)).initial();
    expect(t.batteryLevel, inInclusiveRange(55, 94));
    expect(t.temperature, inInclusiveRange(32, 38));
    expect(t.cpuLoad, inInclusiveRange(10, 49));
    expect(t.wifiSignal, inInclusiveRange(-75, -56));
  });

  test('each tick reports exactly the readings that moved, and they stay in range', () {
    final simulator = TelemetrySimulator(Random(42));
    var current = simulator.initial();

    for (var i = 0; i < 500; i++) {
      final (next, changed) = simulator.next(current);

      expect(changed.length, lessThanOrEqualTo(3));
      for (final field in TelemetryField.values) {
        final moved = next.valueOf(field) != current.valueOf(field);
        expect(changed.contains(field), moved, reason: 'tick $i, $field');
      }
      expect(next.batteryLevel, inInclusiveRange(5, 100));
      expect(next.temperature, inInclusiveRange(28, 48));
      expect(next.cpuLoad, inInclusiveRange(2, 98));
      expect(next.wifiSignal, inInclusiveRange(-90, -35));
      current = next;
    }
  });

  test('the same seed gives the same readings', () {
    final a = TelemetrySimulator(Random(7));
    final b = TelemetrySimulator(Random(7));
    var ta = a.initial();
    var tb = b.initial();
    for (var i = 0; i < 20; i++) {
      (ta, _) = a.next(ta);
      (tb, _) = b.next(tb);
    }
    expect(ta.batteryLevel, tb.batteryLevel);
    expect(ta.temperature, tb.temperature);
  });
}
