import '../../api/api_client.dart';
import 'category_item.dart';

class CategoriesRepository {
  CategoriesRepository(this._api);
  final ApiClient _api;

  static const _rootQuery = <String, String>{
    'ordering': 'ordering',
    'top': '1',
  };

  List<CategoryItem> _parseRootCategories(Object? results) {
    if (results is! List) return const [];
    return results
        .whereType<Map<String, dynamic>>()
        .map(CategoryItem.fromJson)
        .where((c) => c.isRoot)
        .toList(growable: false);
  }

  Future<List<CategoryItem>> fetchTopCategories({int limit = 6}) async {
    final json = await _api.getJson(
      '/api/v1/categories/',
      query: {
        ..._rootQuery,
        'page_size': '${limit * 3}',
      },
    );
    return _parseRootCategories(json['results']).take(limit).toList(growable: false);
  }

  /// Танҳо категорияҳои реша (родительские), бе подкатегорий.
  Future<List<CategoryItem>> fetchRootCategories({int pageSize = 200}) async {
    final json = await _api.getJson(
      '/api/v1/categories/',
      query: {
        ..._rootQuery,
        'page_size': '$pageSize',
      },
    );
    return _parseRootCategories(json['results']);
  }
}

