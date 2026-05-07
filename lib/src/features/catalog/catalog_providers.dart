import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../categories/categories_controller.dart' show categoriesRepositoryProvider;
import '../categories/category_item.dart';
import '../products/product_summary.dart';
import '../products/products_controller.dart' show productsRepositoryProvider;

/// Категорияҳои реша — танҳо барои саҳифаи «Каталог».
final catalogRootCategoriesProvider = FutureProvider<List<CategoryItem>>((ref) async {
  final repo = ref.watch(categoriesRepositoryProvider);
  return repo.fetchRootCategories();
});

/// Маҳсулот дар як категория (саҳифаи алоҳида).
typedef CategoryProductsQuery = ({
  String slug,
  int pageSize,
  String ordering,
});

final categoryProductsProvider =
    FutureProvider.family<List<ProductSummary>, CategoryProductsQuery>((ref, q) async {
  final repo = ref.watch(productsRepositoryProvider);
  return repo.fetchProducts(
    pageSize: q.pageSize,
    categorySlug: q.slug,
    ordering: q.ordering,
  );
});
