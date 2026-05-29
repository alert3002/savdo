import 'package:flutter/material.dart';

import '../brand/brand_assets.dart';
import '../theme/grass_colors.dart';

/// Акси категория вақте `image_url` нест ё хато дода шуд.
class CategoryImageFallback extends StatelessWidget {
  const CategoryImageFallback({super.key, this.compact = false});

  /// Хурдтар барои ҳолати loading.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.isFinite ? constraints.maxWidth : 120.0;
        final h = constraints.maxHeight.isFinite ? constraints.maxHeight : 160.0;
        final base = w < h ? w : h;

        final scale = compact ? 0.48 : 0.62;
        final logoWidth = (base * scale).clamp(56.0, 108.0);
        final logoHeight = logoWidth * 0.38;
        final pad = (base * 0.10).clamp(8.0, 18.0);

        return DecoratedBox(
          decoration: BoxDecoration(
            color: GrassColors.productImageBackground,
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.22),
            ),
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(pad),
              child: Image.asset(
                BrandAssets.logoBlackHorizontal,
                width: logoWidth,
                height: logoHeight,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        );
      },
    );
  }
}
