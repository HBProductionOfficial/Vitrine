import 'package:flutter/foundation.dart';

import 'device.dart';

@immutable
class DeviceList {
  const DeviceList(this.devices, {this.fromCache = false});

  final List<Device> devices;

  /// True when the network call failed and these are the last saved results.
  final bool fromCache;
}

abstract class DevicesRepository {
  Future<DeviceList> fetchAll();

  Future<Device> create(String name, Map<String, Object?> data);

  Future<Device> update(String id, String name, Map<String, Object?> data);

  Future<void> delete(String id);
}
