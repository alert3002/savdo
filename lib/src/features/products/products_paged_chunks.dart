import 'product_summary.dart';
import 'products_repository.dart';

/// Помощник: ҳар клик танҳо 20 товар илова мекунад, на ҳамаи рӯйхат.
class ProductsPagedChunks {
  ProductsPagedChunks({required this.pageSize});

  final int pageSize;
  final List<List<ProductSummary>> chunks = [];

  int get loadedCount =>
      chunks.fold<int>(0, (sum, chunk) => sum + chunk.length);

  bool get isEmpty => chunks.isEmpty;

  void reset() => chunks.clear();

  /// Танҳо ҳадди `pageSize` товар аз ҷавоби API мегирад.
  List<ProductSummary> absorbPage(ProductsPageResult result) {
    final batch = result.items.take(pageSize).toList(growable: false);
    if (batch.isEmpty) return batch;
    chunks.add(batch);
    return batch;
  }

  void setFirstPage(ProductsPageResult result) {
    reset();
    absorbPage(result);
  }

  bool hasMore({int? totalCount, required bool apiHasNext}) {
    if (totalCount != null && totalCount > 0) {
      return loadedCount < totalCount;
    }
    if (chunks.isEmpty) return apiHasNext;
    return apiHasNext && chunks.last.length >= pageSize;
  }
}
