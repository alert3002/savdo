import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/error_retry.dart';
import '../../ui/navigation/shop_layer_app_bar.dart';
import '../../features/cart/cart_controller.dart';
import '../../features/products/product_detail.dart';
import '../../features/products/product_engagement_controller.dart';
import '../../features/products/products_controller.dart';
import '../../features/products/variant_formatting.dart';
import '../../theme/grass_colors.dart';
import '../../ui/grass_cached_network_image.dart';
import '../../utils/text_utils.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.slug});
  final String slug;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _qty = 1;
  String? _selectedVariantId;

  @override
  void didUpdateWidget(covariant ProductDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slug != widget.slug) {
      _selectedVariantId = null;
      _qty = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncDetail = ref.watch(productDetailProvider(widget.slug));

    ref.listen<AsyncValue<ProductDetail>>(productDetailProvider(widget.slug), (prev, next) {
      next.whenData((p) {
        if (!p.hasVariants || p.variants.isEmpty) return;
        if (p.variants.length == 1 && _selectedVariantId == null && mounted) {
          setState(() => _selectedVariantId = p.variants.first.id);
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Товар'),
        actions: shopLayerAppBarActions(context),
      ),
      body: asyncDetail.when(
        data: (p) {
          final needsVariant = p.hasVariants && p.variants.isNotEmpty;
          final canAdd = !needsVariant || _selectedVariantId != null;

          return _Body(
            p: p,
            qty: _qty,
            onQtyChanged: (v) => setState(() => _qty = v.clamp(1, 999)),
            selectedVariantId: _selectedVariantId,
            onVariantSelected: (id) => setState(() => _selectedVariantId = id),
            canAddToCart: canAdd,
            onAddToCart: () {
              if (!canAdd) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Выберите вариант')),
                );
                return;
              }
              final variant = _selectedVariantId == null
                  ? null
                  : _findVariant(p, _selectedVariantId!);
              final unitPrice = variant?.effectivePrice ?? p.effectivePrice;
              ref.read(cartControllerProvider.notifier).addProduct(
                    p,
                    qty: _qty,
                    variantSku: variant?.sku,
                    variantId: variant?.id,
                    variantLabel: formatCartVariantSubtitle(variant, p.currency),
                    unitPrice: unitPrice,
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Добавлено в корзину')),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
              child: ErrorRetryPanel(
                message: friendlyErrorMessage(e),
                onRetry: () => ref.invalidate(productDetailProvider(widget.slug)),
              ),
            ),
      ),
    );
  }
}

ProductVariantInline? _findVariant(ProductDetail p, String id) {
  for (final v in p.variants) {
    if (v.id == id) return v;
  }
  return null;
}

/// Избранное + сравнение рӯи акси маҳсулот.
class _ProductEngagementActions extends ConsumerWidget {
  const _ProductEngagementActions({required this.productSlug});
  final String productSlug;

  static Widget _circleButton({
    required Widget child,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.48),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: child,
        color: Colors.white,
        style: IconButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final slug = productSlug;
    if (slug.isEmpty) return const SizedBox.shrink();

    final fav = ref.watch(favoriteProductSlugsProvider);
    final cmp = ref.watch(compareProductSlugsProvider);
    final isFav = fav.maybeWhen(data: (s) => s.contains(slug), orElse: () => false);
    final inCompare = cmp.maybeWhen(data: (s) => s.contains(slug), orElse: () => false);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _circleButton(
          tooltip: 'Избранное',
          onPressed: () async {
            await ref.read(favoriteProductSlugsProvider.notifier).toggle(slug);
            if (!context.mounted) return;
            final nowFav = ref
                .read(favoriteProductSlugsProvider)
                .maybeWhen(data: (s) => s.contains(slug), orElse: () => false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(nowFav ? 'Добавлено в избранное' : 'Удалено из избранного'),
              ),
            );
          },
          child: Icon(
            isFav ? Icons.favorite : Icons.favorite_border,
            color: isFav ? scheme.error : Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        _circleButton(
          tooltip: 'Сравнение',
          onPressed: () async {
            final wasIn = ref
                .read(compareProductSlugsProvider)
                .maybeWhen(data: (s) => s.contains(slug), orElse: () => false);
            final changed = await ref.read(compareProductSlugsProvider.notifier).toggle(slug);
            if (!context.mounted) return;
            final nowIn = ref
                .read(compareProductSlugsProvider)
                .maybeWhen(data: (s) => s.contains(slug), orElse: () => false);
            if (!changed && !wasIn) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('В сравнении не более $kCompareMaxItems товаров'),
                ),
              );
            } else if (changed) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(nowIn ? 'Добавлено к сравнению' : 'Убрано из сравнения'),
                ),
              );
            }
          },
          child: Icon(
            Icons.compare_arrows,
            color: inCompare ? scheme.primary : Colors.white,
          ),
        ),
      ],
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.p,
    required this.qty,
    required this.onQtyChanged,
    required this.selectedVariantId,
    required this.onVariantSelected,
    required this.canAddToCart,
    required this.onAddToCart,
  });

  final ProductDetail p;
  final int qty;
  final ValueChanged<int> onQtyChanged;
  final String? selectedVariantId;
  final ValueChanged<String> onVariantSelected;
  final bool canAddToCart;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final images = <String>{
      if (p.primaryImage != null && p.primaryImage!.isNotEmpty) p.primaryImage!,
      ...p.images.where((e) => e.isNotEmpty),
    }.toList(growable: false);

    final selectedVariant =
        selectedVariantId == null ? null : _findVariant(p, selectedVariantId!);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ProductImageGallery(
          images: images,
          productSlug: p.slug,
        ),
        const SizedBox(height: 14),
        Text(
          p.name,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          [p.categoryName, p.brandName].whereType<String>().where((e) => e.isNotEmpty).join(' • '),
          style: textTheme.bodySmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.72),
          ),
        ),
        const SizedBox(height: 12),
        _DetailPrice(
          p: p,
          selectedVariant: selectedVariant,
        ),
        const SizedBox(height: 14),
        if (p.hasVariants && p.variants.isNotEmpty) ...[
          Text('Варианты', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          _VariantChipRow(
            p: p,
            selectedVariantId: selectedVariantId,
            onVariantSelected: onVariantSelected,
          ),
          if (!canAddToCart) ...[
            const SizedBox(height: 8),
            Text(
              'Выберите вариант, чтобы добавить в корзину',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.error.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),
        ],
        if (p.description.trim().isNotEmpty) ...[
          Text('Описание', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            stripHtml(p.description),
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.82),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (p.attributes.isNotEmpty) ...[
          Text('Характеристики', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          ...p.attributes.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      e.key,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                  ),
                  Text(
                    e.value,
                    style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        Row(
          children: [
            _QtyPicker(qty: qty, onChanged: onQtyChanged),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: canAddToCart ? onAddToCart : null,
                child: const Text('Добавить в корзину'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _VariantChipRow extends StatelessWidget {
  const _VariantChipRow({
    required this.p,
    required this.selectedVariantId,
    required this.onVariantSelected,
  });

  final ProductDetail p;
  final String? selectedVariantId;
  final ValueChanged<String> onVariantSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final v in p.variants)
          _VariantChoiceChip(
            variant: v,
            currency: p.currency,
            selected: v.id == selectedVariantId,
            scheme: scheme,
            textTheme: textTheme,
            onTap: () => onVariantSelected(v.id),
          ),
      ],
    );
  }
}

class _VariantChoiceChip extends StatelessWidget {
  const _VariantChoiceChip({
    required this.variant,
    required this.currency,
    required this.selected,
    required this.scheme,
    required this.textTheme,
    required this.onTap,
  });

  final ProductVariantInline variant;
  final String currency;
  final bool selected;
  final ColorScheme scheme;
  final TextTheme textTheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final swatch = variantSwatchColor(variant);
    final attrLine = variantAttributeLine(variant);
    final priceLabel = variantPriceLabel(variant, currency);
    final showOnlySwatch = swatch != null && attrLine.isEmpty;

    final borderColor = selected ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.45);
    final bg = selected
        ? scheme.primary.withValues(alpha: 0.12)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.20);

    final baseStyle = textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: scheme.onSurface.withValues(alpha: 0.92),
    );
    final priceStyle = textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w800,
      color: scheme.primary,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (swatch != null) ...[
                Semantics(
                  label: _variantSemanticsLabel(
                    variant: variant,
                    currency: currency,
                    swatch: swatch,
                    attrLine: attrLine,
                    priceLabel: priceLabel,
                  ),
                  child: Container(
                    width: showOnlySwatch ? 36 : 28,
                    height: showOnlySwatch ? 36 : 28,
                    decoration: BoxDecoration(
                      color: swatch,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: scheme.outline.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text.rich(
                  TextSpan(
                    style: baseStyle,
                    children: _variantChipTextSpans(
                      variant: variant,
                      attrLine: attrLine,
                      priceLabel: priceLabel,
                      baseStyle: baseStyle,
                      priceStyle: priceStyle,
                    ),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<TextSpan> _variantChipTextSpans({
  required ProductVariantInline variant,
  required String attrLine,
  required String? priceLabel,
  required TextStyle? baseStyle,
  required TextStyle? priceStyle,
}) {
  final spans = <TextSpan>[];
  if (attrLine.isNotEmpty) {
    spans.add(TextSpan(text: attrLine, style: baseStyle));
  }
  if (priceLabel != null) {
    if (attrLine.isNotEmpty) {
      spans.add(TextSpan(text: ' ', style: baseStyle));
    }
    spans.add(TextSpan(text: priceLabel, style: priceStyle));
  }
  if (spans.isEmpty) {
    spans.add(TextSpan(text: variant.sku, style: baseStyle));
  }
  return spans;
}

String _variantSemanticsLabel({
  required ProductVariantInline variant,
  required String currency,
  required Color swatch,
  required String attrLine,
  required String? priceLabel,
}) {
  final buf = StringBuffer();
  var hasColor = false;
  for (final a in variant.attributeValues) {
    if (parseColorFromString(a.value) == swatch && a.value.trim().isNotEmpty) {
      buf.write('Цвет: ${a.value.trim()}');
      hasColor = true;
      break;
    }
  }
  if (attrLine.isNotEmpty) {
    if (hasColor) buf.write('. ');
    buf.write(attrLine);
  }
  if (priceLabel != null) {
    if (buf.isNotEmpty) buf.write(' ');
    buf.write(priceLabel);
  }
  if (buf.isEmpty) return 'Вариант ${variant.sku}';
  return buf.toString();
}

class _DetailPrice extends StatelessWidget {
  const _DetailPrice({
    required this.p,
    required this.selectedVariant,
  });

  final ProductDetail p;
  final ProductVariantInline? selectedVariant;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (selectedVariant != null && selectedVariant!.effectivePrice.isNotEmpty) {
      return Text(
        '${selectedVariant!.effectivePrice} ${p.currency}',
        style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
      );
    }

    final hasPromo = p.promoPrice != null && p.promoPrice!.isNotEmpty;

    if (!hasPromo) {
      return Text(
        '${p.effectivePrice} ${p.currency}',
        style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
      );
    }

    return Row(
      children: [
        Text(
          '${p.price} ${p.currency}',
          style: textTheme.bodyMedium?.copyWith(
            decoration: TextDecoration.lineThrough,
            color: scheme.onSurface.withValues(alpha: 0.60),
            decorationThickness: 2,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${p.promoPrice} ${p.currency}',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

/// Галереяи аксҳои маҳсулот — pinch-zoom ва full-screen бо пахш.
class _ProductImageGallery extends StatefulWidget {
  const _ProductImageGallery({required this.images, required this.productSlug});

  final List<String> images;
  final String productSlug;

  @override
  State<_ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<_ProductImageGallery> {
  late final PageController _pageController;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openFullscreen() {
    if (widget.images.isEmpty) return;
    showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierLabel: 'Закрыть',
      barrierColor: Colors.black.withValues(alpha: 0.78),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _ProductImageFullscreen(
          images: widget.images,
          initialIndex: _index,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final images = widget.images;
    final pageCount = images.isEmpty ? 1 : images.length;

    return Container(
      height: 360,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: GrassColors.productImageBackground,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _index = i),
              itemCount: pageCount,
              itemBuilder: (context, index) {
                if (images.isEmpty) {
                  return ColoredBox(
                    color: GrassColors.productImageBackground,
                    child: Icon(Icons.image_outlined, size: 56, color: scheme.primary),
                  );
                }
                return _InlineZoomableImage(
                  imageUrl: images[index],
                  errorIcon: Icon(Icons.broken_image_outlined, size: 56, color: scheme.primary),
                );
              },
            ),
            Positioned(
              top: 10,
              right: 10,
              child: _ProductEngagementActions(productSlug: widget.productSlug),
            ),
            if (images.length > 1)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(images.length, (i) {
                    final active = i == _index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: active ? 18 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: active
                            ? scheme.primary
                            : scheme.onSurface.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    );
                  }),
                ),
              ),
            if (images.isNotEmpty)
              Positioned(
                left: 10,
                bottom: 10,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: _openFullscreen,
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.zoom_out_map, size: 16, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Увеличить',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InlineZoomableImage extends StatelessWidget {
  const _InlineZoomableImage({
    required this.imageUrl,
    required this.errorIcon,
  });

  final String imageUrl;
  final Widget errorIcon;

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 1,
      maxScale: 4,
      clipBehavior: Clip.none,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: GrassCachedNetworkImage(
          url: imageUrl,
          width: MediaQuery.sizeOf(context).width,
          height: 320,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          maxCacheSide: 1024,
          errorWidget: ColoredBox(
            color: GrassColors.productImageBackground,
            child: errorIcon,
          ),
        ),
      ),
    );
  }
}

class _ProductImageFullscreen extends StatefulWidget {
  const _ProductImageFullscreen({required this.images, required this.initialIndex});

  final List<String> images;
  final int initialIndex;

  @override
  State<_ProductImageFullscreen> createState() => _ProductImageFullscreenState();
}

class _ProductImageFullscreenState extends State<_ProductImageFullscreen> {
  late final PageController _pageController;
  late int _index;
  bool _pageScrollEnabled = true;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onZoomChanged(bool zoomed) {
    final enabled = !zoomed;
    if (_pageScrollEnabled == enabled) return;
    setState(() => _pageScrollEnabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    final size = MediaQuery.sizeOf(context);

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.opaque,
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          child: Stack(
            children: [
              PageView.builder(
              controller: _pageController,
              physics: _pageScrollEnabled
                  ? const PageScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() {
                _index = i;
                _pageScrollEnabled = true;
              }),
              itemCount: images.length,
              itemBuilder: (context, index) {
                return _FullscreenZoomableImage(
                  imageUrl: images[index],
                  viewportWidth: size.width,
                  viewportHeight: size.height,
                  onZoomChanged: _onZoomChanged,
                );
              },
            ),
            Positioned(
              top: 4,
              left: 4,
              child: IconButton(
                tooltip: 'Закрыть',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
            if (images.length > 1)
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Text(
                  '${_index + 1} / ${images.length}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullscreenZoomableImage extends StatefulWidget {
  const _FullscreenZoomableImage({
    required this.imageUrl,
    required this.viewportWidth,
    required this.viewportHeight,
    required this.onZoomChanged,
  });

  final String imageUrl;
  final double viewportWidth;
  final double viewportHeight;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_FullscreenZoomableImage> createState() => _FullscreenZoomableImageState();
}

class _FullscreenZoomableImageState extends State<_FullscreenZoomableImage> {
  final TransformationController _controller = TransformationController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTransform);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTransform);
    _controller.dispose();
    super.dispose();
  }

  void _handleTransform() {
    final zoomed = _controller.value.getMaxScaleOnAxis() > 1.01;
    widget.onZoomChanged(zoomed);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.translucent,
      child: InteractiveViewer(
        transformationController: _controller,
        minScale: 1,
        maxScale: 5,
        clipBehavior: Clip.none,
        panEnabled: true,
        scaleEnabled: true,
        boundaryMargin: const EdgeInsets.all(48),
        child: SizedBox(
          width: widget.viewportWidth,
          height: widget.viewportHeight,
          child: GrassCachedNetworkImage(
            url: widget.imageUrl,
            width: widget.viewportWidth,
            height: widget.viewportHeight,
            fit: BoxFit.contain,
            maxCacheSide: 1200,
            errorWidget: const Icon(
              Icons.broken_image_outlined,
              size: 64,
              color: Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}

class _QtyPicker extends StatelessWidget {
  const _QtyPicker({required this.qty, required this.onChanged});
  final int qty;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: qty > 1 ? () => onChanged(qty - 1) : null,
            icon: const Icon(Icons.remove),
          ),
          Text('$qty'),
          IconButton(
            onPressed: () => onChanged(qty + 1),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

