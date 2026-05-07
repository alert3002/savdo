import '../../config/app_config.dart';

class ProductDetail {
  const ProductDetail({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.currency,
    required this.price,
    required this.promoPrice,
    required this.effectivePrice,
    required this.hasVariants,
    required this.primaryImage,
    required this.images,
    required this.variants,
    required this.categoryName,
    required this.brandName,
    required this.attributes,
  });

  final String id;
  final String name;
  final String slug;
  final String description;
  final String currency;
  final String price;
  final String? promoPrice;
  final String effectivePrice;
  final bool hasVariants;
  final String? primaryImage;
  final List<String> images;
  final List<ProductVariantInline> variants;
  final String? categoryName;
  final String? brandName;
  final Map<String, String> attributes;

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    String? categoryName;
    if (category is Map<String, dynamic>) {
      final name = category['name'];
      if (name is String) categoryName = name;
    }

    final brand = json['brand'];
    String? brandName;
    if (brand is Map<String, dynamic>) {
      final name = brand['name'];
      if (name is String) brandName = name;
    }

    final images = <String>[];
    final imagesJson = json['images'];
    if (imagesJson is List) {
      for (final img in imagesJson) {
        if (img is Map<String, dynamic>) {
          final url = AppConfig.normalizeMediaUrl(img['image_url'] as String?);
          if (url != null && url.isNotEmpty) images.add(url);
        }
      }
    }

    final variants = <ProductVariantInline>[];
    final variantsJson = json['variants'];
    if (variantsJson is List) {
      for (final v in variantsJson) {
        if (v is Map<String, dynamic>) variants.add(ProductVariantInline.fromJson(v));
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

    final price = json['price'];
    final promo = json['promo_price'];
    final eff = json['effective_price'];

    return ProductDetail(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      currency: (json['currency'] ?? '').toString(),
      price: price?.toString() ?? '',
      promoPrice: promo?.toString(),
      effectivePrice: eff?.toString() ?? '',
      hasVariants: json['has_variants'] == true,
      primaryImage: AppConfig.normalizeMediaUrl(json['primary_image'] as String?),
      images: images,
      variants: variants,
      categoryName: categoryName,
      brandName: brandName,
      attributes: attrs,
    );
  }
}

class VariantAttributeValue {
  const VariantAttributeValue({
    required this.id,
    required this.attribute,
    required this.value,
  });

  final String id;
  final String attribute;
  final String value;

  factory VariantAttributeValue.fromJson(Map<String, dynamic> json) {
    return VariantAttributeValue(
      id: (json['id'] ?? '').toString(),
      attribute: (json['attribute'] ?? '').toString(),
      value: (json['value'] ?? '').toString(),
    );
  }
}

class ProductVariantInline {
  const ProductVariantInline({
    required this.id,
    required this.sku,
    required this.effectivePrice,
    required this.imageUrl,
    required this.attributeValues,
  });

  final String id;
  final String sku;
  final String effectivePrice;
  final String? imageUrl;
  final List<VariantAttributeValue> attributeValues;

  factory ProductVariantInline.fromJson(Map<String, dynamic> json) {
    final eff = json['effective_price'];
    final avJson = json['attribute_values'];
    final attrs = <VariantAttributeValue>[];
    if (avJson is List) {
      for (final e in avJson) {
        if (e is Map<String, dynamic>) {
          attrs.add(VariantAttributeValue.fromJson(e));
        }
      }
    }
    return ProductVariantInline(
      id: (json['id'] ?? '').toString(),
      sku: (json['sku'] ?? '').toString(),
      effectivePrice: eff?.toString() ?? '',
      imageUrl: AppConfig.normalizeMediaUrl(json['image_url'] as String?),
      attributeValues: attrs,
    );
  }
}

