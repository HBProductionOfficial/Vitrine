import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitrine/src/core/network/api_exception.dart';
import 'package:vitrine/src/features/shop/data/dummy_json_products_repository.dart';
import 'package:vitrine/src/features/shop/domain/product.dart';
import 'package:vitrine/src/features/shop/domain/products_repository.dart';
import 'package:vitrine/src/features/shop/presentation/shop_controller.dart';

/// Serves [total] made-up products. Titles start with the search or
/// category they were asked for, so tests can tell which request won.
class FakeProductsRepository implements ProductsRepository {
  FakeProductsRepository({this.total = 45});

  final int total;
  final calls = <String>[];
  Object? failWith;

  /// When set, the next fetch waits for it, to simulate a slow response.
  Completer<void>? hold;

  @override
  Future<ProductPage> fetch({
    required int skip,
    int limit = 20,
    String query = '',
    String? category,
    ProductSort sort = ProductSort.recommended,
  }) async {
    final tag = query.isNotEmpty ? query : (category ?? 'all');
    calls.add('$tag@$skip');
    final wait = hold;
    hold = null;
    if (wait != null) await wait.future;
    if (failWith != null) throw failWith!;
    return ProductPage([
      for (var i = skip; i < min(skip + limit, total); i++) Product(id: i, title: '$tag $i', price: 1, thumbnail: ''),
    ], total: total);
  }

  @override
  Future<List<ProductCategory>> categories() async => const [];

  @override
  Future<Product> product(int id) async => throw UnimplementedError();
}

void main() {
  late FakeProductsRepository repo;
  late ProviderContainer container;

  ShopController controller() => container.read(shopControllerProvider.notifier);
  ShopState state() => container.read(shopControllerProvider);

  Future<void> start() async {
    container = ProviderContainer.test(overrides: [productsRepositoryProvider.overrideWithValue(repo)]);
    container.read(shopControllerProvider);
    await pumpEventQueue();
  }

  setUp(() => repo = FakeProductsRepository());

  test('loads the first page', () async {
    await start();
    expect(state().products, hasLength(20));
    expect(state().hasMore, isTrue);
  });

  test('pages until everything is loaded, then stops asking', () async {
    await start();
    await controller().loadMore();
    await controller().loadMore();
    expect(state().products, hasLength(45));
    expect(state().hasMore, isFalse);

    await controller().loadMore();
    expect(repo.calls, ['all@0', 'all@20', 'all@40']);
  });

  test('search waits until typing stops', () async {
    await start();

    controller().search('p');
    controller().search('ph');
    controller().search('phone');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(repo.calls, ['all@0']);

    await Future<void>.delayed(ShopController.searchDelay);
    await pumpEventQueue();
    expect(repo.calls, ['all@0', 'phone@0']);
    expect(state().products.first.title, startsWith('phone'));
  });

  test('a slow older search does not replace a newer one', () async {
    await start();
    final slow = Completer<void>();
    repo.hold = slow;

    controller().search('slow', now: true);
    controller().search('fast', now: true);
    await pumpEventQueue();
    expect(state().products.first.title, startsWith('fast'));

    slow.complete();
    await pumpEventQueue();
    expect(state().products.first.title, startsWith('fast'));
  });

  test('changing the category starts again from the first page', () async {
    await start();
    await controller().loadMore();

    controller().selectCategory('beauty');
    await pumpEventQueue();

    expect(state().products, hasLength(20));
    expect(state().products.first.title, startsWith('beauty'));
  });

  test('a failed first page can be retried', () async {
    repo.failWith = const ApiException(ApiErrorKind.network);
    await start();
    expect(state().error, isA<ApiException>());
    expect(state().products, isEmpty);

    repo.failWith = null;
    await controller().refresh();
    expect(state().error, isNull);
    expect(state().products, hasLength(20));
  });

  test('a failed next page keeps what is on screen', () async {
    await start();
    repo.failWith = const ApiException(ApiErrorKind.timeout);
    await controller().loadMore();

    expect(state().moreError, isA<ApiException>());
    expect(state().products, hasLength(20));

    repo.failWith = null;
    await controller().retryMore();
    expect(state().products, hasLength(40));
  });
}
