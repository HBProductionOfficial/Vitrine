import 'package:vitrine/src/features/devices/domain/device.dart';
import 'package:vitrine/src/features/devices/domain/devices_repository.dart';
import 'package:vitrine/src/features/devices/domain/telemetry.dart';

const sampleDevices = [
  Device(id: '1', name: 'Google Pixel 6 Pro', data: {'color': 'Cloudy White'}),
  Device(id: '2', name: 'Apple iPhone 12 Mini', data: {'color': 'Blue'}),
  Device(id: '3', name: 'Apple iPhone 12 Pro Max', data: {'capacity GB': 512}),
  Device(id: '7', name: 'Apple MacBook Pro 16', data: {'year': 2019}),
];

class FakeDevicesRepository implements DevicesRepository {
  FakeDevicesRepository([List<Device> devices = sampleDevices]) : devices = [...devices];

  final List<Device> devices;
  var _nextId = 100;

  @override
  Future<DeviceList> fetchAll() async => DeviceList([...devices]);

  @override
  Future<Device> create(String name, Map<String, Object?> data) async {
    final device = Device(id: 'ff${_nextId++}', name: name, data: data, createdByUser: true);
    devices.add(device);
    return device;
  }

  @override
  Future<Device> update(String id, String name, Map<String, Object?> data) async {
    return Device(id: id, name: name, data: data, createdByUser: true);
  }

  @override
  Future<void> delete(String id) async => devices.removeWhere((d) => d.id == id);
}

/// Every tick drains one percent of battery, so tests know exactly what changes.
class SteadySimulator extends TelemetrySimulator {
  @override
  Telemetry initial() => const Telemetry(batteryLevel: 80, temperature: 34, cpuLoad: 20, wifiSignal: -60);

  @override
  (Telemetry, Set<TelemetryField>) next(Telemetry current) {
    return (current.copyWith(batteryLevel: current.batteryLevel - 1), {TelemetryField.batteryLevel});
  }
}
