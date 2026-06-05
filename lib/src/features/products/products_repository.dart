import '../../api/api_client.dart';
import 'product_detail.dart';
import 'products_list_cache.dart';
import 'products_page_buffer.dart';
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
    final bufferKey = ProductsPageBuffer.keyFor(
      categorySlug: categorySlug,
      ordering: ordering,
    );
    final offset = (page - 1) * pageSize;

    if (page == 1 && offset == 0) {
      final cached = ProductsListCache.get(
        page: page,
        categorySlug: categorySlug,
        ordering: ordering,
      );
      if (cached != null) return cached;
    }

    await _ensureBufferLoaded(
      bufferKey: bufferKey,
      offset: offset,
      pageSize: pageSize,
      categorySlug: categorySlug,
      ordering: ordering,
    );

    final entry = ProductsPageBuffer.entry(bufferKey);
    if (entry == null || entry.items.isEmpty) {
      return const ProductsPageResult(items: [], hasNext: false, totalCount: 0);
    }

    final slice = entry.items.skip(offset).take(pageSize).toList(growable: false);
    final total = entry.totalCount;
    final bool hasNext;
    if (total != null && total > 0) {
      hasNext = offset + slice.length < total;
    } else {
      hasNext = slice.length >= pageSize &&
          (entry.apiHasNext || offset + slice.length < entry.items.length);
    }

    final result = ProductsPageResult(
      items: slice,
      hasNext: hasNext,
      totalCount: total,
    );

    ProductsListCache.put(
      page: page,
      categorySlug: categorySlug,
      ordering: ordering,
      result: result,
    );
    return result;
  }

  Future<void> _ensureBufferLoaded({
    required String bufferKey,
    required int offset,
    required int pageSize,
    String? categorySlug,
    required String ordering,
  }) async {
    while (true) {
      final entry = ProductsPageBuffer.entry(bufferKey);
      final loaded = entry?.items.length ?? 0;
      if (loaded > offset) return;

      final shouldFetch = entry == null || (entry.apiHasNext && loaded <= offset);
      if (!shouldFetch) return;

      final apiPage = entry == null ? 1 : entry.lastApiPage + 1;
      final fetched = await _fetchApiPage(
        apiPage: apiPage,
        pageSize: pageSize,
        categorySlug: categorySlug,
        ordering: ordering,
      );

      if (entry == null) {
        ProductsPageBuffer.setFirstPage(
          bufferKey,
          items: fetched.items,
          totalCount: fetched.totalCount,
          apiHasNext: fetched.apiHasNext,
          apiPage: apiPage,
        );
      } else if (fetched.items.isNotEmpty) {
        ProductsPageBuffer.append(
          bufferKey,
          fetched.items,
          apiPage: apiPage,
          apiHasNext: fetched.apiHasNext,
          totalCount: fetched.totalCount,
        );
      } else {
        ProductsPageBuffer.markApiExhausted(bufferKey);
        return;
      }

      final updated = ProductsPageBuffer.entry(bufferKey);
      if (updated == null || updated.items.length > offset) return;
      if (!updated.apiHasNext) return;
    }
  }

  Future<_ApiPage> _fetchApiPage({
    required int apiPage,
    required int pageSize,
    String? categorySlug,
    required String ordering,
  }) async {
    final query = <String, String>{
      'page': '$apiPage',
      'page_size': '$pageSize',
      'ordering': ordering,
    };
    if (categorySlug != null && categorySlug.isNotEmpty) {
      query['category'] = categorySlug;
    }

    try {
      final json = await _api.getJson('/api/v1/products/', query: query);
      return _parseApiPage(json);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return const _ApiPage(items: [], apiHasNext: false);
      }
      rethrow;
    }
  }

  _ApiPage _parseApiPage(Map<String, dynamic> json) {
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
    final apiHasNext = next != null && next.toString().trim().isNotEmpty;

    return _ApiPage(
      items: items,
      totalCount: totalCount,
      apiHasNext: apiHasNext,
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

  static void clearListCache({
    String? categorySlug,
    String? ordering,
  }) {
    if (categorySlug == null && ordering == null) {
      ProductsListCache.clear();
      ProductsPageBuffer.clear();
      return;
    }
    if (ordering != null) {
      ProductsPageBuffer.clearKey(
        ProductsPageBuffer.keyFor(categorySlug: categorySlug, ordering: ordering),
      );
    }
    if (categorySlug == null || categorySlug.isEmpty) {
      ProductsListCache.clear();
    }
  }
}

class _ApiPage {
  const _ApiPage({
    required this.items,
    this.totalCount,
    this.apiHasNext = false,
  });

  final List<ProductSummary> items;
  final int? totalCount;
  final bool apiHasNext;
}

