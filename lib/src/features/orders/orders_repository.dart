import '../../api/api_client.dart';
import 'order_detail.dart';
import 'order_summary.dart';

class OrdersRepository {
  OrdersRepository(this._api);

  final ApiClient _api;

  Future<List<OrderSummary>> fetchMyOrders({
    required String bearerToken,
  }) async {
    final json = await _api.getJson(
      '/api/v1/orders/',
      bearerToken: bearerToken,
      query: const {
        'page_size': '50',
      },
    );

    final results = json['results'];
    if (results is! List) return const [];

    return results
        .whereType<Map<String, dynamic>>()
        .map(OrderSummary.fromJson)
        .toList(growable: false);
  }

  Future<OrderDetail> fetchOrderDetail({
    required String bearerToken,
    required String orderId,
  }) async {
    final json = await _api.getJson(
      '/api/v1/orders/$orderId/',
      bearerToken: bearerToken,
    );
    return OrderDetail.fromJson(json);
  }

  Future<void> cancelOrder({
    required String bearerToken,
    required String orderId,
  }) async {
    await _api.postJson(
      '/api/v1/orders/$orderId/cancel/',
      bearerToken: bearerToken,
      body: const {'note': 'Отменено пользователем'},
    );
  }
}

