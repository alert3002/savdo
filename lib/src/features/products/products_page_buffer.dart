import 'product_summary.dart';

/// Буфер для клиентской пагинации, когда API отдаёт больше товаров, чем `page_size`.
class ProductsPageBuffer {
  ProductsPageBuffer._();

  static final Map<String, ProductsPageBufferEntry> _entries = {};

  static String keyFor({String? categorySlug, required String ordering}) {
    return '${categorySlug ?? ''}|$ordering';
  }

  static ProductsPageBufferEntry? entry(String key) => _entries[key];

  static void setFirstPage(
    String key, {
    required List<ProductSummary> items,
    int? totalCount,
    required bool apiHasNext,
    required int apiPage,
  }) {
    _entries[key] = ProductsPageBufferEntry(
      items: List<ProductSummary>.from(items),
      totalCount: totalCount,
      apiHasNext: apiHasNext,
      lastApiPage: apiPage,
    );
  }

  static void append(
    String key,
    List<ProductSummary> items, {
    required int apiPage,
    required bool apiHasNext,
    int? totalCount,
  }) {
    final entry = _entries[key];
    if (entry == null) return;
    entry.items.addAll(items);
    entry.lastApiPage = apiPage;
    entry.apiHasNext = apiHasNext;
    if (totalCount != null) entry.totalCount = totalCount;
  }

  static void markApiExhausted(String key) {
    final entry = _entries[key];
    if (entry == null) return;
    entry.apiHasNext = false;
  }

  static void clearKey(String key) => _entries.remove(key);

  static void clear() => _entries.clear();
}

class ProductsPageBufferEntry {
  ProductsPageBufferEntry({
    required this.items,
    required this.totalCount,
    required this.apiHasNext,
    required this.lastApiPage,
  });

  final List<ProductSummary> items;
  int? totalCount;
  bool apiHasNext;
  int lastApiPage;
}
