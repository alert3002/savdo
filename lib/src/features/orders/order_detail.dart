class OrderItemLine {
  const OrderItemLine({
    required this.id,
    required this.productName,
    required this.variantId,
    required this.variantSku,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });

  final String id;
  final String productName;
  final String variantId;
  final String? variantSku;
  final String unitPrice;
  final int quantity;
  final String lineTotal;

  factory OrderItemLine.fromJson(Map<String, dynamic> json) {
    return OrderItemLine(
      id: (json['id'] ?? '').toString(),
      productName: (json['product_name_snapshot'] ?? '').toString(),
      variantId: (json['variant'] ?? '').toString(),
      variantSku: (json['variant_sku'] as String?)?.trim().isEmpty ?? true
          ? null
          : (json['variant_sku'] as String?)?.trim(),
      unitPrice: (json['product_price_snapshot'] ?? '').toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      lineTotal: (json['line_total'] ?? '').toString(),
    );
  }
}

class OrderDetail {
  const OrderDetail({
    required this.id,
    required this.status,
    required this.items,
  });

  final String id;
  final String status;
  final List<OrderItemLine> items;

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(OrderItemLine.fromJson)
            .toList(growable: false)
        : const <OrderItemLine>[];

    return OrderDetail(
      id: (json['id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      items: items,
    );
  }
}

