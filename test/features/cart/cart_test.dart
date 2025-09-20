import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitrine/src/core/network/api_exception.dart';
import 'package:vitrine/src/core/storage/preferences.dart';
import 'package:vitrine/src/features/auth/presentation/auth_controller.dart';
import 'package:vitrine/src/features/cart/domain/cart.dart';
import 'package:vitrine/src/features/orders/data/dummy_json_orders_repository.dart';
import 'package:vitrine/src/features/orders/domain/order.dart';
import 'package:vitrine/src/features/orders/domain/orders_repository.dart';
import 'package:vitrine/src/features/orders/presentation/orders_controller.dart';
import 'package:vitrine/src/features/cart/presentation/cart_controller.dart';
import 'package:vitrine/src/features/shop/domain/product.dart';

const _mascara = Product(id: 1, title: 'Mascara', price: 9.99, discountPercentage: 10.48, stock: 99, thumbnail: '');
const _lastOne = Product(id: 2, title: 'Battery pack', price: 99.99, stock: 1, thumbnail: '');
const _plenty = Product(id: 3, title: 'Water', price: 0.99, stock: 500, thumbnail: '');

class FakeOrders implements OrdersRepository {
  bool fail = false;
  List<CartItem>? placed;

  @override
  Future<int> placeOrder({required int userId, required List<CartItem> items}) async {
    if (fail) throw const ApiException(ApiErrorKind.server, statusCode: 500);
    placed = items;
    return 51;
  }

  @override
  Future<List<Order>> history(int userId) async => const [];
}

void main() {
  group('totals', () {
    test('subtotal, discount and total for a discounted product', () {
      const cart = Cart([CartItem(_mascara, 2)]);
      expect(cart.count, 2);
      expect(cart.subtotal, 19.98);
      expect(cart.total, 17.88);
      expect(cart.discount, 2.10);
    });

    test('adding prices up in cents avoids floating point drift', () {
      const cart = Cart([
        CartItem(Product(id: 10, title: 'a', price: 0.1, thumbnail: ''), 1),
        CartItem(Product(id: 11, title: 'b', price: 0.2, thumbnail: ''), 1),
      ]);
      expect(cart.total, 0.3);
    });
  });

  group('cart controller', () {
    late SharedPreferences prefs;
    late FakeOrders orders;

    ProviderContainer containerFor(int? userId) => ProviderContainer.test(
      overrides: [
        preferencesProvider.overrideWithValue(prefs),
        currentUserIdProvider.overrideWithValue(userId),
        ordersRepositoryProvider.overrideWithValue(orders),
      ],
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      orders = FakeOrders();
    });

    test('adding the same product again raises its quantity', () {
      final container = containerFor(1);
      final cart = container.read(cartProvider.notifier);

      cart.add(_mascara);
      cart.add(_mascara);

      expect(container.read(cartProvider).items.single.quantity, 2);
    });

    test('quantity stops at the stock, and at ten for anything else', () {
      final container = containerFor(1);
      final cart = container.read(cartProvider.notifier);

      expect(cart.add(_lastOne), isTrue);
      expect(cart.add(_lastOne), isFalse);

      cart.add(_plenty);
      cart.setQuantity(_plenty.id, 50);
      expect(container.read(cartProvider).quantityOf(_plenty.id), CartController.maxPerItem);
    });

    test('adds a chosen amount, but never past the limit', () {
      final container = containerFor(1);
      final cart = container.read(cartProvider.notifier);

      expect(cart.add(_mascara, quantity: 3), isTrue);
      expect(container.read(cartProvider).quantityOf(_mascara.id), 3);

      expect(cart.add(_mascara, quantity: 20), isTrue);
      expect(container.read(cartProvider).quantityOf(_mascara.id), CartController.maxPerItem);

      expect(cart.add(_mascara, quantity: 1), isFalse);
      expect(cart.add(_lastOne, quantity: 4), isTrue);
      expect(container.read(cartProvider).quantityOf(_lastOne.id), 1);
    });

    test('a removed line can be put back where it was', () {
      final container = containerFor(1);
      final cart = container.read(cartProvider.notifier)
        ..add(_mascara)
        ..add(_lastOne)
        ..add(_plenty);

      final (item, index) = cart.remove(_lastOne.id)!;
      expect(container.read(cartProvider).items.map((i) => i.product.id), [1, 3]);

      cart.restore(item, index);
      expect(container.read(cartProvider).items.map((i) => i.product.id), [1, 2, 3]);
    });

    test('each account has its own cart', () {
      containerFor(1).read(cartProvider.notifier).add(_mascara);

      expect(containerFor(2).read(cartProvider).isEmpty, isTrue);
      expect(containerFor(1).read(cartProvider).count, 1);
    });

    test('checkout sends the lines and empties the cart', () async {
      final container = containerFor(1);
      final cart = container.read(cartProvider.notifier)..add(_mascara);

      expect(await cart.checkout(), 51);
      expect(orders.placed!.single.product.id, _mascara.id);
      expect(container.read(cartProvider).isEmpty, isTrue);

      // DummyJSON forgets the order, so the app keeps its own copy.
      final saved = container.read(placedOrdersProvider).single;
      expect(saved.id, 51);
      expect(saved.lines.single.title, 'Mascara');
      expect(saved.total, 8.94);
      expect(saved.placedHere, isTrue);
    });

    test('a failed checkout keeps the cart', () async {
      orders.fail = true;
      final container = containerFor(1);
      final cart = container.read(cartProvider.notifier)..add(_mascara);

      await expectLater(cart.checkout(), throwsA(isA<ApiException>()));
      expect(container.read(cartProvider).count, 1);
      expect(container.read(placedOrdersProvider), isEmpty);
    });
  });
}
