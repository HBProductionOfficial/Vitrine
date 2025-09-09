import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/restful_devices_repository.dart';
import '../domain/device.dart';
import '../domain/telemetry.dart';

/// Sample devices that get simulated live readings. The assignment asked for
/// at least one; three makes the "updated" dot easier to notice.
const liveDeviceIds = {'1', '3', '7'};

@immutable
class DevicesState {
  const DevicesState({
    this.devices = const [],
    this.loading = true,
    this.error,
    this.fromCache = false,
    this.expandedId,
    this.telemetry = const {},
    this.lastChanged = const {},
    this.unseen = const {},
  });

  final List<Device> devices;
  final bool loading;
  final Object? error;
  final bool fromCache;

  /// Only one row is open at a time.
  final String? expandedId;

  final Map<String, Telemetry> telemetry;

  /// Fields that changed on the most recent tick, per device.
  final Map<String, Set<TelemetryField>> lastChanged;

  /// Collapsed devices that changed since the user last opened them.
  final Set<String> unseen;

  DevicesState copyWith({
    List<Device>? devices,
    bool? loading,
    Object? error,
    bool clearError = false,
    bool? fromCache,
    String? expandedId,
    bool collapse = false,
    Map<String, Telemetry>? telemetry,
    Map<String, Set<TelemetryField>>? lastChanged,
    Set<String>? unseen,
  }) {
    return DevicesState(
      devices: devices ?? this.devices,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      fromCache: fromCache ?? this.fromCache,
      expandedId: collapse ? null : (expandedId ?? this.expandedId),
      telemetry: telemetry ?? this.telemetry,
      lastChanged: lastChanged ?? this.lastChanged,
      unseen: unseen ?? this.unseen,
    );
  }
}

class DevicesController extends Notifier<DevicesState> {
  static const tickInterval = Duration(seconds: 10);

  late TelemetrySimulator _simulator;

  @override
  DevicesState build() {
    _simulator = ref.watch(telemetrySimulatorProvider);
    final timer = Timer.periodic(tickInterval, (_) => tick());
    ref.onDispose(timer.cancel);
    Future.microtask(load);
    return const DevicesState();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final result = await ref.read(devicesRepositoryProvider).fetchAll();
      if (!ref.mounted) return;
      final telemetry = {
        for (final d in result.devices)
          if (liveDeviceIds.contains(d.id)) d.id: state.telemetry[d.id] ?? _simulator.initial(),
      };
      state = state.copyWith(
        devices: result.devices,
        fromCache: result.fromCache,
        loading: false,
        telemetry: telemetry,
      );
    } catch (e) {
      if (ref.mounted) state = state.copyWith(loading: false, error: e);
    }
  }

  void toggle(String id) {
    if (state.expandedId == id) {
      state = state.copyWith(collapse: true);
      return;
    }
    state = state.copyWith(expandedId: id, unseen: {...state.unseen}..remove(id));
  }

  @visibleForTesting
  void tick() {
    if (state.telemetry.isEmpty) return;
    final telemetry = {...state.telemetry};
    final changed = <String, Set<TelemetryField>>{};
    final unseen = {...state.unseen};
    for (final entry in state.telemetry.entries) {
      final (next, fields) = _simulator.next(entry.value);
      if (fields.isEmpty) continue;
      telemetry[entry.key] = next;
      changed[entry.key] = fields;
      if (entry.key != state.expandedId) unseen.add(entry.key);
    }
    state = state.copyWith(telemetry: telemetry, lastChanged: changed, unseen: unseen);
  }

  Future<void> create(String name, Map<String, Object?> data) async {
    final device = await ref.read(devicesRepositoryProvider).create(name, data);
    state = state.copyWith(devices: [...state.devices, device], expandedId: device.id);
  }

  Future<void> save(String id, String name, Map<String, Object?> data) async {
    final updated = await ref.read(devicesRepositoryProvider).update(id, name, data);
    state = state.copyWith(devices: [for (final d in state.devices) d.id == id ? updated : d]);
  }

  Future<void> delete(String id) async {
    await ref.read(devicesRepositoryProvider).delete(id);
    state = state.copyWith(devices: state.devices.where((d) => d.id != id).toList(), collapse: state.expandedId == id);
  }
}

final telemetrySimulatorProvider = Provider<TelemetrySimulator>((ref) => TelemetrySimulator());

final devicesControllerProvider = NotifierProvider<DevicesController, DevicesState>(DevicesController.new);
