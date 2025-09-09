import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_controller.dart';
import 'auth_interceptor.dart';
import 'token_holder.dart';

abstract final class ApiUrls {
  static const dummyJson = 'https://dummyjson.com';
  static const restfulApi = 'https://api.restful-api.dev';
}

BaseOptions _options(String baseUrl) => BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    );

/// DummyJSON: login, profile, products and orders.
final dummyJsonClientProvider = Provider<Dio>((ref) {
  final dio = Dio(_options(ApiUrls.dummyJson));
  dio.interceptors.add(AuthInterceptor(
    tokens: ref.watch(tokenHolderProvider),
    refreshClient: Dio(_options(ApiUrls.dummyJson)),
    retryClient: () => dio,
    onSessionExpired: () => ref.read(authControllerProvider.notifier).onSessionExpired(),
  ));
  ref.onDispose(dio.close);
  return dio;
});

/// restful-api.dev: the device list from the original assignment.
final restfulApiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(_options(ApiUrls.restfulApi));
  ref.onDispose(dio.close);
  return dio;
});
