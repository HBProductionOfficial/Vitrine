import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_clients.dart';
import '../../../core/network/api_exception.dart';
import '../domain/product.dart';
import '../domain/products_repository.dart';

class DummyJsonProductsRepository implements ProductsRepository {
  DummyJsonProductsRepository(this._dio);

  final Dio _dio;

  @override
  Future<ProductPage> fetch({
    required int skip,
    int limit = 20,
    String query = '',
    String? category,
    ProductSort sort = ProductSort.recommended,
  }) async {
    // DummyJSON can't search inside a category, so a search covers everything.
    final path = query.isNotEmpty
        ? '/products/search'
        : category != null
        ? '/products/category/$category'
        : '/products';
    final (sortBy, order) = switch (sort) {
      ProductSort.recommended => (null, null),
      ProductSort.priceLow => ('price', 'asc'),
      ProductSort.priceHigh => ('price', 'desc'),
      ProductSort.rating => ('rating', 'desc'),
    };
    final json = await _get<Map<String, dynamic>>(path, {
      'limit': limit,
      'skip': skip,
      if (query.isNotEmpty) 'q': query,
      'sortBy': ?sortBy,
      'order': ?order,
    });
    final products = (json['products'] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();
    return ProductPage(products, total: json['total'] as int? ?? products.length);
  }

  @override
  Future<List<ProductCategory>> categories() async {
    final json = await _get<List<dynamic>>('/products/categories');
    return json.whereType<Map<String, dynamic>>().map(ProductCategory.fromJson).toList();
  }

  @override
  Future<Product> product(int id) async {
    return Product.fromJson(await _get<Map<String, dynamic>>('/products/$id'));
  }

  Future<T> _get<T>(String path, [Map<String, dynamic>? query]) async {
    try {
      final response = await _dio.get<T>(path, queryParameters: query);
      return response.data as T;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final productsRepositoryProvider = Provider<ProductsRepository>(
  (ref) => DummyJsonProductsRepository(ref.watch(dummyJsonClientProvider)),
);
