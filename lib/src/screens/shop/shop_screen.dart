import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../../brand/brand_assets.dart';
import '../../features/categories/categories_controller.dart';
import '../../features/categories/category_item.dart';
import '../../features/products/products_controller.dart';
import '../../features/products/product_grid_card.dart';
import '../../features/search/product_search_sheet.dart';
import '../../routing/app_routes.dart';
import '../../ui/navigation/shop_layer_app_bar.dart';
import '../../ui/skeleton.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  bool _isLoading = true;
  int _visibleCount = 10;
  Timer? _loadingTimer;

  @override
  void initState() {
    super.initState();
    _loadingTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  void _loadMore() {
    setState(() => _visibleCount += 10);
  }

  Future<void> _openFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const _ProductsFilterSheet(),
    );
    if (!mounted) return;
    ref.invalidate(productsListProvider(_visibleCount));
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _isLoading;
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final logo = isDark ? BrandAssets.logoWhiteHorizontal : BrandAssets.logoBlackHorizontal;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: openShopNavigationDrawer,
          icon: const Icon(Icons.menu),
          tooltip: 'Меню',
        ),
        title: Image.asset(
          logo,
          height: 26,
          fit: BoxFit.contain,
        ),
        actions: [
          IconButton(
            onPressed: () => showProductSearchSheet(context),
            icon: const Icon(Icons.search),
            tooltip: 'Поиск',
          ),
          const NotificationsAppBarButton(),
        ],
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            const _PromoSlider(),
            const SizedBox(height: 10),
            const _CategoryGrid(),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Новые товары',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _openFilters,
                  icon: const Icon(Icons.tune),
                  tooltip: 'Фильтры',
                ),
              ],
            ),
            const SizedBox(height: 10),
            isLoading ? const _ShopSkeletonGrid() : _ProductsGrid(pageSize: _visibleCount),
            const SizedBox(height: 14),
            if (!isLoading)
              Center(
                child: FilledButton.tonal(
                  onPressed: _loadMore,
                  child: const Text('Загрузить ещё'),
                ),
              ),
            const SizedBox(height: 18),
            const _MotivationBlocks(),
          ],
        ),
      ),
    );
  }
}

class _ProductsGrid extends ConsumerWidget {
  const _ProductsGrid({required this.pageSize});
  final int pageSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(productsListProvider(pageSize));
    return asyncItems.when(
      data: (items) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          // a bit taller to avoid overflow on small screens
          childAspectRatio: 0.66,
        ),
        itemBuilder: (context, index) => ProductGridCard(item: items[index]),
      ),
      loading: () => const _ShopSkeletonGrid(),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text('Ошибка: $e'),
      ),
    );
  }
}

class _CategoryGrid extends ConsumerWidget {
  const _CategoryGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final asyncCats = ref.watch(topCategoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        asyncCats.when(
          data: (items) => _CategoryGridBody(items: items),
          loading: () => _CategorySkeleton(scheme: scheme),
          error: (e, st) => _CategorySkeleton(scheme: scheme),
        ),
      ],
    );
  }
}

class _CategoryGridBody extends StatelessWidget {
  const _CategoryGridBody({required this.items});
  final List<CategoryItem> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length.clamp(0, 6),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (context, index) {
        final c = items[index];
        final imageUrl = c.imageUrl;

        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            if (c.slug.isEmpty) return;
            context.push(
              AppRoutes.catalogCategoryProducts(c.slug),
              extra: c.name,
            );
          },
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.18),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.22),
                width: 0.8,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const ColoredBox(color: Colors.transparent);
                      },
                    ),
                  // Dark overlay for readability + "wow".
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.05),
                          Colors.black.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        c.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: scheme.onSurface,
                          height: 1.05,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CategorySkeleton extends StatelessWidget {
  const _CategorySkeleton({required this.scheme});
  final ColorScheme scheme;

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
        childAspectRatio: 0.92,
      ),
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: const SkeletonBox(
            width: double.infinity,
            height: double.infinity,
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
        );
      },
    );
  }
}

class _MotivationBlocks extends StatelessWidget {
  const _MotivationBlocks();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Почему Savdo.tech',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        _MotivationCard(
          title: 'Бесплатная доставка',
          subtitle: 'Доставим заказ в пункт выдачи при выполнении условий.',
          icon: Icons.local_shipping_outlined,
          gradient: [
            scheme.primary.withValues(alpha: 0.28),
            scheme.secondary.withValues(alpha: 0.14),
          ],
          actionText: 'Узнать условия',
          onTap: () => context.push(AppRoutes.infoDelivery),
        ),
        const SizedBox(height: 12),
        _MotivationCard(
          title: 'Зарабатывай с MLM',
          subtitle: 'Построй команду, получай бонусы и повышай статус.',
          icon: Icons.account_tree_outlined,
          gradient: [
            scheme.secondary.withValues(alpha: 0.22),
            scheme.primary.withValues(alpha: 0.14),
          ],
          actionText: 'Открыть кабинет',
          onTap: () => context.go(AppRoutes.mlm),
        ),
      ],
    );
  }
}

