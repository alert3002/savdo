import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/catalog/catalog_providers.dart';
import '../../features/categories/category_item.dart';
import '../../routing/app_routes.dart';
import '../../ui/navigation/shop_layer_app_bar.dart';
import '../../ui/skeleton.dart';

/// Ҳошияи равшан барои категорияҳо (дар торик/равшан хонанда мемонад).
BorderSide _categoryBorderSide(ColorScheme scheme) => BorderSide(
      color: scheme.outline.withValues(alpha: 0.42),
      width: 1,
    );

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Каталог'),
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
            ref.invalidate(catalogRootCategoriesProvider);
            await ref.read(catalogRootCategoriesProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Text(
                'Категории',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              ref.watch(catalogRootCategoriesProvider).when(
                    data: (cats) {
                      if (cats.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'Нет категорий',
                              style: textTheme.bodyLarge?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        );
                      }
                      return _CategorySection(
                        categories: cats,
                        onOpenCategory: (c) {
                          context.push(
                            AppRoutes.catalogCategoryProducts(c.slug),
                            extra: c.name,
                          );
                        },
                      );
                    },
                    loading: () => const _CategorySkeletonGrid(),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('Категории: $e'),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.categories,
    required this.onOpenCategory,
  });

  final List<CategoryItem> categories;
  final void Function(CategoryItem c) onOpenCategory;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.68,
      ),
      itemBuilder: (context, index) {
        final c = categories[index];
        return _CategoryTile(
          name: c.name,
          imageUrl: c.imageUrl,
          productCount: c.productCount,
          scheme: scheme,
          textTheme: textTheme,
          onTap: () => onOpenCategory(c),
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.name,
    required this.imageUrl,
    required this.productCount,
    required this.scheme,
    required this.textTheme,
    required this.onTap,
  });

  final String name;
  final String? imageUrl;
  final int productCount;
  final ColorScheme scheme;
  final TextTheme textTheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.fromBorderSide(_categoryBorderSide(scheme)),
            color: scheme.surfaceContainerLow,
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageUrl != null && imageUrl!.isNotEmpty)
                  Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _CategoryPlaceholder(scheme: scheme),
                  )
                else
                  _CategoryPlaceholder(scheme: scheme),
                if (imageUrl != null && imageUrl!.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0),
                            Colors.black.withValues(alpha: 0.62),
                          ],
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: (imageUrl != null && imageUrl!.isNotEmpty)
                              ? Colors.white
                              : scheme.onSurface,
                          height: 1.05,
                          fontSize: 12,
                          shadows: (imageUrl != null && imageUrl!.isNotEmpty)
                              ? const [
                                  Shadow(blurRadius: 6, color: Colors.black54),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$productCount шт',
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: (imageUrl != null && imageUrl!.isNotEmpty)
                              ? Colors.white.withValues(alpha: 0.92)
                              : scheme.onSurface.withValues(alpha: 0.65),
                          fontSize: 11,
                          shadows: (imageUrl != null && imageUrl!.isNotEmpty)
                              ? const [
                                  Shadow(blurRadius: 4, color: Colors.black54),
                                ]
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryPlaceholder extends StatelessWidget {
  const _CategoryPlaceholder({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: scheme.surfaceContainerHigh.withValues(alpha: 0.65),
      child: Center(
        child: Icon(
          Icons.category_outlined,
          size: 34,
          color: scheme.primary.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

class _CategorySkeletonGrid extends StatelessWidget {
  const _CategorySkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.68,
      ),
      itemBuilder: (context, index) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.fromBorderSide(
            BorderSide(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.42),
              width: 1,
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.5),
          child: const SkeletonBox(
            width: double.infinity,
            height: double.infinity,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
    );
  }
}
