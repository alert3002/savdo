import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/products/product_detail.dart';
import '../../features/products/product_engagement_controller.dart';
import '../../features/products/products_controller.dart';
import '../../routing/app_routes.dart';
import '../../ui/navigation/shop_layer_app_bar.dart';

class CompareScreen extends ConsumerWidget {
  const CompareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCmp = ref.watch(compareProductSlugsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Сравнение'),
        actions: [
          ...shopLayerAppBarActions(context),
          IconButton(
            tooltip: 'Очистить',
            onPressed: () async {
              final slugs = ref.read(compareProductSlugsProvider).maybeWhen(
                    data: (s) => s,
                    orElse: () => const <String>[],
                  );
              if (slugs.isEmpty) return;

              final ok = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Очистить сравнение?'),
                    content: const Text('Все товары будут удалены из списка сравнения.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Отмена'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Очистить'),
                      ),
                    ],
                  );
                },
              );
              if (ok != true) return;

              final ctrl = ref.read(compareProductSlugsProvider.notifier);
              for (final slug in slugs) {
                await ctrl.toggle(slug);
              }
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Сравнение очищено')),
              );
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: asyncCmp.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (slugs) {
          if (slugs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Icon(
                        Icons.compare_arrows,
                        color: scheme.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Список сравнения пуст',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Добавьте до $kCompareMaxItems товаров из карточки товара —\nи сравнивайте позже.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.72),
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }
          final detailsAsync = ref.watch(_compareDetailsProvider(slugs));
          return detailsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Ошибка: $e')),
            data: (products) {
              if (products.isEmpty) {
                return const Center(child: Text('Не удалось загрузить товары для сравнения.'));
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.28)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.compare_arrows, color: scheme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${products.length} / $kCompareMaxItems • Скролл вправо — сравнить.\nСвайп влево по колонке — удалить.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurface.withValues(alpha: 0.72),
                                  height: 1.25,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _CompareTable(
                    products: products,
                    onOpen: (slug) => context.push(AppRoutes.productBySlug(slug)),
                    onRemove: (slug) => ref.read(compareProductSlugsProvider.notifier).toggle(slug),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

final _compareDetailsProvider = FutureProvider.family<List<ProductDetail>, List<String>>((ref, slugs) async {
  final repo = ref.read(productsRepositoryProvider);
  final out = <ProductDetail>[];
  for (final slug in slugs) {
    final s = slug.trim();
    if (s.isEmpty) continue;
    try {
      final d = await repo.fetchProductDetail(s);
      out.add(d);
    } catch (_) {
      // If one product fails, still show others.
    }
  }
  return out;
});

class _CompareTable extends StatelessWidget {
  const _CompareTable({
    required this.products,
    required this.onOpen,
    required this.onRemove,
  });

  final List<ProductDetail> products;
  final void Function(String slug) onOpen;
  final void Function(String slug) onRemove;

  static const double _labelColW = 118;
  static const double _productColW = 230;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(18);

    TableRow rowLabelAndCells(String label, List<Widget> cells) {
      return TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (final c in cells)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
              child: c,
            ),
        ],
      );
    }

    Widget headerCell(ProductDetail p) {
      final variantCount = p.variants.length;
      final showVariants = p.hasVariants || variantCount > 0;
      return Dismissible(
        key: ValueKey('cmp_col:${p.slug}'),
        direction: DismissDirection.up,
        background: const SizedBox.shrink(),
        secondaryBackground: const SizedBox.shrink(),
        onDismissed: (_) => onRemove(p.slug),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InkWell(
                onTap: () => onOpen(p.slug),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name.isEmpty ? p.slug : p.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      if (showVariants) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.28)),
                          ),
                          child: Text(
                            variantCount > 0 ? 'Варианты: $variantCount' : 'Есть варианты',
                            style: textTheme.labelSmall?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Удалить',
              onPressed: () => onRemove(p.slug),
              icon: const Icon(Icons.remove_circle_outline),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      );
    }

    Widget imageCell(ProductDetail p) {
      final url = (p.primaryImage ?? (p.images.isNotEmpty ? p.images.first : null))?.trim();
      if (url == null || url.isEmpty) {
        return Container(
          height: 120,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.30)),
          ),
          child: Center(
            child: Icon(Icons.image_not_supported_outlined, color: scheme.onSurface.withValues(alpha: 0.45)),
          ),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 1.35,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.25),
              alignment: Alignment.center,
              child: Icon(Icons.broken_image_outlined, color: scheme.onSurface.withValues(alpha: 0.45)),
            ),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.22),
                alignment: Alignment.center,
                child: const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              );
            },
          ),
        ),
      );
    }

    String priceText(ProductDetail p) {
      final cur = p.currency.isEmpty ? '' : ' ${p.currency}';
      final eff = p.effectivePrice.trim();
      if (eff.isNotEmpty) return '$eff$cur';
      final pr = p.price.trim();
      if (pr.isNotEmpty) return '$pr$cur';
      return '—';
    }

    String categoryText(ProductDetail p) {
      final c = (p.categoryName ?? '').trim();
      return c.isEmpty ? '—' : c;
    }

    String descText(ProductDetail p) {
      final d = p.description.trim();
      if (d.isEmpty) return '—';
      return d.replaceAll(RegExp(r'\s+'), ' ');
    }

    final rows = <TableRow>[
      rowLabelAndCells('Товар', products.map(headerCell).toList(growable: false)),
      rowLabelAndCells('Фото', products.map(imageCell).toList(growable: false)),
      rowLabelAndCells(
        'Цена',
        products
            .map((p) => Text(priceText(p), style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900)))
            .toList(growable: false),
      ),
      rowLabelAndCells(
        'Категория',
        products
            .map((p) => Text(categoryText(p), maxLines: 2, overflow: TextOverflow.ellipsis))
            .toList(growable: false),
      ),
      rowLabelAndCells(
        'Описание',
        products
            .map(
              (p) => Text(
                descText(p),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(height: 1.25),
              ),
            )
            .toList(growable: false),
      ),
    ];

    final totalWidth = _labelColW + (products.length * _productColW);

    return ClipRRect(
      borderRadius: radius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.18),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.30)),
        ),
        child: _HorizontalCompareScroll(
          totalWidth: totalWidth,
          labelColW: _labelColW,
          productColW: _productColW,
          productsCount: products.length,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: totalWidth),
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.top,
              columnWidths: <int, TableColumnWidth>{
                0: const FixedColumnWidth(_labelColW),
                for (var i = 0; i < products.length; i++) i + 1: const FixedColumnWidth(_productColW),
              },
              border: TableBorder(
                horizontalInside: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.22)),
                verticalInside: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.22)),
              ),
              children: rows,
            ),
          ),
        ),
      ),
    );
  }
}