class _MotivationCard extends StatelessWidget {
  const _MotivationCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.actionText,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final String actionText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.30),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.78),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.tonal(
                        onPressed: onTap,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        child: Text(actionText),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(icon, color: scheme.primary, size: 30),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromoSlider extends StatefulWidget {
  const _PromoSlider();

  @override
  State<_PromoSlider> createState() => _PromoSliderState();
}

class _PromoSliderState extends State<_PromoSlider> {
  final PageController _controller = PageController(viewportFraction: 0.92);
  int _index = 0;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _startAuto();
  }

  void _startAuto() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      if (!_controller.hasClients) return;
      final next = (_index + 1) % 3;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _onPageChanged(int i) {
    setState(() => _index = i);
    _startAuto();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = scheme.brightness == Brightness.dark;
    final watermarkLogo =
        isDark ? BrandAssets.logoWhiteHorizontal : BrandAssets.logoBlackHorizontal;

    final items = const [
      _PromoData(
        title: 'Savdo.tech — покупки, которым доверяют',
        subtitle: 'Профессиональная автохимия и бытовая химия.',
      ),
      _PromoData(
        title: 'Стань партнёром и развивайся',
        subtitle: 'MLM-система, бонусы и рост команды.',
      ),
      _PromoData(
        title: 'Быстрая доставка и удобный заказ',
        subtitle: 'Выбирай товары и оформляй заказы за минуту.',
      ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 156,
          child: PageView.builder(
            controller: _controller,
            itemCount: items.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, i) {
              final item = items[i];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    // Later: open promo/category/link.
                  },
                  child: Material(
                    color: Colors.transparent,
                    elevation: 0,
                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: scheme.surfaceContainerHighest.withValues(alpha: 0.22),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.shadow.withValues(alpha: 0.55),
                            blurRadius: 26,
                            spreadRadius: 2,
                            offset: const Offset(0, 14),
                          ),
                        ],
                        border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.80),
                          width: 2.2,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Subtle inner overlay to separate from page background.
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    scheme.surface.withValues(alpha: 0.08),
                                    scheme.primary.withValues(alpha: 0.14),
                                    scheme.secondary.withValues(alpha: 0.08),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                          // "Image" background (watermark logo) instead of icon.
                          Positioned.fill(
                            child: Opacity(
                              opacity: 0.14,
                              child: Transform.scale(
                                scale: 1.15,
                                child: Image.asset(
                                  watermarkLogo,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.centerRight,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: scheme.onSurface.withValues(alpha: 0.72),
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                FilledButton.tonal(
                                  onPressed: () {},
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                  ),
                                  child: const Text('Купить'),
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
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(items.length, (i) {
            final selected = i == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: selected ? 18 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: selected
                    ? scheme.primary.withValues(alpha: 0.9)
                    : scheme.onSurface.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(100),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _PromoData {
  const _PromoData({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;
}

class _ShopSkeletonGrid extends StatelessWidget {
  const _ShopSkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 8,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) {
        return const _ShopSkeletonCard();
      },
    );
  }
}

class _ShopSkeletonCard extends StatelessWidget {
  const _ShopSkeletonCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(
              width: double.infinity,
              height: 120,
              borderRadius: BorderRadius.zero,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonText(width: 130, height: 14),
                  const SizedBox(height: 6),
                  const SkeletonText(width: 90, height: 12),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      Expanded(child: SkeletonText(width: 90, height: 16)),
                      SizedBox(width: 8),
                      SkeletonBox(
                        width: 32,
                        height: 32,
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductsFilterSheet extends ConsumerWidget {
  const _ProductsFilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final current = ref.watch(productsFilterProvider);
    final filterCtrl = ref.read(productsFilterProvider.notifier);
    final asyncCats = ref.watch(topCategoriesProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Фильтры',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Категория',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 8),
            asyncCats.when(
              data: (cats) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Chip(
                      label: 'Все',
                      selected: current.categorySlug == null,
                      onTap: () => filterCtrl.setCategory(null),
                    ),
                    for (final c in cats)
                      _Chip(
                        label: c.name,
                        selected: current.categorySlug == c.slug,
                        onTap: () => filterCtrl.setCategory(c.slug),
                      ),
                  ],
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, st) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Сортировка',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Chip(
                  label: 'Новые',
                  selected: current.ordering == '-created_at',
                  onTap: () => filterCtrl.setOrdering('-created_at'),
                ),
                _Chip(
                  label: 'Цена ↑',
                  selected: current.ordering == 'price',
                  onTap: () => filterCtrl.setOrdering('price'),
                ),
                _Chip(
                  label: 'Цена ↓',
                  selected: current.ordering == '-price',
                  onTap: () => filterCtrl.setOrdering('-price'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () {
                      filterCtrl.reset();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Сбросить'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(backgroundColor: scheme.primary),
                    child: const Text('Применить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? scheme.primary.withValues(alpha: 0.18) : scheme.surfaceContainerHighest.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? scheme.primary.withValues(alpha: 0.55) : scheme.outlineVariant.withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

