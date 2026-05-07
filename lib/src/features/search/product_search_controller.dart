import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../products/product_summary.dart';
import 'product_search_repository.dart';

sealed class ProductSearchState {
  const ProductSearchState({required this.query});
  final String query;
}

class ProductSearchIdle extends ProductSearchState {
  const ProductSearchIdle({required super.query});
}

class ProductSearchLoading extends ProductSearchState {
  const ProductSearchLoading({required super.query});
}

class ProductSearchData extends ProductSearchState {
  const ProductSearchData({required super.query, required this.items});
  final List<ProductSummary> items;
}

class ProductSearchError extends ProductSearchState {
  const ProductSearchError({required super.query, required this.message});
  final String message;
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final productSearchRepositoryProvider = Provider<ProductSearchRepository>(
  (ref) => ProductSearchRepository(ref.watch(apiClientProvider)),
);

final productSearchControllerProvider =
    NotifierProvider<ProductSearchController, ProductSearchState>(
  ProductSearchController.new,
);

class ProductSearchController extends Notifier<ProductSearchState> {
  Timer? _debounce;

  @override
  ProductSearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const ProductSearchIdle(query: '');
  }

  void setQuery(String value) {
    final q = value.trim();
    if (q == state.query) return;

    _debounce?.cancel();

    if (q.length < 3) {
      state = ProductSearchIdle(query: q);
      return;
    }

    state = ProductSearchLoading(query: q);
    _debounce = Timer(const Duration(milliseconds: 320), () async {
      try {
        final repo = ref.read(productSearchRepositoryProvider);
        final items = await repo.searchProducts(q);
        if (state.query != q) return;
        state = ProductSearchData(query: q, items: items);
      } catch (e) {
        if (state.query != q) return;
        state = ProductSearchError(query: q, message: e.toString());
      }
    });
  }
}

