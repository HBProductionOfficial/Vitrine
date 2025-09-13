import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitrine/src/features/devices/data/restful_devices_repository.dart';
import 'package:vitrine/src/features/devices/domain/telemetry.dart';
import 'package:vitrine/src/features/devices/presentation/devices_controller.dart';

import '../../helpers/fake_devices.dart';

void main() {
  late ProviderContainer container;
  late FakeDevicesRepository repo;

  DevicesController controller() => container.read(devicesControllerProvider.notifier);
  DevicesState state() => container.read(devicesControllerProvider);

  setUp(() async {
    repo = FakeDevicesRepository();
    container = ProviderContainer.test(
      overrides: [
        devicesRepositoryProvider.overrideWithValue(repo),
        telemetrySimulatorProvider.overrideWithValue(SteadySimulator()),
      ],
    );
    container.read(devicesControllerProvider);
    await pumpEventQueue();
  });

  test('loads the list and gives live readings to devices 1, 3 and 7', () {
    expect(state().loading, isFalse);
    expect(state().devices, hasLength(4));
    expect(state().telemetry.keys, unorderedEquals(['1', '3', '7']));
  });

  test('only one row is open at a time', () {
    controller().toggle('1');
    expect(state().expandedId, '1');

    controller().toggle('3');
    expect(state().expandedId, '3');

    controller().toggle('3');
    expect(state().expandedId, isNull);
  });

  test('a tick marks closed live devices as updated, but not the open one', () {
    controller().toggle('1');
    controller().tick();

    expect(state().unseen, {'3', '7'});
    expect(state().telemetry['1']!.batteryLevel, 79);
    expect(state().lastChanged['1'], {TelemetryField.batteryLevel});
  });

  test('opening a row clears its dot', () {
    controller().tick();
    expect(state().unseen, {'1', '3', '7'});

    controller().toggle('7');
    expect(state().unseen, {'1', '3'});
  });

  test('a new device is added at the end and opened', () async {
    await controller().create('Vitrine test phone', {'color': 'Graphite'});

    expect(state().devices.last.name, 'Vitrine test phone');
    expect(state().expandedId, state().devices.last.id);
  });

  test('deleting the open device closes it', () async {
    await controller().create('Temp', const {});
    final id = state().expandedId!;
    await controller().delete(id);

    expect(state().devices.any((d) => d.id == id), isFalse);
    expect(state().expandedId, isNull);
  });
}
