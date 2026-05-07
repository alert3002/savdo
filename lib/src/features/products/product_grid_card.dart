import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'product_engagement_controller.dart';
import '../../routing/app_routes.dart';
import 'product_summary.dart';

/// Карточка маҳсулот дар шабака (мағоза, каталог).
class ProductGridCard extends ConsumerWidget {
  const ProductGridCard({super.key, required this.item});

  final ProductSummary item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isFav = ref.watch(favoriteProductSlugsProvider).maybeWhen(
          data: (s) => s.contains(item.slug),
          orElse: () => false,
        );
    final inCompare = ref.watch(compareProductSlugsProvider).maybeWhen(
          data: (s) => s.contains(item.slug),
          orElse: () => false,
        );

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push(AppRoutes.productBySlug(item.slug)),
      child: Ink(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 120,
                color: scheme.primary.withValues(alpha: 0.10),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: item.primaryImage != null && item.primaryImage!.isNotEmpty
                          ? Image.network(
                              item.primaryImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.local_car_wash_outlined,
                                size: 46,
                                color: scheme.primary,
                              ),
                            )
                          : Icon(
                              Icons.local_car_wash_outlined,
                              size: 46,
                              color: scheme.primary,
                            ),
                        ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ActionCircleButton(
                            tooltip: 'Избранное',
                            icon: isFav ? Icons.favorite : Icons.favorite_border,
                            iconColor: isFav ? scheme.error : Colors.white,
                            onTap: () =>
                                ref.read(favoriteProductSlugsProvider.notifier).toggle(item.slug),
                          ),
                          const SizedBox(width: 6),
                          _ActionCircleButton(
                            tooltip: 'Сравнение',
                            icon: Icons.compare_arrows,
                            iconColor: inCompare ? scheme.primary : Colors.white,
                            onTap: () async {
                              final ok = await ref
                                  .read(compareProductSlugsProvider.notifier)
                                  .toggle(item.slug);
                              if (!context.mounted || ok) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('В сравнении не более $kCompareMaxItems товаров'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyLarge?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.categoryName ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.70),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _PriceBlock(item: item),
                        ),
                        IconButton.filledTonal(
                          onPressed: () =>
                              context.push(AppRoutes.productBySlug(item.slug)),
                          icon: const Icon(Icons.add, size: 16),
                          tooltip: 'Открыть',
                          style: IconButton.styleFrom(
                            minimumSize: const Size(34, 34),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (item.hasVariants) ...[
                      const SizedBox(height: 4),
                      _VariantHint(item: item),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCircleButton extends StatelessWidget {
  const _ActionCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.iconColor,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(icon, size: 16, color: iconColor),
        ),
      ),
    );
  }
}

class _VariantHint extends StatelessWidget {
  const _VariantHint({required this.item});
  final ProductSummary item;

