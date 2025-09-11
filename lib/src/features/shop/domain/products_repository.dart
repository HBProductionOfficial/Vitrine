import 'product.dart';

abstract interface class ProductsRepository {
  /// A page of products. A non-empty [query] searches the whole catalog and
  /// ignores [category].
  Future<ProductPage> fetch({
    required int skip,
    int limit = 20,
    String query = '',
    String? category,
    ProductSort sort = ProductSort.recommended,
  });

  Future<List<ProductCategory>> categories();

  Future<Product> product(int id);
}
