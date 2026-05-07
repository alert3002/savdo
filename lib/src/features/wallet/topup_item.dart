class TopUpItem {
  const TopUpItem({
    required this.id,
    required this.reference,
    required this.amount,
    required this.currency,
    required this.status,
    required this.requestedAt,
  });

  final String id;
  final String reference;
  final String amount;
  final String currency;
  final String status;
  final DateTime? requestedAt;

  factory TopUpItem.fromJson(Map<String, dynamic> json) {
    return TopUpItem(
      id: (json['id'] ?? '').toString(),
      reference: (json['reference'] ?? '').toString(),
      amount: (json['amount'] ?? '').toString(),
      currency: (json['currency'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      requestedAt: DateTime.tryParse((json['requested_at'] ?? '').toString()),
    );
  }
}

