import 'package:flutter/foundation.dart';

@immutable
class Review {
  const Review({required this.rating, required this.comment, required this.reviewer, this.date});

  final int rating;
  final String comment;
  final String reviewer;
  final DateTime? date;

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      rating: (json['rating'] as num?)?.round() ?? 0,
      comment: json['comment'] as String? ?? '',
      reviewer: json['reviewerName'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? ''),
    );
  }
}

@immutable
class Product {
  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.thumbnail,
    this.description = '',
    this.category = '',
    this.brand,
    this.discountPercentage = 0,
    this.rating = 0,
    this.stock = 0,
    this.images = const [],
    this.reviews = const [],
    this.warranty,
    this.shipping,
    this.returnPolicy,
  });

  final int id;
  final String title;
  final String description;
  final String category;
  final String? brand;

  /// List price. DummyJSON sends the discount separately.
  final double price;
  final double discountPercentage;
  final double rating;
  final int stock;
  final String thumbnail;
  final List<String> images;
  final List<Review> reviews;
  final String? warranty;
  final String? shipping;
  final String? returnPolicy;

  /// What the customer pays, rounded to cents.
  double get finalPrice => (price * (100 - discountPercentage)).roundToDouble() / 100;

  int get percentOff => discountPercentage.round();

  /// Every DummyJSON product has some discount; only the bigger ones are
  /// worth pointing out in the grid.
  bool get isDeal => percentOff >= 10;

  bool get inStock => stock > 0;

  List<String> get gallery => images.isEmpty ? [thumbnail] : images;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      brand: json['brand'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      thumbnail: json['thumbnail'] as String? ?? '',
      images: (json['images'] as List<dynamic>?)?.whereType<String>().toList() ?? const [],
      reviews:
          (json['reviews'] as List<dynamic>?)?.whereType<Map<String, dynamic>>().map(Review.fromJson).toList() ??
          const [],
      warranty: json['warrantyInformation'] as String?,
      shipping: json['shippingInformation'] as String?,
      returnPolicy: json['returnPolicy'] as String?,
    );
  }

  /// The fields a list row needs, in DummyJSON's own shape so [fromJson]
  /// reads it back. Used for the saved cart and favourites.
  Map<String, dynamic> toSummaryJson() => {
    'id': id,
    'title': title,
    'category': category,
    'brand': brand,
    'price': price,
    'discountPercentage': discountPercentage,
    'rating': rating,
    'stock': stock,
    'thumbnail': thumbnail,
  };
}

@immutable
class ProductCategory {
  const ProductCategory({required this.slug, required this.name});

  final String slug;
  final String name;

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(slug: json['slug'] as String, name: json['name'] as String? ?? json['slug'] as String);
  }
}

enum ProductSort { recommended, priceLow, priceHigh, rating }

@immutable
class ProductPage {
  const ProductPage(this.products, {required this.total});

  final List<Product> products;
  final int total;
}
