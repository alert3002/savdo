import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../../brand/brand_assets.dart';
import '../../features/categories/categories_controller.dart';
import '../../features/categories/category_item.dart';
import '../../features/products/product_summary.dart';
import '../../features/products/products_controller.dart';
import '../../features/products/product_grid_card.dart';
import '../../features/search/product_search_sheet.dart';
import '../../features/slider/slider_controller.dart';
import '../../routing/app_routes.dart';
import '../../ui/error_retry.dart';
import '../../ui/navigation/shop_layer_app_bar.dart';
import '../../ui/skeleton.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  static const _pageSize = 20;

  bool _isLoading = true;
  Timer? _loadingTimer;
  List<ProductSummary> _items = [];
  int _page = 1;
  bool _hasMore = true;
  bool _productsLoading = true;
  bool _loadingMore = false;
  Object? _productsError;

  @override
  void initState() {
    super.initState();
    _loadingTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
    });
    _loadFirstPage();
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  Future<void> _reloadProducts() async {
    setState(() {
      _items = [];
      _page = 1;
      _hasMore = true;
      _productsLoading = true;
      _loadingMore = false;
      _productsError = null;
    });
    await _loadFirstPage();
  }

  Future<void> _loadFirstPage() async {
    final filter = ref.read(productsFilterProvider);
    try {
      final repo = ref.read(productsRepositoryProvider);
      final result = await repo.fetchProductsPage(
        page: 1,
        pageSize: _pageSize,
        categorySlug: filter.categorySlug,
        ordering: filter.ordering,
      );
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _page = 1;
        _hasMore = result.hasNext;
        _productsLoading = false;
        _productsError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _productsLoading = false;
        _productsError = e;
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore || _productsLoading) return;
    setState(() => _loadingMore = true);
    final filter = ref.read(productsFilterProvider);
    try {
      final repo = ref.read(productsRepositoryProvider);
      final nextPage = _page + 1;
      final result = await repo.fetchProductsPage(
        page: nextPage,
        pageSize: _pageSize,
        categorySlug: filter.categorySlug,
        ordering: filter.ordering,
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

  Future<void> _openFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const _ProductsFilterSheet(),
    );
    if (!mounted) return;
    await _reloadProducts();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(productsFilterProvider, (prev, next) {
      if (prev == null) return;
      if (prev.categorySlug != next.categorySlug || prev.ordering != next.ordering) {
        _reloadProducts();
      }
    });

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
            if (_productsError != null && !_productsLoading)
              ErrorRetryPanel(
                message: friendlyErrorMessage(_productsError!),
                onRetry: _reloadProducts,
              )
            else if (isLoading || _productsLoading)
              const _ShopSkeletonGrid()
            else
              _ProductsGrid(items: _items),
            const SizedBox(height: 14),
            if (!isLoading && !_productsLoading && _productsError == null && _hasMore)
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
            const SizedBox(height: 18),
            const _MotivationBlocks(),
          ],
        ),
      ),
    );
  }
}

class _ProductsGrid extends StatelessWidget {
  const _ProductsGrid({required this.items});
  final List<ProductSummary> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Нет товаров',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 0.58,
      ),
      itemBuilder: (context, index) => ProductGridCard(item: items[index]),
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
        childAspectRatio: 0.68,
      ),
      itemBuilder: (context, index) {
        final c = items[index];
        final imageUrl = c.imageUrl;
        final hasImage = imageUrl != null && imageUrl.isNotEmpty;

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
              color: scheme.surfaceContainerLow,
              border: Border.all(
                color: scheme.outline.withValues(alpha: 0.42),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _HomeCategoryPlaceholder(scheme: scheme),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return ColoredBox(
                          color: scheme.surfaceContainerHigh.withValues(alpha: 0.5),
                        );
                      },
                    )
                  else
                    _HomeCategoryPlaceholder(scheme: scheme),
                  if (hasImage)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 48,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0),
                              Colors.black.withValues(alpha: 0.6),
                            ],
                          ),
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
                          color: hasImage ? Colors.white : scheme.onSurface,
                          height: 1.05,
                          fontSize: 12,
                          shadows: hasImage
                              ? const [
                                  Shadow(blurRadius: 5, color: Colors.black45),
                                ]
                              : null,
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

