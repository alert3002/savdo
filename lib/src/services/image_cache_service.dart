import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Дисковый кэш картинок (категории, товары, слайдер) — не качает заново при каждом входе.
class GrassImageCache {
  GrassImageCache._();

  static final CacheManager instance = CacheManager(
    Config(
      'grass_media_cache',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 600,
      fileService: HttpFileService(),
    ),
  );
}
