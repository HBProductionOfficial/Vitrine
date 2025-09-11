import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/preferences.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../shop/domain/product.dart';

/// Products the user hearted, newest first.
class SavedController extends Notifier<List<Product>> {
  String? _key;

  @override
  List<Product> build() {
    final userId = ref.watch(currentUserIdProvider);
    _key = userId == null ? null : 'saved.$userId';
    final raw = _key == null ? null : ref.read(preferencesProvider).getString(_key!);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>().map(Product.fromJson).toList();
    } catch (_) {
      return const [];
    }
  }

  void toggle(Product product) {
    final saved = state.any((p) => p.id == product.id);
    state = saved ? state.where((p) => p.id != product.id).toList() : [product, ...state];
    final key = _key;
    if (key != null) {
      final json = jsonEncode([for (final p in state) p.toSummaryJson()]);
      unawaited(ref.read(preferencesProvider).setString(key, json));
    }
  }
}

final savedProvider = NotifierProvider<SavedController, List<Product>>(SavedController.new);