class _HomeCategoryPlaceholder extends StatelessWidget {
  const _HomeCategoryPlaceholder({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: scheme.surfaceContainerHigh.withValues(alpha: 0.65),
      child: Center(
        child: Icon(
          Icons.category_outlined,
          size: 30,
          color: scheme.primary.withValues(alpha: 0.55),
        ),
      ),
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
        childAspectRatio: 0.68,
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

class _PromoSlider extends ConsumerStatefulWidget {
  const _PromoSlider();

  @override
  ConsumerState<_PromoSlider> createState() => _PromoSliderState();
}

class _PromoSliderState extends ConsumerState<_PromoSlider> {
  final PageController _controller = PageController(viewportFraction: 0.92);
  int _index = 0;
  Timer? _autoTimer;
  int _slideCount = 1;

  static const _fallback = [
    _PromoData(
      title: 'Savdo.tech — покупки, которым доверяют',
      subtitle: 'Профессиональная автохимия и бытовая химия.',
    ),
    _PromoData(
      title: 'Стань партнёром и развивайся',
      subtitle: 'MLM-система, бонусы и рост команды.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAuto();
  }

  void _startAuto() {
    _autoTimer?.cancel();
    if (_slideCount < 2) return;
    _autoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      if (!_controller.hasClients) return;
      final next = (_index + 1) % _slideCount;
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

    final asyncSlides = ref.watch(sliderItemsProvider);

    return asyncSlides.when(
      data: (apiItems) {
        final useApi = apiItems.isNotEmpty;
        final count = useApi ? apiItems.length : _fallback.length;
        if (_slideCount != count) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _slideCount = count);
              _startAuto();
            }
          });
        }
        return _buildSlider(
          context,
          scheme: scheme,
          textTheme: textTheme,
          watermarkLogo: watermarkLogo,
          count: count,
          itemBuilder: (i) {
            if (useApi) {
              final s = apiItems[i];
              return _PromoData(
                title: s.title,
                subtitle: s.description,
                imageUrl: s.imageUrl,
              );
            }
            return _fallback[i];
          },
        );
      },
      loading: () => _buildSlider(
        context,
        scheme: scheme,
        textTheme: textTheme,
        watermarkLogo: watermarkLogo,
        count: _fallback.length,
        itemBuilder: (i) => _fallback[i],
      ),
      error: (Object e, StackTrace st) => _buildSlider(
        context,
        scheme: scheme,
        textTheme: textTheme,
        watermarkLogo: watermarkLogo,
        count: _fallback.length,
        itemBuilder: (i) => _fallback[i],
      ),
    );
  }

  Widget _buildSlider(
    BuildContext context, {
    required ColorScheme scheme,
    required TextTheme textTheme,
    required String watermarkLogo,
    required int count,
    required _PromoData Function(int index) itemBuilder,
  }) {
    return Column(
      children: [
        SizedBox(
          height: 156,
          child: PageView.builder(
            controller: _controller,
            itemCount: count,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, i) {
              final item = itemBuilder(i);
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Material(
                  color: Colors.transparent,
                  elevation: 0,
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.22),
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.80),
                        width: 2.2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        children: [
                          if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                            Positioned.fill(
                              child: Image.network(
                                item.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox.shrink(),
                              ),
                            )
                          else
                            Positioned.fill(
                              child: Opacity(
                                opacity: 0.14,
                                child: Image.asset(
                                  watermarkLogo,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.centerRight,
                                ),
                              ),
                            ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    scheme.surface.withValues(alpha: 0.88),
                                    scheme.surface.withValues(alpha: 0.35),
                                  ],
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
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                if (item.subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    item.subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                      color: scheme.onSurface.withValues(alpha: 0.72),
                                    ),
                                  ),
                                ],
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
          children: List.generate(count, (i) {
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
    this.imageUrl,
  });

  final String title;
  final String subtitle;
  final String? imageUrl;
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
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 0.58,
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
              height: 168,
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

