import '../../api/api_client.dart';
import '../products/product_summary.dart';

class ProductSearchRepository {
  ProductSearchRepository(this._api);

  final ApiClient _api;

  Future<List<ProductSummary>> searchProducts(String query) async {
    final json = await _api.getJson(
      '/api/v1/products/',
      query: {
        'search': query,
        'page_size': '10',
      },
    );

    final results = json['results'];
    if (results is List) {
      return results
          .whereType<Map<String, dynamic>>()
          .map(ProductSummary.fromJson)
          .toList(growable: false);
    }
    return const [];
  }
}

