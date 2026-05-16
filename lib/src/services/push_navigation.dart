import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routing/app_routes.dart';

/// Навигация по данным FCM (data payload).
void navigateFromPushData(BuildContext context, Map<String, dynamic> data) {
  final route = (data['route'] ?? data['screen'] ?? '').toString().toLowerCase();
  final slug = (data['slug'] ?? data['product_slug'] ?? '').toString();

  switch (route) {
    case 'notifications':
    case 'notification':
      context.push(AppRoutes.notifications);
      return;
    case 'orders':
    case 'order':
      context.push(AppRoutes.profileMyOrders);
      return;
    case 'wallet':
      context.push(AppRoutes.profileWallet);
      return;
    case 'mlm':
      context.go(AppRoutes.mlm);
      return;
    case 'cart':
      context.go(AppRoutes.cart);
      return;
    case 'product':
      if (slug.isNotEmpty) {
        context.push(AppRoutes.productBySlug(slug));
      }
      return;
    case 'catalog':
      context.go(AppRoutes.catalog);
      return;
    default:
      if (slug.isNotEmpty) {
        context.push(AppRoutes.productBySlug(slug));
      }
  }
}

void handleRemoteMessageNavigation(
  GlobalKey<NavigatorState> navigatorKey,
  RemoteMessage message,
) {
  final ctx = navigatorKey.currentContext;
  if (ctx == null) return;
  navigateFromPushData(ctx, message.data);
}

void showForegroundPushBanner(
  BuildContext context,
  RemoteMessage message, {
  required VoidCallback onTap,
}) {
  final title = message.notification?.title ?? message.data['title']?.toString() ?? 'Уведомление';
  final body = message.notification?.body ?? message.data['body']?.toString() ?? '';

  ScaffoldMessenger.of(context).showMaterialBanner(
    MaterialBanner(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          if (body.isNotEmpty) Text(body),
        ],
      ),
      leading: const Icon(Icons.notifications_active_outlined),
      actions: [
        TextButton(onPressed: onTap, child: const Text('Открыть')),
        TextButton(
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
          child: const Text('Закрыть'),
        ),
      ],
    ),
  );
}
