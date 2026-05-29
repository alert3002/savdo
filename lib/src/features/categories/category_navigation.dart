import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../routing/app_routes.dart';
import 'categories_controller.dart';
import 'category_item.dart';

/// Агар зеркатегория бошад → рӯйхат; агар не → маҳсулот.
Future<void> navigateToCategory(
  BuildContext context,
  WidgetRef ref,
  CategoryItem category,
) async {
  if (category.slug.isEmpty) return;

  final repo = ref.read(categoriesRepositoryProvider);
  final children = await repo.fetchChildCategories(parentSlug: category.slug);
  if (!context.mounted) return;

  if (children.isNotEmpty) {
    context.push(
      AppRoutes.catalogCategoryChildren(category.slug),
      extra: category.name,
    );
    return;
  }

  context.push(
    AppRoutes.catalogCategoryProducts(category.slug),
    extra: category.name,
  );
}
