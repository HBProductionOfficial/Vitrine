import 'package:dio/dio.dart';

import 'token_holder.dart';

/// Requests opt in to auth with `Options(extra: {AuthInterceptor.requiresAuth: true})`.
/// On a 401 the interceptor refreshes the access token once and replays the
/// request; if the refresh fails too, [onSessionExpired] signs the user out.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.tokens,
    required this.refreshClient,
    required this.retryClient,
    required this.onSessionExpired,
  });

  static const requiresAuth = 'requiresAuth';
  static const _retried = 'retriedAfterRefresh';

  final TokenHolder tokens;

  /// Separate client without this interceptor, so refreshing can't loop.
  final Dio refreshClient;
  final Dio Function() retryClient;
  final void Function() onSessionExpired;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = tokens.accessToken;
    if (options.extra[requiresAuth] == true && token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    final refresh = tokens.refreshToken;
    final canRetry =
        err.response?.statusCode == 401 &&
        request.extra[requiresAuth] == true &&
        request.extra[_retried] != true &&
        refresh != null;
    if (!canRetry) return handler.next(err);

    try {
      final response = await refreshClient.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refresh, 'expiresInMins': 30},
      );
      final body = response.data!;
      tokens.update(access: body['accessToken'] as String, refresh: body['refreshToken'] as String);
    } on DioException {
      tokens.clear();
      onSessionExpired();
      return handler.next(err);
    }

    request.extra[_retried] = true;
    request.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
    try {
      handler.resolve(await retryClient().fetch(request));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
