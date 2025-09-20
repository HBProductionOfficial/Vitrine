import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_controller.dart';
import 'auth_interceptor.dart';
import 'token_holder.dart';

abstract final class ApiUrls {
  static const dummyJson = 'https://dummyjson.com';
  static const restfulApi = 'https://api.restful-api.dev';
}

/// Where requests actually go. Null is the real network; the end-to-end
/// tests put a fake server here so they don't depend on the public APIs.
final httpAdapterProvider = Provider<HttpClientAdapter?>((ref) => null);

Dio _client(Ref ref, String baseUrl) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );
  final adapter = ref.watch(httpAdapterProvider);
  if (adapter != null) dio.httpClientAdapter = adapter;
  return dio;
}

/// DummyJSON: login, profile, products and orders.
final dummyJsonClientProvider = Provider<Dio>((ref) {
  final dio = _client(ref, ApiUrls.dummyJson);
  dio.interceptors.add(
    AuthInterceptor(
      tokens: ref.watch(tokenHolderProvider),
      plainClient: _client(ref, ApiUrls.dummyJson),
      onSessionExpired: () => ref.read(authControllerProvider.notifier).onSessionExpired(),
      onRefreshed: (refresh) => ref.read(authControllerProvider.notifier).onTokensRefreshed(refresh),
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});

/// restful-api.dev: the device list from the original assignment.
final restfulApiClientProvider = Provider<Dio>((ref) {
  final dio = _client(ref, ApiUrls.restfulApi);
  ref.onDispose(dio.close);
  return dio;
});
