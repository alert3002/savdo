import '../../api/api_client.dart';

class CheckoutRepository {
  CheckoutRepository(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> checkout({
    required String bearerToken,
    required List<Map<String, dynamic>> items,
    required String deliveryAddress,
  }) {
    return _api.postJson(
      '/api/v1/orders/checkout/',
      bearerToken: bearerToken,
      body: {
        'items': items,
        'delivery_address': deliveryAddress.trim(),
      },
    );
  }
}
