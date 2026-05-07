import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/catalog/catalog_providers.dart';
import '../../features/products/product_grid_card.dart';
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
  int _pageSize = 20;
  String _ordering = '-created_at';

  CategoryProductsQuery get _query => (
        slug: widget.categorySlug,
        pageSize: _pageSize,
        ordering: _ordering,
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final title = widget.categoryName?.trim().isNotEmpty == true
        ? widget.categoryName!.trim()
        : 'Товары';

    final asyncItems = ref.watch(categoryProductsProvider(_query));

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
          onRefresh: () async {
            ref.invalidate(categoryProductsProvider(_query));
            await ref.read(categoryProductsProvider(_query).future);
          },
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
                    onTap: () => setState(() {
                      _ordering = '-created_at';
                      _pageSize = 20;
                    }),
                  ),
                  _SortChip(
                    label: 'Цена ↑',
                    selected: _ordering == 'price',
                    onTap: () => setState(() {
                      _ordering = 'price';
                      _pageSize = 20;
                    }),
                  ),
                  _SortChip(
                    label: 'Цена ↓',
                    selected: _ordering == '-price',
                    onTap: () => setState(() {
                      _ordering = '-price';
                      _pageSize = 20;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              asyncItems.when(
                data: (items) {
                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'Нет товаров',
                          style: textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.66,
                        ),
                        itemBuilder: (context, index) {
                          return ProductGridCard(item: items[index]);
                        },
                      ),
                      const SizedBox(height: 14),
                      if (items.length >= _pageSize)
                        Center(
                          child: FilledButton.tonal(
                            onPressed: () => setState(() => _pageSize += 20),
                            child: const Text('Загрузить ещё'),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const _ProductsSkeletonGrid(),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('Ошибка: $e'),
                ),
              ),
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
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.66,
      ),
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonBox(
                width: double.infinity,
                height: 128,
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
