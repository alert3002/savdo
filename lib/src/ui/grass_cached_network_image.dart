import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../services/image_cache_service.dart';

/// Сетевые фото: дисковый кэш + уменьшенный decode (меньше RAM на iPhone 13).
class GrassCachedNetworkImage extends StatelessWidget {
  const GrassCachedNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.medium,
    this.errorWidget,
    this.loadingBuilder,
    this.onError,
    this.maxCacheSide = 1200,
    this.fadeInDuration = const Duration(milliseconds: 200),
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final FilterQuality filterQuality;
  final Widget? errorWidget;
  final ImageLoadingBuilder? loadingBuilder;
  final VoidCallback? onError;
  final int maxCacheSide;
  final Duration fadeInDuration;

  int? _memSide(BuildContext context, double logical) {
    if (!logical.isFinite || logical <= 0) return null;
    final px = (logical * MediaQuery.devicePixelRatioOf(context)).round();
    return px.clamp(1, maxCacheSide);
  }

  /// Танҳо як тараф — вагарна decode ҳарду тарафро мезанад ва сурат дароз мешавад.
  ({int? width, int? height}) _memCacheSize(BuildContext context) {
    if (width == null && height == null) return (width: null, height: null);

    if (width != null && height != null) {
      if (width! >= height!) {
        return (width: _memSide(context, width!), height: null);
      }
      return (width: null, height: _memSide(context, height!));
    }
    if (width != null) {
      return (width: _memSide(context, width!), height: null);
    }
    return (width: null, height: _memSide(context, height!));
  }

  @override
  Widget build(BuildContext context) {
    final mem = _memCacheSize(context);

    return CachedNetworkImage(
      imageUrl: url,
      cacheManager: GrassImageCache.instance,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      filterQuality: filterQuality,
      memCacheWidth: mem.width,
      memCacheHeight: mem.height,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: Duration.zero,
      useOldImageOnUrlChange: true,
      progressIndicatorBuilder: (context, imageUrl, progress) {
        final done = progress.progress != null && progress.progress! >= 1;
        if (done) return const SizedBox.shrink();
        if (loadingBuilder != null) {
          return loadingBuilder!(context, const SizedBox.shrink(), null);
        }
        return Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: progress.progress,
            ),
          ),
        );
      },
      errorWidget: (context, imageUrl, error) {
        onError?.call();
        return errorWidget ??
            Icon(
              Icons.broken_image_outlined,
              color: Theme.of(context).colorScheme.outline,
            );
      },
    );
  }
}
