import '../products/product_detail.dart';

class CartItem {
  const CartItem({
    required this.slug,
    required this.name,
    required this.currency,
    required this.unitPrice,
    required this.qty,
    required this.imageUrl,
    required this.variantSku,
    this.variantId,
    this.variantLabel,
  });

  final String slug;
  final String name;
  final String currency;
  final String unitPrice;
  final int qty;
  final String? imageUrl;
  final String? variantSku;
  /// UUID вариант барои API-и checkout.
  final String? variantId;
  /// Матни зерии маҳсулот дар корзина (масалан «Размер: 2 Цена: …»).
  final String? variantLabel;

  String get key => '$slug::${variantId ?? variantSku ?? ''}';

  CartItem copyWith({int? qty}) => CartItem(
        slug: slug,
        name: name,
        currency: currency,
        unitPrice: unitPrice,
        qty: qty ?? this.qty,
        imageUrl: imageUrl,
        variantSku: variantSku,
        variantId: variantId,
        variantLabel: variantLabel,
      );

  static CartItem fromProduct(
    ProductDetail p, {
    required int qty,
    String? variantSku,
    String? variantId,
    String? variantLabel,
    String? unitPrice,
  }) {
    return CartItem(
      slug: p.slug,
      name: p.name,
      currency: p.currency,
      unitPrice: unitPrice ?? p.effectivePrice,
      qty: qty,
      imageUrl: p.primaryImage,
      variantSku: variantSku,
      variantId: variantId,
      variantLabel: variantLabel,
    );
  }
}

