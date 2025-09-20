import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitrine/src/core/storage/preferences.dart';
import 'package:vitrine/src/features/auth/presentation/auth_controller.dart';
import 'package:vitrine/src/features/cart/domain/cart.dart';
import 'package:vitrine/src/features/orders/data/dummy_json_orders_repository.dart';
import 'package:vitrine/src/features/orders/domain/order.dart';
import 'package:vitrine/src/features/orders/presentation/orders_controller.dart';
import 'package:vitrine/src/features/shop/domain/product.dart';

import '../../helpers/fake_http.dart';

/// Trimmed from a real /carts/user/1 response.
const _history = {
  'carts': [
    {
      'id': 1,
      'products': [
        {
          'id': 162,
          'title': 'Blue Frock',
          'price': 29.99,
          'quantity': 4,
          'total': 119.96,
          'discountPercentage': 12.13,
          'discountedTotal': 105.41,
          'thumbnail': 'https://cdn.dummyjson.com/product-images/tops/blue-frock/thumbnail.webp',
        },
      ],
      'total': 119.96,
      'discountedTotal': 105.41,
      'userId': 1,
      'totalProducts': 1,
      'totalQuantity': 4,
    },
  ],
  'total': 1,
  'skip': 0,
  'limit': 1,
};

const _lipstick = Product(id: 4, title: 'Red Lipstick', price: 12.99, discountPercentage: 12.16, thumbnail: '');

void main() {
  test('reads the account history from DummyJSON', () async {
    final (dio, adapter) = fakeDio((_) => const FakeResponse(200, _history));

    final orders = await DummyJsonOrdersRepository(dio).history(1);

    expect(adapter.requests.single.path, '/carts/user/1');
    final order = orders.single;
    expect(order.ref, 'd1');
    expect(order.placedHere, isFalse);
    expect(order.quantity, 4);
    expect(order.lines.single.total, 105.41);
    expect(order.discount, 14.55);
  });

  test('an order from the cart keeps the exact totals and reads back the same', () {
    final placedAt = DateTime.utc(2026, 10, 17, 22, 40);
    final order = Order.fromCart(209, const Cart([CartItem(_lipstick, 3)]), placedAt);

    expect(order.total, 34.23);
    expect(order.ref, 'p${placedAt.millisecondsSinceEpoch}');

    final copy = Order.fromJson(order.toJson());
    expect(copy.ref, order.ref);
    expect(copy.total, order.total);
    expect(copy.subtotal, order.subtotal);
    expect(copy.lines.single.quantity, 3);
  });

  group('placed orders', () {
    late SharedPreferences prefs;

    ProviderContainer containerFor(int userId) => ProviderContainer.test(
      overrides: [preferencesProvider.overrideWithValue(prefs), currentUserIdProvider.overrideWithValue(userId)],
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('newest first, and still there after a restart', () {
      final orders = containerFor(1).read(placedOrdersProvider.notifier);
      orders.add(Order.fromCart(209, const Cart([CartItem(_lipstick, 1)]), DateTime(2026, 10, 17, 10)));
      orders.add(Order.fromCart(209, const Cart([CartItem(_lipstick, 2)]), DateTime(2026, 10, 17, 11)));

      final saved = containerFor(1).read(placedOrdersProvider);
      expect(saved.map((o) => o.quantity), [2, 1]);
    });

    test('each account has its own', () {
      containerFor(1)
          .read(placedOrdersProvider.notifier)
          .add(Order.fromCart(209, const Cart([CartItem(_lipstick, 1)]), DateTime(2026, 10, 17)));
      expect(containerFor(2).read(placedOrdersProvider), isEmpty);
    });
  });
}
