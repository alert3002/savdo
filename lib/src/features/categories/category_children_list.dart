import 'package:flutter/material.dart';

import '../../theme/grass_colors.dart';
import '../../ui/category_image_fallback.dart';
import '../../ui/grass_cached_network_image.dart';
import 'category_item.dart';

/// Рӯйхати подкатегорияҳо (на grid).
class CategoryChildrenList extends StatelessWidget {
  const CategoryChildrenList({
    super.key,
    required this.categories,
    required this.onOpenCategory,
  });

  final List<CategoryItem> categories;
  final void Function(CategoryItem c) onOpenCategory;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      itemCount: categories.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final c = categories[index];
        return _CategoryChildListTile(
          category: c,
          onTap: () => onOpenCategory(c),
        );
      },
    );
  }
}

class _CategoryChildListTile extends StatefulWidget {
  const _CategoryChildListTile({
    required this.category,
    required this.onTap,
  });

  final CategoryItem category;
  final VoidCallback onTap;

  @override
  State<_CategoryChildListTile> createState() => _CategoryChildListTileState();
}

class _CategoryChildListTileState extends State<_CategoryChildListTile> {
  bool _imageFailed = false;

  @override
  void didUpdateWidget(covariant _CategoryChildListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category.imageUrl != widget.category.imageUrl) {
      _imageFailed = false;
    }
  }

  bool get _hasPhoto {
    final url = widget.category.imageUrl;
    return !_imageFailed && url != null && url.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final c = widget.category;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: widget.onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: scheme.surfaceContainerLow,
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ColoredBox(
                  color: GrassColors.productImageBackground,
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: _hasPhoto
                        ? GrassCachedNetworkImage(
                            url: c.imageUrl!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.contain,
                            maxCacheSide: 200,
                            onError: () {
                              if (mounted) setState(() => _imageFailed = true);
                            },
                            errorWidget: const CategoryImageFallback(compact: true),
                          )
                        : const CategoryImageFallback(compact: true),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${c.productCount} шт',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: scheme.onSurface.withValues(alpha: 0.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
