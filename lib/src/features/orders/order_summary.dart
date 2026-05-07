class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalAmount,
    required this.deliveryFee,
    required this.grandTotal,
    required this.currency,
    required this.deliveryAddress,
    required this.createdAt,
  });

  final String id;
  final String orderNumber;
  final String status;
  final String totalAmount;
  final String deliveryFee;
  final String grandTotal;
  final String currency;
  final String deliveryAddress;
  final DateTime? createdAt;

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      id: (json['id'] ?? '').toString(),
      orderNumber: (json['order_number'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      totalAmount: (json['total_amount'] ?? '').toString(),
      deliveryFee: (json['delivery_fee'] ?? '').toString(),
      grandTotal: (json['grand_total'] ?? '').toString(),
      currency: (json['currency'] ?? '').toString(),
      deliveryAddress: (json['delivery_address'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
    );
  }
}

