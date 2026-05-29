import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/catalog/catalog_providers.dart';
import '../../features/categories/category_children_list.dart';
import '../../features/categories/category_navigation.dart';
import '../../ui/navigation/shop_layer_app_bar.dart';

/// Зеркатегорияҳои як категория — рӯйхат (list).
class CategoryChildrenScreen extends ConsumerWidget {
  const CategoryChildrenScreen({
    super.key,
    required this.parentSlug,
    this.parentName,
  });

  final String parentSlug;
  final String? parentName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final title = parentName?.trim().isNotEmpty == true ? parentName!.trim() : 'Подкатегории';

    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
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
        child: ref.watch(categoryChildrenProvider(parentSlug)).when(
              data: (cats) {
                if (cats.isEmpty) {
                  return Center(
                    child: Text(
                      'Нет подкатегорий',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(categoryChildrenProvider(parentSlug));
                    await ref.read(categoryChildrenProvider(parentSlug).future);
                  },
                  child: CategoryChildrenList(
                    categories: cats,
                    onOpenCategory: (c) => navigateToCategory(context, ref, c),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Подкатегории: $e'),
                ),
              ),
            ),
      ),
    );
  }
}
