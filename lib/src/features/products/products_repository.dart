import '../../api/api_client.dart';
import 'product_detail.dart';
import 'products_list_cache.dart';
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
    final cached = ProductsListCache.get(
      page: page,
      categorySlug: categorySlug,
      ordering: ordering,
    );
    if (cached != null) return cached;

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
    final countRaw = json['count'];
    final totalCount = countRaw is int ? countRaw : int.tryParse('$countRaw');

    var hasNext = next != null && next.toString().trim().isNotEmpty;
    if (!hasNext && totalCount != null && totalCount > 0) {
      hasNext = (page * pageSize) < totalCount;
    }
    if (!hasNext && items.length >= pageSize) {
      hasNext = true;
    }

    final result = ProductsPageResult(
      items: items,
      hasNext: hasNext,
      totalCount: totalCount,
    );
    ProductsListCache.put(
      page: page,
      categorySlug: categorySlug,
      ordering: ordering,
      result: result,
    );
    return result;
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

