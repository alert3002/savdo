import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../search/product_search_controller.dart' show apiClientProvider;
import 'product_detail.dart';
import 'product_summary.dart';
import 'products_repository.dart';

class ProductsFilter {
  const ProductsFilter({
    this.categorySlug,
    this.ordering = '-created_at',
  });

  final String? categorySlug;
  final String ordering;

  ProductsFilter copyWith({String? categorySlug, String? ordering}) {
    return ProductsFilter(
      categorySlug: categorySlug,
      ordering: ordering ?? this.ordering,
    );
  }
}

final productsRepositoryProvider = Provider<ProductsRepository>(
  (ref) => ProductsRepository(ref.watch(apiClientProvider)),
);

final productsFilterProvider =
    NotifierProvider<ProductsFilterController, ProductsFilter>(
  ProductsFilterController.new,
);

class ProductsFilterController extends Notifier<ProductsFilter> {
  @override
  ProductsFilter build() => const ProductsFilter();

  void setCategory(String? slug) {
    state = state.copyWith(categorySlug: slug);
  }

  void setOrdering(String ordering) {
    state = state.copyWith(ordering: ordering);
  }

  void reset() {
    state = const ProductsFilter();
  }
}

final productsListProvider = FutureProvider.family<List<ProductSummary>, int>((ref, pageSize) async {
  final repo = ref.watch(productsRepositoryProvider);
  final filter = ref.watch(productsFilterProvider);
  return repo.fetchProducts(
    pageSize: pageSize,
    categorySlug: filter.categorySlug,
    ordering: filter.ordering,
  );
});

final productDetailProvider = FutureProvider.family<ProductDetail, String>((ref, slug) async {
  final repo = ref.watch(productsRepositoryProvider);
  return repo.fetchProductDetail(slug);
});

