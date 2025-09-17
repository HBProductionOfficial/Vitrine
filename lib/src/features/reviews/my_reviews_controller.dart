import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/preferences.dart';
import '../auth/presentation/auth_controller.dart';
import '../shop/domain/product.dart';

/// Reviews the signed-in user wrote, by product id. DummyJSON has no way to
/// add a review, so they're kept on the device, per account.
class MyReviewsController extends Notifier<Map<int, Review>> {
  String? _key;

  @override
  Map<int, Review> build() {
    final userId = ref.watch(currentUserIdProvider);
    _key = userId == null ? null : 'reviews.$userId';
    final raw = _key == null ? null : ref.read(preferencesProvider).getString(_key!);
    if (raw == null) return const {};
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final entry in json.entries) int.parse(entry.key): Review.fromJson(entry.value as Map<String, dynamic>),
      };
    } catch (_) {
      return const {};
    }
  }

  void save(int productId, {required int rating, required String comment, required String reviewer}) {
    _write({
      ...state,
      productId: Review(rating: rating, comment: comment.trim(), reviewer: reviewer, date: DateTime.now()),
    });
  }

  /// Returns the removed review so it can be put back.
  Review? remove(int productId) {
    final removed = state[productId];
    if (removed != null) _write({...state}..remove(productId));
    return removed;
  }

  void restore(int productId, Review review) => _write({...state, productId: review});

  void _write(Map<int, Review> reviews) {
    state = reviews;
    final key = _key;
    if (key == null) return;
    final json = jsonEncode({for (final e in reviews.entries) '${e.key}': e.value.toJson()});
    unawaited(ref.read(preferencesProvider).setString(key, json));
  }
}

final myReviewsProvider = NotifierProvider<MyReviewsController, Map<int, Review>>(MyReviewsController.new);
