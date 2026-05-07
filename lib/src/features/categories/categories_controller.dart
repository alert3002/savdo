import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../search/product_search_controller.dart' show apiClientProvider;
import 'categories_repository.dart';
import 'category_item.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>(
  (ref) => CategoriesRepository(ref.watch(apiClientProvider)),
);

final topCategoriesProvider = FutureProvider<List<CategoryItem>>((ref) async {
  final repo = ref.watch(categoriesRepositoryProvider);
  return repo.fetchTopCategories(limit: 6);
});