  String? _pickAttr(String key) {
    final lowerKey = key.toLowerCase();
    for (final entry in item.attributes.entries) {
      final k = entry.key.toLowerCase();
      if (k.contains(lowerKey)) return entry.value;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final variantColors = item.variantColorValues;

    String? color = _pickAttr('цвет') ??
        _pickAttr('оттен') ??
        _pickAttr('тон') ??
        _pickAttr('rang') ??
        _pickAttr('color');

    // If key names differ between API responses (home/category vs detail),
    // try to detect a "color-like" value by content.
    if (color == null || color.trim().isEmpty) {
      const colorNeedle = [
        'черн',
        'black',
        'бел',
        'white',
        'красн',
        'red',
        'син',
        'blue',
        'желт',
        'yellow',
        'оранж',
        'orange',
        'фиол',
        'purple',
        'роз',
        'pink',
        'корич',
        'brown',
        'сер',
        'gray',
        'grey',
      ];
      final hexRe = RegExp(r'#?[0-9a-fA-F]{3}([0-9a-fA-F]{3})$');

      for (final e in item.attributes.entries) {
        final v = e.value.trim();
        if (v.isEmpty) continue;
        final vl = v.toLowerCase();
        if (colorNeedle.any((n) => vl.contains(n)) || hexRe.hasMatch(vl)) {
          color = v;
          break;
        }
      }
    }
    final size = _pickAttr('размер') ?? _pickAttr('андоза') ?? _pickAttr('size');

    List<String> splitTokens(String raw) {
      return raw
          // Support separators like: "black/white", "black; white", "black, white", "red и white"
          .split(RegExp(r'[,\n;|/]+|\s+и\s+|\s*&\s+'))
          .map((e) {
            var t = e.trim();
            // Remove possible prefixes like "Цвет: " or "Color-".
            t = t.replaceAll(RegExp(r'^\s*.*?:\s*'), '');
            return t.trim();
          })
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    }

    Color? parseHexColor(String token) {
      var t = token.trim();
      if (t.startsWith('#')) t = t.substring(1);
      if (t.length == 3) {
        // RGB -> RRGGBB
        t = '${t[0]}${t[0]}${t[1]}${t[1]}${t[2]}${t[2]}';
      }
      if (t.length != 6) return null;
      final rgb = int.tryParse(t, radix: 16);
      if (rgb == null) return null;
      return Color(0xFF000000 | rgb);
    }

    Color colorFromToken(String token) {
      final hex = parseHexColor(token);
      if (hex != null) return hex;
      final v = token.toLowerCase();

      if (v.contains('зелен') || v.contains('vert') || v == 'green') return Colors.green;
      if (v.contains('красн') || v.contains('red') || v.contains('борд')) return Colors.red;
      if (v.contains('син') || v == 'blue') return Colors.blue;
      if (v.contains('желт') || v.contains('yellow')) return Colors.yellow.shade700;
      if (v.contains('черн') || v.contains('black')) return Colors.black;
      if (v.contains('бел') || v.contains('white')) return Colors.white;
      if (v.contains('оранж') || v.contains('orange')) return Colors.orange;
      if (v.contains('фиолет') || v.contains('purple') || v.contains('пурп')) return Colors.purple;
      if (v.contains('роз') || v.contains('pink')) return Colors.pink;
      if (v.contains('сер') || v.contains('gray') || v.contains('grey')) return Colors.grey;
      if (v.contains('корич') || v.contains('brown')) return Colors.brown;
      return scheme.onSurface.withValues(alpha: 0.22);
    }

    // Prefer colors coming from variants (list endpoints). This ensures
    // that "Варианты: N" does not show when actual color values exist.
    if (variantColors.isNotEmpty) {
      final shown = variantColors.take(5).toList(growable: false);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final t in shown)
            Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorFromToken(t),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.55),
                  width: 1,
                ),
              ),
            ),
        ],
      );
    }

    if (color != null) {
      final tokens = splitTokens(color);
      if (tokens.isNotEmpty) {
        final max = tokens.length.clamp(1, 5);
        final shown = tokens.take(max).toList(growable: false);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final t in shown)
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorFromToken(t),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.55),
                    width: 1,
                  ),
                ),
              ),
            if (size != null)
              Text(
                'Размер: $size',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withValues(alpha: 0.70),
                ),
              ),
          ],
        );
      }
    }

    final text = (color != null || size != null)
        ? [
            if (color != null) 'Цвет: $color',
            if (size != null) 'Размер: $size',
          ].join(' • ')
        : 'Варианты: ${item.variantCount}';

    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface.withValues(alpha: 0.70),
      ),
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({required this.item});
  final ProductSummary item;

  Widget _priceText(
    BuildContext context, {
    required String value,
    required String currency,
    required TextStyle style,
    required double currencyFontSize,
    required double currencyOpacity,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: value),
          TextSpan(
            text: ' $currency',
            style: style.copyWith(
              fontSize: currencyFontSize,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: currencyOpacity),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final hasPromo = (item.promoPrice != null && item.promoPrice!.isNotEmpty);
    if (!hasPromo) {
      return _priceText(
        context,
        value: item.effectivePrice,
        currency: item.currency,
        style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w900) ??
            const TextStyle(fontWeight: FontWeight.w900),
        currencyFontSize: 11,
        currencyOpacity: 0.65,
      );
    }

    return Row(
      children: [
        Flexible(
          child: _priceText(
            context,
            value: item.price,
            currency: item.currency,
            style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
              fontSize: 11,
              color: scheme.onSurface.withValues(alpha: 0.42),
              decoration: TextDecoration.lineThrough,
              decorationThickness: 2,
            ),
            currencyFontSize: 10,
            currencyOpacity: 0.35,
          ),
        ),
        const SizedBox(width: 8),
        _priceText(
          context,
          value: item.promoPrice!,
          currency: item.currency,
          style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: scheme.onSurface.withValues(alpha: 0.98),
              ) ??
              TextStyle(
                fontWeight: FontWeight.w900,
                color: scheme.onSurface.withValues(alpha: 0.98),
              ),
          currencyFontSize: 11,
          currencyOpacity: 0.62,
        ),
      ],
    );
  }
}