class _HorizontalCompareScroll extends StatefulWidget {
  const _HorizontalCompareScroll({
    required this.totalWidth,
    required this.labelColW,
    required this.productColW,
    required this.productsCount,
    required this.child,
  });

  final double totalWidth;
  final double labelColW;
  final double productColW;
  final int productsCount;
  final Widget child;

  @override
  State<_HorizontalCompareScroll> createState() => _HorizontalCompareScrollState();
}

class _HorizontalCompareScrollState extends State<_HorizontalCompareScroll> {
  late final ScrollController _ctrl;
  bool _canScrollRight = false;
  bool _canScrollLeft = false;

  @override
  void initState() {
    super.initState();
    _ctrl = ScrollController();
    _ctrl.addListener(_recalc);
    WidgetsBinding.instance.addPostFrameCallback((_) => _recalc());
  }

  @override
  void dispose() {
    _ctrl.removeListener(_recalc);
    _ctrl.dispose();
    super.dispose();
  }

  void _recalc() {
    if (!mounted || !_ctrl.hasClients) return;
    final max = _ctrl.position.maxScrollExtent;
    final off = _ctrl.offset;
    final left = off > 2;
    final right = off < (max - 2);
    if (left != _canScrollLeft || right != _canScrollRight) {
      setState(() {
        _canScrollLeft = left;
        _canScrollRight = right;
      });
    }
  }

  Future<void> _scrollBy(double dx) async {
    if (!_ctrl.hasClients) return;
    final current = _ctrl.offset;
    final target = (current + dx).clamp(0.0, _ctrl.position.maxScrollExtent);
    await _ctrl.animateTo(
      target,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Scrollbar(
          controller: _ctrl,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _ctrl,
            scrollDirection: Axis.horizontal,
            child: Padding(
              // reserve space for bottom controls so content isn't covered
              padding: const EdgeInsets.only(bottom: 54),
              child: widget.child,
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 10,
          child: IgnorePointer(
            ignoring: !(_canScrollLeft || _canScrollRight),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: _canScrollLeft ? 1 : 0,
                  child: IconButton.filledTonal(
                    tooltip: 'Влево',
                    onPressed: _canScrollLeft ? () => _scrollBy(-widget.productColW) : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    'Скролл',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.82),
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: _canScrollRight ? 1 : 0,
                  child: IconButton.filledTonal(
                    tooltip: 'Вправо',
                    onPressed: _canScrollRight ? () => _scrollBy(widget.productColW) : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
