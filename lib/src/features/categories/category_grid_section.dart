import 'package:flutter/material.dart';

import '../../theme/grass_colors.dart';
import '../../ui/category_image_fallback.dart';
import '../../ui/skeleton.dart';
import 'category_item.dart';

BorderSide categoryGridBorderSide(ColorScheme scheme) => BorderSide(
      color: scheme.outline.withValues(alpha: 0.42),
      width: 1,
    );

class CategoryGridSection extends StatelessWidget {
  const CategoryGridSection({
    super.key,
    required this.categories,
    required this.onOpenCategory,
  });

  final List<CategoryItem> categories;
  final void Function(CategoryItem c) onOpenCategory;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.68,
      ),
      itemBuilder: (context, index) {
        final c = categories[index];
        return CategoryGridTile(
          name: c.name,
          imageUrl: c.imageUrl,
          productCount: c.productCount,
          scheme: scheme,
          textTheme: textTheme,
          onTap: () => onOpenCategory(c),
        );
      },
    );
  }
}

class CategoryGridTile extends StatefulWidget {
  const CategoryGridTile({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.productCount,
    required this.scheme,
    required this.textTheme,
    required this.onTap,
  });

  final String name;
  final String? imageUrl;
  final int productCount;
  final ColorScheme scheme;
  final TextTheme textTheme;
  final VoidCallback onTap;

  @override
  State<CategoryGridTile> createState() => _CategoryGridTileState();
}

class _CategoryGridTileState extends State<CategoryGridTile> {
  bool _imageFailed = false;

  @override
  void didUpdateWidget(covariant CategoryGridTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _imageFailed = false;
    }
  }

  bool get _hasPhoto =>
      !_imageFailed && widget.imageUrl != null && widget.imageUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final name = widget.name;
    final scheme = widget.scheme;
    final textTheme = widget.textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.fromBorderSide(categoryGridBorderSide(scheme)),
            color: scheme.surfaceContainerLow,
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_hasPhoto)
                  Image.network(
                    widget.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted || _imageFailed) return;
                        setState(() => _imageFailed = true);
                      });
                      return const CategoryImageFallback();
                    },
                  )
                else
                  const CategoryImageFallback(),
                if (_hasPhoto)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0),
                            Colors.black.withValues(alpha: 0.62),
                          ],
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: _hasPhoto
                              ? Colors.white
                              : GrassColors.grassBlack,
                          height: 1.05,
                          fontSize: 12,
                          shadows: _hasPhoto
                              ? const [
                                  Shadow(blurRadius: 6, color: Colors.black54),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.productCount} шт',
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: _hasPhoto
                              ? Colors.white.withValues(alpha: 0.92)
                              : GrassColors.grassBlack.withValues(alpha: 0.62),
                          fontSize: 11,
                          shadows: _hasPhoto
                              ? const [
                                  Shadow(blurRadius: 4, color: Colors.black54),
                                ]
                              : null,
                        ),
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
  }
}

class CategoryGridSkeleton extends StatelessWidget {
  const CategoryGridSkeleton({super.key});

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
      itemBuilder: (context, index) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.fromBorderSide(categoryGridBorderSide(Theme.of(context).colorScheme)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.5),
          child: const SkeletonBox(
            width: double.infinity,
            height: double.infinity,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
    );
  }
}
