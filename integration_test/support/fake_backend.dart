import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'fixtures.dart';

/// Stands in for DummyJSON and restful-api.dev. It answers from real
/// captured responses, keeps what the app sends, and can be switched off to
/// see how the app copes with the network going away.
class FakeBackend implements HttpClientAdapter {
  final _products = (jsonDecode(productsJson) as List<dynamic>).cast<Map<String, dynamic>>();
  final _user = jsonDecode(userJson) as Map<String, dynamic>;

  /// Every request fails as if there were no connection.
  bool offline = false;

  /// Bodies of the orders the app placed.
  final placedOrders = <Map<String, dynamic>>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    // A little latency, so loading states actually appear.
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (offline) {
      throw DioException.connectionError(requestOptions: options, reason: 'The fake server is switched off');
    }
    final (status, body) = _answer(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  (int, Object?) _answer(RequestOptions request) {
    final uri = request.uri;
    final path = uri.path;

    if (uri.host == 'api.restful-api.dev') {
      if (request.method == 'GET' && path == '/objects') return (200, jsonDecode(objectsJson));
      return (404, {'error': 'Not in the fake: ${request.method} $path'});
    }

    switch ((request.method, path)) {
      case ('POST', '/auth/login'):
        final body = request.data as Map<String, dynamic>;
        if (body['username'] == 'emilys' && body['password'] == 'emilyspass') {
          return (200, {..._user, 'accessToken': 'access-token', 'refreshToken': 'refresh-token'});
        }
        return (400, {'message': 'Invalid credentials'});
      case ('POST', '/auth/refresh'):
        return (200, {'accessToken': 'access-token-2', 'refreshToken': 'refresh-token-2'});
      case ('GET', '/auth/me'):
        return (200, _user);
      case ('GET', '/products/categories'):
        return (200, jsonDecode(categoriesJson));
      case ('GET', '/carts/user/1'):
        return (200, jsonDecode(cartsJson));
      case ('POST', '/carts/add'):
        final body = request.data as Map<String, dynamic>;
        placedOrders.add(body);
        return (200, {'id': 209, 'userId': body['userId'], 'products': body['products']});
    }

    if (path == '/products' || path == '/products/search' || path.startsWith('/products/category/')) {
      return (200, _page(uri));
    }
    final single = RegExp(r'^/products/(\d+)$').firstMatch(path);
    if (single != null) {
      final id = int.parse(single.group(1)!);
      final product = _products.where((p) => p['id'] == id).firstOrNull;
      return product == null ? (404, {'message': "Product with id '$id' not found"}) : (200, product);
    }
    return (404, {'message': 'Not in the fake: ${request.method} $path'});
  }

  Map<String, dynamic> _page(Uri uri) {
    final query = uri.queryParameters;
    var list = _products;
    if (uri.path == '/products/search') {
      final term = (query['q'] ?? '').toLowerCase();
      list = list.where((p) => (p['title'] as String).toLowerCase().contains(term)).toList();
    } else if (uri.path.startsWith('/products/category/')) {
      final slug = uri.pathSegments.last;
      list = list.where((p) => p['category'] == slug).toList();
    }
    final sortBy = query['sortBy'];
    if (sortBy != null) {
      list = [...list]..sort((a, b) => (a[sortBy] as num).compareTo(b[sortBy] as num));
      if (query['order'] == 'desc') list = list.reversed.toList();
    }
    final skip = int.tryParse(query['skip'] ?? '') ?? 0;
    final limit = int.tryParse(query['limit'] ?? '') ?? 30;
    return {'products': list.skip(skip).take(limit).toList(), 'total': list.length, 'skip': skip, 'limit': limit};
  }

  @override
  void close({bool force = false}) {}
}
