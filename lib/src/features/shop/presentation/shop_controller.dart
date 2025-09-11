import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dummy_json_products_repository.dart';
import '../domain/product.dart';

@immutable
class ShopState {
  const ShopState({
    this.query = '',
    this.category,
    this.sort = ProductSort.recommended,
    this.products = const [],
    this.total = 0,
    this.loading = true,
    this.loadingMore = false,
    this.error,
    this.moreError,
  });

  final String query;
  final String? category;
  final ProductSort sort;
  final List<Product> products;
  final int total;
  final bool loading;
  final bool loadingMore;

  /// The first page failed.
  final Object? error;

  /// A later page failed; what's already on screen stays.
  final Object? moreError;

  bool get hasMore => products.length < total;

  ShopState copyWith({
    String? query,
    String? category,
    bool clearCategory = false,
    ProductSort? sort,
    List<Product>? products,
    int? total,
    bool? loading,
    bool? loadingMore,
    Object? error,
    Object? moreError,
    bool clearErrors = false,
  }) {
    return ShopState(
      query: query ?? this.query,
      category: clearCategory ? null : (category ?? this.category),
      sort: sort ?? this.sort,
      products: products ?? this.products,
      total: total ?? this.total,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: clearErrors ? null : (error ?? this.error),
      moreError: clearErrors ? null : (moreError ?? this.moreError),
    );
  }
}

class ShopController extends Notifier<ShopState> {
  static const pageSize = 20;
  static const searchDelay = Duration(milliseconds: 300);

  Timer? _debounce;

  /// Bumped on every new first-page load so a slow, older response can't
  /// overwrite the results of a newer search.
  int _generation = 0;

  @override
  ShopState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(_reload);
    return const ShopState();
  }

  void search(String text, {bool now = false}) {
    _debounce?.cancel();
    final query = text.trim();
    void run() {
      if (query == state.query) return;
      state = state.copyWith(query: query);
      _reload();
    }

    if (now) {
      run();
    } else {
      _debounce = Timer(searchDelay, run);
    }
  }

  void selectCategory(String? slug) {
    if (slug == state.category) return;
    state = state.copyWith(category: slug, clearCategory: slug == null);
    _reload();
  }

  void setSort(ProductSort sort) {
    if (sort == state.sort) return;
    state = state.copyWith(sort: sort);
    _reload();
  }

  /// Pull to refresh keeps the current grid on screen until the new one is in.
  Future<void> refresh() => _reload(keepItems: true);

  Future<void> _reload({bool keepItems = false}) async {
    final generation = ++_generation;
    state = state.copyWith(
      loading: true,
      loadingMore: false,
      clearErrors: true,
      products: keepItems ? null : const [],
      total: keepItems ? null : 0,
    );
    try {
      final page = await ref
          .read(productsRepositoryProvider)
          .fetch(skip: 0, limit: pageSize, query: state.query, category: state.category, sort: state.sort);
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(products: page.products, total: page.total, loading: false);
    } catch (e) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(loading: false, error: e, products: const [], total: 0);
    }
  }

  Future<void> loadMore() async {
    final s = state;
    if (s.loading || s.loadingMore || s.moreError != null || !s.hasMore) return;
    final generation = _generation;
    state = s.copyWith(loadingMore: true);
    try {
      final page = await ref
          .read(productsRepositoryProvider)
          .fetch(skip: s.products.length, limit: pageSize, query: s.query, category: s.category, sort: s.sort);
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(products: [...state.products, ...page.products], total: page.total, loadingMore: false);
    } catch (e) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(loadingMore: false, moreError: e);
    }
  }

  Future<void> retryMore() {
    state = state.copyWith(clearErrors: true);
    return loadMore();
  }
}

final shopControllerProvider = NotifierProvider<ShopController, ShopState>(ShopController.new);

final categoriesProvider = FutureProvider<List<ProductCategory>>(
  (ref) => ref.watch(productsRepositoryProvider).categories(),
);
