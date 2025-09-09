import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_clients.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/preferences.dart';
import '../domain/device.dart';
import '../domain/devices_repository.dart';

/// restful-api.dev lists only its sample objects at `/objects`; objects you
/// create are fetched by id, so we remember those ids locally.
class RestfulDevicesRepository implements DevicesRepository {
  RestfulDevicesRepository(this._dio, this._prefs);

  final Dio _dio;
  final SharedPreferences _prefs;

  static const _ownIdsKey = 'devices.ownIds';
  static const _cacheKey = 'devices.cache';

  List<String> get _ownIds => _prefs.getStringList(_ownIdsKey) ?? const [];

  @override
  Future<DeviceList> fetchAll() async {
    try {
      final samples = await _get(null);
      final own = _ownIds.isEmpty ? const <Device>[] : await _get(_ownIds, createdByUser: true);
      final devices = [...samples, ...own];
      await _prefs.setString(_cacheKey, jsonEncode(devices.map((d) => d.toJson()).toList()));
      return DeviceList(devices);
    } on ApiException catch (e) {
      // The public API allows about 50 requests a day, so fall back to the
      // last good list instead of an empty screen.
      final cached = _readCache();
      if (cached == null || e.kind == ApiErrorKind.badRequest) rethrow;
      return DeviceList(cached, fromCache: true);
    }
  }

  @override
  Future<Device> create(String name, Map<String, Object?> data) async {
    final response = await _call(() => _dio.post<Map<String, dynamic>>('/objects', data: {'name': name, 'data': data}));
    final device = Device.fromJson(response, createdByUser: true);
    await _prefs.setStringList(_ownIdsKey, [..._ownIds, device.id]);
    return device;
  }

  @override
  Future<Device> update(String id, String name, Map<String, Object?> data) async {
    final response = await _call(
      () => _dio.put<Map<String, dynamic>>('/objects/$id', data: {'name': name, 'data': data}),
    );
    return Device.fromJson(response, createdByUser: true);
  }

  @override
  Future<void> delete(String id) async {
    await _call(() => _dio.delete<Map<String, dynamic>>('/objects/$id'));
    await _prefs.setStringList(_ownIdsKey, _ownIds.where((own) => own != id).toList());
  }

  Future<List<Device>> _get(List<String>? ids, {bool createdByUser = false}) async {
    final response = await _call(
      () => _dio.get<List<dynamic>>(
        '/objects',
        queryParameters: ids == null ? null : {'id': ids},
        options: Options(listFormat: ListFormat.multi),
      ),
    );
    return response
        .whereType<Map<String, dynamic>>()
        .map((json) => Device.fromJson(json, createdByUser: createdByUser))
        .toList();
  }

  Future<T> _call<T>(Future<Response<T>> Function() request) async {
    try {
      final response = await request();
      return response.data as T;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  List<Device>? _readCache() {
    final raw = _prefs.getString(_cacheKey);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map((json) => Device.fromJson(json, createdByUser: json['createdByUser'] == true))
        .toList();
  }
}

final devicesRepositoryProvider = Provider<DevicesRepository>(
  (ref) => RestfulDevicesRepository(ref.watch(restfulApiClientProvider), ref.watch(preferencesProvider)),
);
