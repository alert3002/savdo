import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../search/product_search_controller.dart' show apiClientProvider;

final engagementRepositoryProvider = Provider<EngagementRepository>(
  (ref) => EngagementRepository(ref.watch(apiClientProvider)),
);

class ClientDataPayload {
  const ClientDataPayload({
    this.favoriteSlugs,
    this.compareSlugs,
    this.cart,
  });

  final List<String>? favoriteSlugs;
  final List<String>? compareSlugs;
  final List<Map<String, dynamic>>? cart;

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    if (favoriteSlugs != null) m['favorite_slugs'] = favoriteSlugs;
    if (compareSlugs != null) m['compare_slugs'] = compareSlugs;
    if (cart != null) m['cart'] = cart;
    return m;
  }
}

class EngagementRepository {
  EngagementRepository(this._api);
  final ApiClient _api;

  Future<Map<String, dynamic>> fetchClientData(String bearer) async {
    return _api.getJson('/api/v1/users/client-data/', bearerToken: bearer);
  }

  Future<Map<String, dynamic>> patchClientData({
    required String bearer,
    required ClientDataPayload payload,
  }) async {
    return _api.patchJson(
      '/api/v1/users/client-data/',
      bearerToken: bearer,
      body: payload.toJson(),
    );
  }
}
