import 'package:flutter/foundation.dart';

import '../../cart/domain/cart.dart';

@immutable
class OrderLine {
  const OrderLine({
    required this.productId,
    required this.title,
    required this.thumbnail,
    required this.price,
    required this.quantity,
    required this.total,
  });

  final int productId;
  final String title;
  final String thumbnail;

  /// List price of one unit.
  final double price;
  final int quantity;

  /// What the line cost after discount.
  final double total;

  factory OrderLine.fromCartItem(CartItem item) {
    return OrderLine(
      productId: item.product.id,
      title: item.product.title,
      thumbnail: item.product.thumbnail,
      price: item.product.price,
      quantity: item.quantity,
      total: item.lineTotal,
    );
  }

  factory OrderLine.fromJson(Map<String, dynamic> json) {
    final quantity = (json['quantity'] as num?)?.toInt() ?? 1;
    final price = (json['price'] as num?)?.toDouble() ?? 0;
    return OrderLine(
      productId: json['id'] as int,
      title: json['title'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
      price: price,
      quantity: quantity,
      total: (json['discountedTotal'] as num?)?.toDouble() ?? price * quantity,
    );
  }

  /// DummyJSON's own field names, so [OrderLine.fromJson] reads it back.
  Map<String, dynamic> toJson() => {
    'id': productId,
    'title': title,
    'thumbnail': thumbnail,
    'price': price,
    'quantity': quantity,
    'discountedTotal': total,
  };
}

@immutable
class Order {
  const Order({required this.id, required this.lines, required this.subtotal, required this.total, this.placedAt});

  /// DummyJSON's number for it. Orders placed in the app all come back as
  /// the same number, so [ref] is what tells them apart.
  final int id;
  final List<OrderLine> lines;
  final double subtotal;
  final double total;

  /// Set for orders placed in the app; DummyJSON's history has no dates.
  final DateTime? placedAt;

  bool get placedHere => placedAt != null;

  int get quantity => lines.fold(0, (sum, line) => sum + line.quantity);

  double get discount => ((subtotal * 100).round() - (total * 100).round()) / 100;

  /// Stable id for links: "p" plus the time for orders placed here, "d" plus
  /// DummyJSON's number for the rest.
  String get ref => placedHere ? 'p${placedAt!.millisecondsSinceEpoch}' : 'd$id';

  /// Uses the app's own totals, which are exact to the cent; DummyJSON rounds
  /// discounted prices to whole dollars when an order is placed.
  factory Order.fromCart(int id, Cart cart, DateTime placedAt) {
    return Order(
      id: id,
      lines: [for (final item in cart.items) OrderLine.fromCartItem(item)],
      subtotal: cart.subtotal,
      total: cart.total,
      placedAt: placedAt,
    );
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    final placedAt = json['placedAt'] as String?;
    return Order(
      id: json['id'] as int,
      lines: (json['products'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(OrderLine.fromJson)
          .toList(),
      subtotal: (json['total'] as num?)?.toDouble() ?? 0,
      total: (json['discountedTotal'] as num?)?.toDouble() ?? 0,
      placedAt: placedAt == null ? null : DateTime.tryParse(placedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'products': [for (final line in lines) line.toJson()],
    'total': subtotal,
    'discountedTotal': total,
    'placedAt': ?placedAt?.toIso8601String(),
  };
}
