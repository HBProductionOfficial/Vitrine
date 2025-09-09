import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_clients.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/auth_interceptor.dart';
import '../domain/auth_repository.dart';
import '../domain/user.dart';

class DummyJsonAuthRepository implements AuthRepository {
  DummyJsonAuthRepository(this._dio);

  final Dio _dio;

  static const _sessionMinutes = 30;

  @override
  Future<(User, AuthTokens)> login(String username, String password) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'username': username.trim(), 'password': password, 'expiresInMins': _sessionMinutes},
      );
      final body = response.data!;
      return (User.fromJson(body), _tokens(body));
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 400 || status == 401) {
        throw ApiException(ApiErrorKind.invalidCredentials, statusCode: status);
      }
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<AuthTokens> refresh(String refreshToken) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken, 'expiresInMins': _sessionMinutes},
      );
      return _tokens(response.data!);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // DummyJSON answers an expired or unknown refresh token with 401 or 403.
      if (status == 401 || status == 403) {
        throw ApiException(ApiErrorKind.unauthorized, statusCode: status);
      }
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<User> currentUser() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/auth/me',
        options: Options(extra: {AuthInterceptor.requiresAuth: true}),
      );
      return User.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<int> signUp(SignUpRequest request) async {
    try {
      // DummyJSON validates and echoes the user back, but doesn't store it.
      final response = await _dio.post<Map<String, dynamic>>('/users/add', data: request.toJson());
      return response.data!['id'] as int;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    // DummyJSON has no reset endpoint, so this only simulates the round trip.
    await Future<void>.delayed(const Duration(milliseconds: 700));
  }

  AuthTokens _tokens(Map<String, dynamic> body) =>
      AuthTokens(accessToken: body['accessToken'] as String, refreshToken: body['refreshToken'] as String);
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => DummyJsonAuthRepository(ref.watch(dummyJsonClientProvider)),
);
