import '../../api/api_client.dart';
import 'notification_item.dart';

class NotificationsRepository {
  NotificationsRepository(this._api);
  final ApiClient _api;

  Future<int> fetchUnreadCount({String? bearerToken}) async {
    try {
      final json = await _api.getJson(
        '/api/v1/notifications/unread-count/',
        bearerToken: bearerToken,
      );
      final count = json['count'];
      if (count is int) return count;
      return int.tryParse(count.toString()) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<List<NotificationItem>> fetchNotifications({String? bearerToken}) async {
    final json = await _api.getJson(
      '/api/v1/notifications/',
      bearerToken: bearerToken,
      query: {'page_size': '30'},
    );
    final results = json['results'];
    if (results is List) {
      return results
          .whereType<Map<String, dynamic>>()
          .map(NotificationItem.fromJson)
          .toList(growable: false);
    }
    return const [];
  }

  Future<void> markRead(String id, {String? bearerToken}) async {
    try {
      await _api.postJson(
        '/api/v1/notifications/$id/mark-read/',
        bearerToken: bearerToken,
      );
    } catch (_) {}
  }
}

