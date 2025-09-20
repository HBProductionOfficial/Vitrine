import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/preferences.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/dummy_json_orders_repository.dart';
import '../domain/order.dart';

/// Orders placed in the app, newest first. DummyJSON doesn't keep them, so
/// they're stored on the device per account, like the cart.
class PlacedOrdersController extends Notifier<List<Order>> {
  String? _key;

  @override
  List<Order> build() {
    final userId = ref.watch(currentUserIdProvider);
    _key = userId == null ? null : 'orders.$userId';
    final raw = _key == null ? null : ref.read(preferencesProvider).getString(_key!);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>().map(Order.fromJson).toList();
    } catch (_) {
      return const [];
    }
  }

  void add(Order order) {
    state = [order, ...state];
    final key = _key;
    if (key == null) return;
    unawaited(ref.read(preferencesProvider).setString(key, jsonEncode([for (final o in state) o.toJson()])));
  }
}

final placedOrdersProvider = NotifierProvider<PlacedOrdersController, List<Order>>(PlacedOrdersController.new);

/// The account's history on DummyJSON.
final orderHistoryProvider = FutureProvider.autoDispose<List<Order>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  return ref.watch(ordersRepositoryProvider).history(userId);
});
