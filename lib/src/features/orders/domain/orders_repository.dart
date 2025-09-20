import '../../cart/domain/cart.dart';
import 'order.dart';

abstract interface class OrdersRepository {
  /// Returns the order number.
  Future<int> placeOrder({required int userId, required List<CartItem> items});

  /// The account's past orders as DummyJSON has them.
  Future<List<Order>> history(int userId);
}
