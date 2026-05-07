import '../../api/api_client.dart';
import 'category_item.dart';

class CategoriesRepository {
  CategoriesRepository(this._api);
  final ApiClient _api;

  Future<List<CategoryItem>> fetchTopCategories({int limit = 6}) async {
    final json = await _api.getJson(
      '/api/v1/categories/',
      query: {
        'page_size': '$limit',
        'ordering': 'ordering',
        'top': '1',
      },
    );
    final results = json['results'];
    if (results is List) {
      return results
          .whereType<Map<String, dynamic>>()
          .map(CategoryItem.fromJson)
          .take(limit)
          .toList(growable: false);
    }
    return const [];
  }

  /// Ҳамаи категорияҳои реша (барои саҳифаи «Каталог»).
  Future<List<CategoryItem>> fetchRootCategories({int pageSize = 100}) async {
    final json = await _api.getJson(
      '/api/v1/categories/',
      query: {
        'page_size': '$pageSize',
        'ordering': 'ordering',
        'top': '1',
      },
    );
    final results = json['results'];
    if (results is List) {
      return results
          .whereType<Map<String, dynamic>>()
          .map(CategoryItem.fromJson)
          .toList(growable: false);
    }
    return const [];
  }
}

