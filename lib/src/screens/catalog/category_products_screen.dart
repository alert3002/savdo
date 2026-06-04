import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/products/product_grid_card.dart';
import '../../features/products/product_summary.dart';
import '../../features/products/products_controller.dart';
import '../../ui/error_retry.dart';
import '../../ui/navigation/shop_layer_app_bar.dart';
import '../../ui/skeleton.dart';

/// Маҳсулотҳои як категория — ҷудо аз рӯйхати категорияҳо.
class CategoryProductsScreen extends ConsumerStatefulWidget {
  const CategoryProductsScreen({
    super.key,
    required this.categorySlug,
    this.categoryName,
  });

  final String categorySlug;
  final String? categoryName;

  @override
  ConsumerState<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends ConsumerState<CategoryProductsScreen> {
  static const _pageSize = 20;
  static const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    crossAxisSpacing: 6,
    mainAxisSpacing: 6,
    childAspectRatio: 0.64,
  );

  String _ordering = '-created_at';
  List<ProductSummary> _items = [];
  int _page = 1;
  bool _hasMore = true;
  bool _initialLoading = true;
  bool _loadingMore = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
  }

  @override
  void didUpdateWidget(covariant CategoryProductsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categorySlug != widget.categorySlug) {
      _reload();
    }
  }

  Future<void> _reload() async {
    setState(() {
      _items = [];
      _page = 1;
      _hasMore = true;
      _initialLoading = true;
      _loadingMore = false;
      _error = null;
    });
    await _loadFirstPage();
  }

  Future<void> _loadFirstPage() async {
    try {
      final repo = ref.read(productsRepositoryProvider);
      final result = await repo.fetchProductsPage(
        page: 1,
        pageSize: _pageSize,
        categorySlug: widget.categorySlug,
        ordering: _ordering,
      );
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _page = 1;
        _hasMore = result.hasNext;
        _initialLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initialLoading = false;
        _error = e;
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore || _initialLoading) return;
    setState(() => _loadingMore = true);
    try {
      final repo = ref.read(productsRepositoryProvider);
      final nextPage = _page + 1;
      final result = await repo.fetchProductsPage(
        page: nextPage,
        pageSize: _pageSize,
        categorySlug: widget.categorySlug,
        ordering: _ordering,
      );
      if (!mounted) return;
      setState(() {
        _page = nextPage;
        _items = [..._items, ...result.items];
        _hasMore = result.hasNext;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось загрузить: $e')),
      );
    }
  }

  void _setOrdering(String ordering) {
    if (_ordering == ordering) return;
    setState(() => _ordering = ordering);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final title = widget.categoryName?.trim().isNotEmpty == true
        ? widget.categoryName!.trim()
        : 'Товары';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: shopLayerAppBarActions(context),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.surface,
              scheme.surface.withValues(alpha: 0.96),
            ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Text(
                'Сортировка',
                style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SortChip(
                    label: 'Новые',
                    selected: _ordering == '-created_at',
                    onTap: () => _setOrdering('-created_at'),
                  ),
                  _SortChip(
                    label: 'Цена ↑',
                    selected: _ordering == 'price',
                    onTap: () => _setOrdering('price'),
                  ),
                  _SortChip(
                    label: 'Цена ↓',
                    selected: _ordering == '-price',
                    onTap: () => _setOrdering('-price'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_initialLoading)
                const _ProductsSkeletonGrid()
              else if (_error != null)
                ErrorRetryPanel(
                  message: friendlyErrorMessage(_error!),
                  onRetry: _reload,
                )
              else if (_items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'Нет товаров',
                      style: textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                )
              else ...[
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _items.length,
                  gridDelegate: _gridDelegate,
                  itemBuilder: (context, index) {
                    return ProductGridCard(item: _items[index]);
                  },
                ),
                const SizedBox(height: 14),
                if (_hasMore)
                  Center(
                    child: FilledButton.tonal(
                      onPressed: _loadingMore ? null : _loadMore,
                      child: _loadingMore
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Загрузить ещё'),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: scheme.primary.withValues(alpha: 0.22),
      checkmarkColor: scheme.primary,
    );
  }
}

class _ProductsSkeletonGrid extends StatelessWidget {
  const _ProductsSkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 0.64,
      ),
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonBox(
                width: double.infinity,
                height: 168,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(10, 12, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonText(width: 120, height: 14),
                    SizedBox(height: 8),
                    SkeletonText(width: 80, height: 12),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
