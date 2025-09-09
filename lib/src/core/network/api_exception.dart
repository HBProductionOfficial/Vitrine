import 'package:dio/dio.dart';

enum ApiErrorKind {
  network,
  timeout,
  invalidCredentials,
  unauthorized,
  forbidden,
  notFound,
  rateLimited,
  badRequest,
  server,
  unknown,
}

class ApiException implements Exception {
  const ApiException(this.kind, {this.statusCode, this.message});

  final ApiErrorKind kind;
  final int? statusCode;

  /// Message from the server, kept for logs. The UI shows its own copy.
  final String? message;

  factory ApiException.fromDio(DioException e) {
    final status = e.response?.statusCode;
    final message = _serverMessage(e.response?.data);
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return ApiException(ApiErrorKind.timeout, message: message);
      case DioExceptionType.connectionError:
        return ApiException(ApiErrorKind.network, message: message);
      case DioExceptionType.badResponse:
        return ApiException(_kindFor(status), statusCode: status, message: message);
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        // On the web a CORS or offline failure surfaces as `unknown` with no response.
        if (e.response == null) return ApiException(ApiErrorKind.network, message: message);
        return ApiException(ApiErrorKind.unknown, statusCode: status, message: message);
    }
  }

  static ApiErrorKind _kindFor(int? status) {
    return switch (status) {
      400 => ApiErrorKind.badRequest,
      401 => ApiErrorKind.unauthorized,
      403 || 405 => ApiErrorKind.forbidden,
      404 => ApiErrorKind.notFound,
      429 => ApiErrorKind.rateLimited,
      final s? when s >= 500 => ApiErrorKind.server,
      _ => ApiErrorKind.unknown,
    };
  }

  static String? _serverMessage(Object? data) {
    if (data is Map && data['message'] is String) return data['message'] as String;
    if (data is Map && data['error'] is String) return data['error'] as String;
    return null;
  }

  @override
  String toString() => 'ApiException($kind, status: $statusCode, message: $message)';
}
