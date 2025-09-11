import 'package:flutter/foundation.dart';

import '../../shop/domain/product.dart';

@immutable
class CartItem {
  const CartItem(this.product, this.quantity);

  final Product product;
  final int quantity;

  double get lineTotal => (_cents(product.finalPrice) * quantity) / 100;

  CartItem withQuantity(int quantity) => CartItem(product, quantity);

  Map<String, dynamic> toJson() => {'product': product.toSummaryJson(), 'quantity': quantity};

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(Product.fromJson(json['product'] as Map<String, dynamic>), json['quantity'] as int);
  }
}

/// Totals are added up in cents so they don't drift by a cent here and there.
@immutable
class Cart {
  const Cart([this.items = const []]);

  final List<CartItem> items;

  bool get isEmpty => items.isEmpty;

  /// Number of units, not lines.
  int get count => items.fold(0, (sum, item) => sum + item.quantity);

  int quantityOf(int productId) => items.where((i) => i.product.id == productId).firstOrNull?.quantity ?? 0;

  double get subtotal => _sum((p) => p.price) / 100;
  double get total => _sum((p) => p.finalPrice) / 100;
  double get discount => (_sum((p) => p.price) - _sum((p) => p.finalPrice)) / 100;

  int _sum(double Function(Product) price) {
    return items.fold(0, (sum, item) => sum + _cents(price(item.product)) * item.quantity);
  }
}

int _cents(double amount) => (amount * 100).round();
