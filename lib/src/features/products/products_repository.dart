import '../../api/api_client.dart';
import 'product_detail.dart';
import 'product_summary.dart';

class ProductsPageResult {
  const ProductsPageResult({
    required this.items,
    required this.hasNext,
    this.totalCount,
  });

  final List<ProductSummary> items;
  final bool hasNext;
  final int? totalCount;
}

class ProductsRepository {
  ProductsRepository(this._api);
  final ApiClient _api;

  Future<ProductsPageResult> fetchProductsPage({
    required int page,
    int pageSize = 20,
    String? categorySlug,
    String ordering = '-created_at',
  }) async {
    final query = <String, String>{
      'page': '$page',
      'page_size': '$pageSize',
      'ordering': ordering,
    };
    if (categorySlug != null && categorySlug.isNotEmpty) {
      query['category'] = categorySlug;
    }

    final json = await _api.getJson('/api/v1/products/', query: query);
    final results = json['results'];
    final items = results is List
        ? results
            .whereType<Map<String, dynamic>>()
            .map(ProductSummary.fromJson)
            .toList(growable: false)
        : <ProductSummary>[];

    final next = json['next'];
    final hasNext = next != null && next.toString().trim().isNotEmpty;
    final count = json['count'];
    return ProductsPageResult(
      items: items,
      hasNext: hasNext,
      totalCount: count is int ? count : int.tryParse('$count'),
    );
  }

  Future<List<ProductSummary>> fetchProducts({
    required int pageSize,
    String? categorySlug,
    String ordering = '-created_at',
  }) async {
    final page = await fetchProductsPage(
      page: 1,
      pageSize: pageSize,
      categorySlug: categorySlug,
      ordering: ordering,
    );
    return page.items;
  }

  Future<ProductDetail> fetchProductDetail(String slug) async {
    final json = await _api.getJson('/api/v1/products/$slug/');
    return ProductDetail.fromJson(json);
  }
}

