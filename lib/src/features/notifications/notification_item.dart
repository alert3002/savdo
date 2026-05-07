class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? createdAt;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    DateTime? createdAt;
    final created = json['created_at'];
    if (created is String) {
      createdAt = DateTime.tryParse(created);
    }

    return NotificationItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      isRead: json['is_read'] == true,
      createdAt: createdAt,
    );
  }
}

