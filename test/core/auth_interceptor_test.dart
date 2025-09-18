import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitrine/src/core/network/auth_interceptor.dart';
import 'package:vitrine/src/core/network/token_holder.dart';

import '../helpers/fake_http.dart';

void main() {
  late TokenHolder tokens;
  late int expiredCalls;
  late List<String> savedRefresh;

  setUp(() {
    tokens = TokenHolder()..update(access: 'old', refresh: 'refresh-1');
    expiredCalls = 0;
    savedRefresh = [];
  });

  /// Both clients talk to the same fake server, like the real ones do.
  Dio clientWith(FakeResponse Function(RequestOptions request) server) {
    final (dio, _) = fakeDio(server);
    final (plain, _) = fakeDio(server);
    dio.interceptors.add(
      AuthInterceptor(
        tokens: tokens,
        plainClient: plain,
        onSessionExpired: () => expiredCalls++,
        onRefreshed: savedRefresh.add,
      ),
    );
    return dio;
  }

  final authed = Options(extra: {AuthInterceptor.requiresAuth: true});
  const refreshed = FakeResponse(200, {'accessToken': 'new', 'refreshToken': 'refresh-2'});

  test('adds the bearer token only to requests that ask for it', () async {
    final seen = <String?>[];
    final dio = clientWith((r) {
      seen.add(r.headers['Authorization'] as String?);
      return const FakeResponse(200, {});
    });

    await dio.get<Object>('/products');
    await dio.get<Object>('/auth/me', options: authed);

    expect(seen, [null, 'Bearer old']);
  });

  test('on 401 it refreshes once and replays the request', () async {
    final dio = clientWith((r) {
      if (r.path == '/auth/refresh') {
        expect((r.data as Map)['refreshToken'], 'refresh-1');
        return refreshed;
      }
      return r.headers['Authorization'] == 'Bearer new'
          ? const FakeResponse(200, {'id': 1})
          : const FakeResponse(401, {'message': 'Token Expired!'});
    });

    final response = await dio.get<Map<String, dynamic>>('/auth/me', options: authed);

    expect(response.data, {'id': 1});
    expect(tokens.accessToken, 'new');
    expect(tokens.refreshToken, 'refresh-2');
    expect(savedRefresh, ['refresh-2']);
    expect(expiredCalls, 0);
  });

  test('a failed refresh ends the session', () async {
    final dio = clientWith((_) => const FakeResponse(401));

    await expectLater(
      dio.get<Object>('/auth/me', options: authed),
      throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 401)),
    );
    expect(expiredCalls, 1);
    expect(tokens.hasSession, isFalse);
  });

  test('a replay that fails again is passed on, not retried or stuck', () async {
    var calls = 0;
    final dio = clientWith((r) {
      if (r.path == '/auth/refresh') return refreshed;
      calls++;
      return const FakeResponse(401);
    });

    await expectLater(
      dio.get<Object>('/auth/me', options: authed).timeout(const Duration(seconds: 2)),
      throwsA(isA<DioException>()),
    );
    expect(calls, 2);
  });

  test('requests without auth are never refreshed', () async {
    var refreshes = 0;
    final dio = clientWith((r) {
      if (r.path == '/auth/refresh') refreshes++;
      return const FakeResponse(401);
    });

    await expectLater(dio.get<Object>('/products'), throwsA(isA<DioException>()));
    expect(refreshes, 0);
  });
}
