import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_clients.dart';
import '../../../core/network/api_exception.dart';
import '../domain/cart.dart';
import '../domain/orders_repository.dart';

class DummyJsonOrdersRepository implements OrdersRepository {
  DummyJsonOrdersRepository(this._dio);

  final Dio _dio;

  @override
  Future<int> placeOrder({required int userId, required List<CartItem> items}) async {
    try {
      // DummyJSON answers like a real order but doesn't keep it.
      final response = await _dio.post<Map<String, dynamic>>(
        '/carts/add',
        data: {
          'userId': userId,
          'products': [
            for (final item in items) {'id': item.product.id, 'quantity': item.quantity},
          ],
        },
      );
      return response.data!['id'] as int;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => DummyJsonOrdersRepository(ref.watch(dummyJsonClientProvider)),
);
