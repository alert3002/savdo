import '../../config/app_config.dart';

class ProductSummary {
  const ProductSummary({
    required this.id,
    required this.name,
    required this.slug,
    required this.currency,
    required this.price,
    required this.promoPrice,
    required this.effectivePrice,
    required this.primaryImage,
    required this.categoryName,
    required this.hasVariants,
    required this.variantCount,
    required this.variantColorValues,
    required this.variantSizeValues,
    required this.attributes,
  });

  final String id;
  final String name;
  final String slug;
  final String currency;
  final String price;
  final String? promoPrice;
  final String effectivePrice;
  final String? primaryImage;
  final String? categoryName;
  final bool hasVariants;
  final int variantCount;
  final List<String> variantColorValues;
  final List<String> variantSizeValues;
  final Map<String, String> attributes;

  factory ProductSummary.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    String? categoryName;
    if (category is Map<String, dynamic>) {
      final name = category['name'];
      if (name is String) categoryName = name;
    }
    final eff = json['effective_price'];
    final price = json['price'];
    final promo = json['promo_price'];

    final hasVariants = json['has_variants'] == true;
    int variantCount = 0;
    final variants = json['variants'];
    final variantColorValues = <String>{};
    final variantSizeValues = <String>{};
    if (variants is List) {
      variantCount = variants.length;
      for (final v in variants) {
        if (v is! Map<String, dynamic>) continue;
        final attributeValues = v['attribute_values'];
        if (attributeValues is! List) continue;
        for (final av in attributeValues) {
          if (av is! Map<String, dynamic>) continue;
          final attributeName = av['attribute'];
          final value = av['value'];
          if (attributeName is! String || value is! String) continue;
          final a = attributeName.toLowerCase().trim();
          final val = value.trim();
          if (val.isEmpty) continue;

          if (a.contains('цвет') ||
              a.contains('otten') ||
              a.contains('тон') ||
              a.contains('rang') ||
              a.contains('color')) {
            variantColorValues.add(val);
          }
          if (a.contains('размер') || a.contains('size') || a.contains('андоза')) {
            variantSizeValues.add(val);
          }
        }
      }
    }

    final attrs = <String, String>{};
    final attributeValues = json['attribute_values'];
    if (attributeValues is List) {
      for (final v in attributeValues) {
        if (v is Map<String, dynamic>) {
          final a = v['attribute'];
          final val = v['value'];
          if (a is String && val is String && a.trim().isNotEmpty) {
            attrs[a.trim()] = val.trim();
          }
        }
      }
    }
    return ProductSummary(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      currency: (json['currency'] ?? '').toString(),
      price: price?.toString() ?? '',
      promoPrice: promo?.toString(),
      effectivePrice: eff?.toString() ?? '',
      primaryImage: AppConfig.normalizeMediaUrl(json['primary_image'] as String?),
      categoryName: categoryName,
      hasVariants: hasVariants,
      variantCount: variantCount,
      variantColorValues: variantColorValues.toList(growable: false),
      variantSizeValues: variantSizeValues.toList(growable: false),
      attributes: attrs,
    );
  }
}

