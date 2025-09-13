import 'package:flutter_test/flutter_test.dart';
import 'package:vitrine/src/core/network/api_exception.dart';
import 'package:vitrine/src/features/shop/data/dummy_json_products_repository.dart';
import 'package:vitrine/src/features/shop/domain/product.dart';

import '../../helpers/fake_http.dart';

const _page = {
  'products': [
    {'id': 1, 'title': 'Essence Mascara Lash Princess', 'price': 9.99, 'discountPercentage': 10.48, 'stock': 99},
  ],
  'total': 194,
  'skip': 0,
  'limit': 20,
};

void main() {
  test('the plain list asks for a page with limit and skip', () async {
    final (dio, adapter) = fakeDio((_) => const FakeResponse(200, _page));

    final page = await DummyJsonProductsRepository(dio).fetch(skip: 40);

    final request = adapter.requests.single;
    expect(request.path, '/products');
    expect(request.queryParameters, {'limit': 20, 'skip': 40});
    expect(page.total, 194);
    expect(page.products.single.finalPrice, 8.94);
  });

  test('a search goes to /products/search and ignores the category', () async {
    final (dio, adapter) = fakeDio((_) => const FakeResponse(200, _page));

    await DummyJsonProductsRepository(dio).fetch(skip: 0, query: 'phone', category: 'beauty');

    expect(adapter.requests.single.path, '/products/search');
    expect(adapter.requests.single.queryParameters['q'], 'phone');
  });

  test('a category has its own path', () async {
    final (dio, adapter) = fakeDio((_) => const FakeResponse(200, _page));
    await DummyJsonProductsRepository(dio).fetch(skip: 0, category: 'smartphones');
    expect(adapter.requests.single.path, '/products/category/smartphones');
  });

  test('sort options map to sortBy and order', () async {
    final (dio, adapter) = fakeDio((_) => const FakeResponse(200, _page));
    final repo = DummyJsonProductsRepository(dio);

    await repo.fetch(skip: 0, sort: ProductSort.priceHigh);
    await repo.fetch(skip: 0, sort: ProductSort.rating);

    expect(adapter.requests[0].queryParameters, containsPair('sortBy', 'price'));
    expect(adapter.requests[0].queryParameters, containsPair('order', 'desc'));
    expect(adapter.requests[1].queryParameters, containsPair('sortBy', 'rating'));
  });

  test('a missing product is a notFound error', () async {
    final (dio, _) = fakeDio((_) => const FakeResponse(404, {'message': "Product with id '999' not found"}));
    await expectLater(
      DummyJsonProductsRepository(dio).product(999),
      throwsA(isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.notFound)),
    );
  });

  test('categories come back with slug and name', () async {
    final (dio, _) = fakeDio(
      (_) => const FakeResponse(200, [
        {'slug': 'mens-shirts', 'name': 'Mens Shirts', 'url': 'https://dummyjson.com/products/category/mens-shirts'},
      ]),
    );
    final categories = await DummyJsonProductsRepository(dio).categories();
    expect(categories.single.slug, 'mens-shirts');
    expect(categories.single.name, 'Mens Shirts');
  });
}
