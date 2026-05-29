import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/catalog/catalog_providers.dart';
import '../../features/categories/category_grid_section.dart';
import '../../features/categories/category_navigation.dart';
import '../../ui/navigation/shop_layer_app_bar.dart';

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
                      return CategoryGridSection(
                        categories: cats,
                        onOpenCategory: (c) => navigateToCategory(context, ref, c),
                      );
                    },
                    loading: () => const CategoryGridSkeleton(),
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
