import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitrine/src/core/network/api_exception.dart';
import 'package:vitrine/src/features/devices/data/restful_devices_repository.dart';

import '../../helpers/fake_http.dart';

const _samples = [
  {
    'id': '1',
    'name': 'Google Pixel 6 Pro',
    'data': {'color': 'Cloudy White', 'capacity': '128 GB'},
  },
  {'id': '7', 'name': 'Apple MacBook Pro 16', 'data': null},
];

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('lists the samples, then the devices you created, fetched by id', () async {
    await prefs.setStringList('devices.ownIds', ['ff01', 'ff02']);
    final (dio, adapter) = fakeDio(
      (r) => r.uri.queryParametersAll.containsKey('id')
          ? const FakeResponse(200, [
              {'id': 'ff01', 'name': 'Test phone', 'data': {}},
              {'id': 'ff02', 'name': 'Test tablet', 'data': {}},
            ])
          : const FakeResponse(200, _samples),
    );

    final list = await RestfulDevicesRepository(dio, prefs).fetchAll();

    expect(list.devices.map((d) => d.id), ['1', '7', 'ff01', 'ff02']);
    expect(list.devices.where((d) => d.createdByUser).length, 2);
    expect(list.fromCache, isFalse);
    expect(adapter.requests.last.uri.query, 'id=ff01&id=ff02');
  });

  test('skips the second request when you have no devices of your own', () async {
    final (dio, adapter) = fakeDio((_) => const FakeResponse(200, _samples));
    await RestfulDevicesRepository(dio, prefs).fetchAll();
    expect(adapter.requests, hasLength(1));
  });

  test('create remembers the new id and delete forgets it', () async {
    final (dio, adapter) = fakeDio(
      (r) => switch (r.method) {
        'POST' => FakeResponse(200, {'id': 'ff03', 'name': (r.data as Map)['name'], 'data': (r.data as Map)['data']}),
        _ => const FakeResponse(200, {'message': 'deleted'}),
      },
    );
    final repo = RestfulDevicesRepository(dio, prefs);

    final device = await repo.create('Vitrine test phone', {'color': 'Graphite'});
    expect(device.createdByUser, isTrue);
    expect(device.data['color'], 'Graphite');
    expect(prefs.getStringList('devices.ownIds'), ['ff03']);

    await repo.delete('ff03');
    expect(adapter.requests.last.method, 'DELETE');
    expect(adapter.requests.last.path, '/objects/ff03');
    expect(prefs.getStringList('devices.ownIds'), isEmpty);
  });

  test('update sends the whole object with PUT', () async {
    final (dio, adapter) = fakeDio(
      (r) => FakeResponse(200, {'id': 'ff03', 'name': (r.data as Map)['name'], 'data': (r.data as Map)['data']}),
    );

    final updated = await RestfulDevicesRepository(dio, prefs).update('ff03', 'Renamed', {'color': 'Blue'});

    expect(adapter.requests.single.method, 'PUT');
    expect(adapter.requests.single.data, {
      'name': 'Renamed',
      'data': {'color': 'Blue'},
    });
    expect(updated.name, 'Renamed');
  });

  test('when the daily limit is hit, the last good list is shown instead', () async {
    var limited = false;
    final (dio, _) = fakeDio(
      (_) => limited ? const FakeResponse(429, {'error': 'Too many requests'}) : const FakeResponse(200, _samples),
    );
    final repo = RestfulDevicesRepository(dio, prefs);
    await repo.fetchAll();

    limited = true;
    final list = await repo.fetchAll();

    expect(list.fromCache, isTrue);
    expect(list.devices.map((d) => d.name), ['Google Pixel 6 Pro', 'Apple MacBook Pro 16']);
  });

  test('with nothing cached the error comes through', () async {
    final (dio, _) = fakeDio((_) => const FakeResponse(429));
    await expectLater(
      RestfulDevicesRepository(dio, prefs).fetchAll(),
      throwsA(isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.rateLimited)),
    );
  });

  test('the sample objects are read-only', () async {
    final (dio, _) = fakeDio((_) => const FakeResponse(405, {'error': 'reserved id'}));
    await expectLater(
      RestfulDevicesRepository(dio, prefs).delete('1'),
      throwsA(isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.forbidden)),
    );
  });
}
