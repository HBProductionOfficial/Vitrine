import 'cart.dart';

abstract interface class OrdersRepository {
  /// Returns the order number.
  Future<int> placeOrder({required int userId, required List<CartItem> items});
}
