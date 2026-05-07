import 'package:flutter/material.dart';

import 'product_detail.dart';

bool isColorAttributeLabel(String attributeName) {
  final a = attributeName.toLowerCase().trim();
  if (a.isEmpty) return false;
  return a.contains('color') || a.contains('цвет') || a.contains('rang');
}

Color? parseColorFromString(String value) {
  var s = value.trim();
  if (s.isEmpty) return null;

  final lower = s.toLowerCase();
  const named = <String, Color>{
    'red': Color(0xFFE53935),
    'green': Color(0xFF43A047),
    'blue': Color(0xFF1E88E5),
    'black': Color(0xFF212121),
    'white': Color(0xFFFAFAFA),
    'yellow': Color(0xFFFDD835),
    'orange': Color(0xFFFB8C00),
    'purple': Color(0xFF8E24AA),
    'pink': Color(0xFFEC407A),
    'gray': Color(0xFF757575),
    'grey': Color(0xFF757575),
    'brown': Color(0xFF6D4C41),
    'красный': Color(0xFFE53935),
    'зелёный': Color(0xFF43A047),
    'зеленый': Color(0xFF43A047),
    'синий': Color(0xFF1E88E5),
    'чёрный': Color(0xFF212121),
    'черный': Color(0xFF212121),
    'белый': Color(0xFFFAFAFA),
    'жёлтый': Color(0xFFFDD835),
    'желтый': Color(0xFFFDD835),
  };
  if (named.containsKey(lower)) return named[lower];

  if (s.startsWith('#')) s = s.substring(1);
  if (s.length == 3) {
    final chars = s.split('');
    s = chars.map((c) => '$c$c').join();
  }
  if (s.length == 6 || s.length == 8) {
    final n = int.tryParse(s, radix: 16);
    if (n != null) {
      if (s.length == 6) return Color(0xFF000000 | n);
      return Color(n);
    }
  }
  return null;
}

Color? variantSwatchColor(ProductVariantInline v) {
  for (final av in v.attributeValues) {
    final c = parseColorFromString(av.value);
    if (c == null) continue;
    if (isColorAttributeLabel(av.attribute) || av.value.trim().startsWith('#')) {
      return c;
    }
  }
  return null;
}

/// Атрибутҳои матнӣ (ранг тавассути дайра нишон дода мешавад).
String variantAttributeLine(ProductVariantInline v) {
  final parts = <String>[];
  for (final av in v.attributeValues) {
    final c = parseColorFromString(av.value);
    if (c != null && (isColorAttributeLabel(av.attribute) || av.value.trim().startsWith('#'))) {
      continue;
    }
    final val = av.value.trim();
    if (val.isEmpty) continue;
    final label = displayAttributeLabelRu(av.attribute);
    parts.add('$label: $val');
  }
  return parts.join(' ');
}

String? variantPriceLabel(ProductVariantInline v, String currency) {
  if (v.effectivePrice.isEmpty) return null;
  final c = currency.trim();
  if (c.isEmpty) return 'Цена: ${v.effectivePrice}';
  return 'Цена: ${v.effectivePrice} $c';
}

String displayAttributeLabelRu(String attributeName) {
  final a = attributeName.toLowerCase().trim();
  if (a.isEmpty) return '';
  if (a.contains('size') || a.contains('размер') || a.contains('ӧлчөм') || a.contains('olcham')) {
    return 'Размер';
  }
  if (a.contains('color') || a.contains('цвет') || a.contains('rang')) {
    return 'Цвет';
  }
  final t = attributeName.trim();
  if (t.isEmpty) return '';
  return t[0].toUpperCase() + (t.length > 1 ? t.substring(1) : '');
}

/// Сатри зерии корзина: «Размер: 2 Цена: … TJS»
String? formatCartVariantSubtitle(ProductVariantInline? v, String currency) {
  if (v == null) return null;
  final attr = variantAttributeLine(v);
  final price = variantPriceLabel(v, currency);
  if (attr.isEmpty && price == null) {
    return v.sku.isEmpty ? null : v.sku;
  }
  if (attr.isEmpty) return price;
  if (price == null) return attr;
  return '$attr $price';
}
