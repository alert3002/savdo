import 'products_repository.dart';

/// Кэш первой страницы «Новые товары» на главной (без фильтра категории).
class ProductsListCache {
  ProductsListCache._();

  static ProductsPageResult? _homeFirstPage;
  static DateTime? _cachedAt;
  static const Duration ttl = Duration(minutes: 15);

  static bool _isHomeQuery({
    required int page,
    String? categorySlug,
    required String ordering,
  }) {
    return page == 1 &&
        (categorySlug == null || categorySlug.isEmpty) &&
        ordering == '-created_at';
  }

  static ProductsPageResult? get({
    required int page,
    String? categorySlug,
    required String ordering,
  }) {
    if (!_isHomeQuery(page: page, categorySlug: categorySlug, ordering: ordering)) {
      return null;
    }
    final at = _cachedAt;
    if (_homeFirstPage == null || at == null) return null;
    if (DateTime.now().difference(at) > ttl) {
      clear();
      return null;
    }
    return _homeFirstPage;
  }

  static void put({
    required int page,
    String? categorySlug,
    required String ordering,
    required ProductsPageResult result,
  }) {
    if (!_isHomeQuery(page: page, categorySlug: categorySlug, ordering: ordering)) {
      return;
    }
    _homeFirstPage = result;
    _cachedAt = DateTime.now();
  }

  static void clear() {
    _homeFirstPage = null;
    _cachedAt = null;
  }
}
