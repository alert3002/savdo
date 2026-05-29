import '../../api/api_client.dart';
import 'category_item.dart';

class CategoriesRepository {
  CategoriesRepository(this._api);
  final ApiClient _api;

  static const _orderingQuery = <String, String>{'ordering': 'ordering'};

  List<CategoryItem> _parseCategories(
    Object? results, {
    bool rootsOnly = false,
  }) {
    if (results is! List) return const [];
    return results
        .whereType<Map<String, dynamic>>()
        .map(CategoryItem.fromJson)
        .where((c) => c.isActive)
        .where((c) => !rootsOnly || c.isRoot)
        .toList(growable: false);
  }

  Future<List<CategoryItem>> fetchTopCategories({int limit = 6}) async {
    final json = await _api.getJson(
      '/api/v1/categories/',
      query: {
        ..._orderingQuery,
        'top': '1',
        'page_size': '${limit * 3}',
      },
    );
    return _parseCategories(json['results'], rootsOnly: true).take(limit).toList(growable: false);
  }

  /// Танҳо категорияҳои реша (родительские).
  Future<List<CategoryItem>> fetchRootCategories({int pageSize = 200}) async {
    final json = await _api.getJson(
      '/api/v1/categories/',
      query: {
        ..._orderingQuery,
        'top': '1',
        'page_size': '$pageSize',
      },
    );
    return _parseCategories(json['results'], rootsOnly: true);
  }

  /// Зеркатегорияҳои як категория (танҳо аз ҳамон волидай).
  Future<List<CategoryItem>> fetchChildCategories({
    required String parentSlug,
    int pageSize = 200,
  }) async {
    final slug = parentSlug.trim();
    if (slug.isEmpty) return const [];

    // Аз detail — subcategories танҳо фарзандони ҳамин категория.
    final detail = await _api.getJson('/api/v1/categories/$slug/');
    final subs = detail['subcategories'];
    if (subs is List) {
      final fromDetail = subs
          .whereType<Map<String, dynamic>>()
          .map(CategoryItem.fromJson)
          .where((c) => c.isActive)
          .toList(growable: false);
      if (fromDetail.isNotEmpty) return fromDetail;
    }

    // Fallback: list + фильтр бо parent slug/id.
    final parentId = (detail['id'] ?? '').toString();
    final json = await _api.getJson(
      '/api/v1/categories/',
      query: {
        ..._orderingQuery,
        'parent': slug,
        'page_size': '$pageSize',
      },
    );
    final results = _parseCategories(json['results']);
    if (parentId.isEmpty) return results;
    return results.where((c) => c.parentId == parentId).toList(growable: false);
  }
}
