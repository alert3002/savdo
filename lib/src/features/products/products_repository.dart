import '../../api/api_client.dart';
import 'product_detail.dart';
import 'product_summary.dart';

class ProductsRepository {
  ProductsRepository(this._api);
  final ApiClient _api;

  Future<List<ProductSummary>> fetchProducts({
    required int pageSize,
    String? categorySlug,
    String ordering = '-created_at',
  }) async {
    final query = <String, String>{
      'page_size': '$pageSize',
      'ordering': ordering,
    };
    if (categorySlug != null && categorySlug.isNotEmpty) {
      query['category'] = categorySlug;
    }

    final json = await _api.getJson('/api/v1/products/', query: query);
    final results = json['results'];
    if (results is List) {
      return results
          .whereType<Map<String, dynamic>>()
          .map(ProductSummary.fromJson)
          .toList(growable: false);
    }
    return const [];
  }

  Future<ProductDetail> fetchProductDetail(String slug) async {
    final json = await _api.getJson('/api/v1/products/$slug/');
    return ProductDetail.fromJson(json);
  }
}

