import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/preferences.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../shop/domain/product.dart';
import '../data/dummy_json_orders_repository.dart';
import '../domain/cart.dart';

class CartController extends Notifier<Cart> {
  /// Cap per product so the stepper stays sensible for items with huge stock.
  static const maxPerItem = 10;

  String? _key;

  @override
  Cart build() {
    final userId = ref.watch(currentUserIdProvider);
    _key = userId == null ? null : 'cart.$userId';
    return _read();
  }

  int limitFor(Product product) => math.min(product.stock, maxPerItem);

  /// Adds one unit. Returns false if the product is already at its limit.
  bool add(Product product) {
    final current = state.quantityOf(product.id);
    if (current >= limitFor(product)) return false;
    if (current == 0) {
      _save(Cart([...state.items, CartItem(product, 1)]));
    } else {
      setQuantity(product.id, current + 1);
    }
    return true;
  }

  void setQuantity(int productId, int quantity) {
    _save(
      Cart([
        for (final item in state.items)
          item.product.id == productId ? item.withQuantity(quantity.clamp(1, limitFor(item.product))) : item,
      ]),
    );
  }

  /// Removes a line and hands back what [restore] needs for an undo.
  (CartItem, int)? remove(int productId) {
    final index = state.items.indexWhere((i) => i.product.id == productId);
    if (index < 0) return null;
    final item = state.items[index];
    _save(Cart([...state.items]..removeAt(index)));
    return (item, index);
  }

  void restore(CartItem item, int index) {
    _save(Cart([...state.items]..insert(math.min(index, state.items.length), item)));
  }

  /// Places the order and empties the cart. Returns the order number.
  Future<int> checkout() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || state.isEmpty) throw StateError('Nothing to check out');
    final orderId = await ref.read(ordersRepositoryProvider).placeOrder(userId: userId, items: state.items);
    if (ref.mounted) _save(const Cart());
    return orderId;
  }

  Cart _read() {
    final raw = _key == null ? null : ref.read(preferencesProvider).getString(_key!);
    if (raw == null) return const Cart();
    try {
      final items = (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>().map(CartItem.fromJson).toList();
      return Cart(items);
    } catch (_) {
      // A cart saved by an older version that no longer parses isn't worth crashing over.
      return const Cart();
    }
  }

  void _save(Cart cart) {
    state = cart;
    final key = _key;
    if (key == null) return;
    final json = jsonEncode([for (final item in cart.items) item.toJson()]);
    unawaited(ref.read(preferencesProvider).setString(key, json));
  }
}

final cartProvider = NotifierProvider<CartController, Cart>(CartController.new);
