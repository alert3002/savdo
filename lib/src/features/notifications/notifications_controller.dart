import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../search/product_search_controller.dart' show apiClientProvider;
import 'notification_item.dart';
import 'notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(ref.watch(apiClientProvider)),
);

final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  final token = ref.watch(authControllerProvider).accessToken;
  final repo = ref.watch(notificationsRepositoryProvider);
  return repo.fetchUnreadCount(bearerToken: token);
});

final notificationsListProvider = FutureProvider<List<NotificationItem>>((ref) async {
  final token = ref.watch(authControllerProvider).accessToken;
  final repo = ref.watch(notificationsRepositoryProvider);
  return repo.fetchNotifications(bearerToken: token);
});

