import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/products/product_engagement_controller.dart';
import '../../features/products/products_controller.dart';
import '../../routing/app_routes.dart';
import '../../theme/grass_colors.dart';
import '../../ui/grass_cached_network_image.dart';
import '../../ui/navigation/shop_layer_app_bar.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncFav = ref.watch(favoriteProductSlugsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Избранное'),
        actions: shopLayerAppBarActions(context),
      ),
      body: asyncFav.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (slugs) {
          if (slugs.isEmpty) {
            return Center(
              child: Text(
                'Пока нет избранных товаров.\nОткройте карточку товара и нажмите на сердце.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
              ),
            );
          }
          final list = slugs.toList();
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final slug = list[i];
              return _FavoriteProductTile(slug: slug);
            },
          );
        },
      ),
    );
  }
}

class _FavoriteProductTile extends ConsumerWidget {
  const _FavoriteProductTile({required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final asyncDetail = ref.watch(productDetailProvider(slug));

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push(AppRoutes.productBySlug(slug)),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.25),
        ),
        child: asyncDetail.when(
          loading: () => const SizedBox(
            height: 92,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (e, _) => ListTile(
            leading: const Icon(Icons.broken_image_outlined),
            title: Text(slug, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: const Text('Ошибка загрузки'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => ref.read(favoriteProductSlugsProvider.notifier).toggle(slug),
            ),
          ),
          data: (p) => ListTile(
            contentPadding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ColoredBox(
                color: GrassColors.productImageBackground,
                child: SizedBox(
                  width: 62,
                  height: 62,
                  child: (p.primaryImage != null && p.primaryImage!.isNotEmpty)
                      ? GrassCachedNetworkImage(
                          url: p.primaryImage!,
                          width: 62,
                          height: 62,
                          fit: BoxFit.contain,
                          maxCacheSide: 200,
                          errorWidget: Icon(
                            Icons.image_not_supported_outlined,
                            color: scheme.primary,
                          ),
                        )
                      : Icon(Icons.local_car_wash_outlined, color: scheme.primary),
                ),
              ),
            ),
            title: Text(
              p.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              [p.categoryName, p.brandName].whereType<String>().where((e) => e.isNotEmpty).join(' • '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${p.effectivePrice} ${p.currency}',
                  style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                IconButton(
                  icon: const Icon(Icons.favorite),
                  color: scheme.error,
                  tooltip: 'Удалить из избранного',
                  onPressed: () => ref.read(favoriteProductSlugsProvider.notifier).toggle(slug),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
