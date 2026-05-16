import '../../config/app_config.dart';

class CategoryItem {
  const CategoryItem({
    required this.id,
    required this.name,
    required this.slug,
    required this.imageUrl,
    this.productCount = 0,
    this.parentId,
  });

  final String id;
  final String name;
  final String slug;
  final String? imageUrl;
  /// Маҳсулоти фаъол/намоён дар ин категория (аз API).
  final int productCount;
  /// `null` = категорияи реша (родительская).
  final String? parentId;

  bool get isRoot => parentId == null || parentId!.isEmpty;

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    final pc = json['product_count'];
    return CategoryItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      imageUrl: AppConfig.normalizeMediaUrl(json['image_url'] as String?),
      productCount: pc is int ? pc : int.tryParse('$pc') ?? 0,
      parentId: _parseParentId(json['parent']),
    );
  }

  static String? _parseParentId(Object? parent) {
    if (parent == null) return null;
    if (parent is String) {
      final s = parent.trim();
      return s.isEmpty ? null : s;
    }
    if (parent is Map) {
      final id = parent['id'];
      if (id == null) return null;
      final s = id.toString().trim();
      return s.isEmpty ? null : s;
    }
    final s = parent.toString().trim();
    return s.isEmpty ? null : s;
  }
}

