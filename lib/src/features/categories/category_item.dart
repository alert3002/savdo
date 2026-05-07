import '../../config/app_config.dart';

class CategoryItem {
  const CategoryItem({
    required this.id,
    required this.name,
    required this.slug,
    required this.imageUrl,
    this.productCount = 0,
  });

  final String id;
  final String name;
  final String slug;
  final String? imageUrl;
  /// Маҳсулоти фаъол/намоён дар ин категория (аз API).
  final int productCount;

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    final pc = json['product_count'];
    return CategoryItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      imageUrl: AppConfig.normalizeMediaUrl(json['image_url'] as String?),
      productCount: pc is int ? pc : int.tryParse('$pc') ?? 0,
    );
  }
}

