import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/notifications/notifications_controller.dart';
import '../../features/search/product_search_sheet.dart';
import '../../routing/app_routes.dart';
import 'app_shell_scaffold_key.dart';

/// Кушодани менюи пурра аз чап ([Drawer]-и [HomeShell]).
void openShopNavigationDrawer() {
  appShellScaffoldKey.currentState?.openDrawer();
}

/// Иконкаи push-огоҳиномаҳо бо бейджи шумора.
class NotificationsAppBarButton extends ConsumerWidget {
  const NotificationsAppBarButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final asyncCount = ref.watch(unreadNotificationsCountProvider);
    final count = asyncCount.maybeWhen(data: (v) => v, orElse: () => 0);

    return IconButton(
      onPressed: () {
        ref.invalidate(notificationsListProvider);
        ref.invalidate(unreadNotificationsCountProvider);
        context.push(AppRoutes.notifications);
      },
      tooltip: 'Уведомления',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_none),
          if (count > 0)
            Positioned(
              right: -2,
              top: -3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: scheme.surface, width: 2),
                ),
                child: Text(
                  '$count',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        height: 1.0,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Меню + поиск + уведомления барои `AppBar.actions` дар саҳифаҳои дохилӣ.
List<Widget> shopLayerAppBarActions(BuildContext context) {
  return [
    IconButton(
      onPressed: openShopNavigationDrawer,
      icon: const Icon(Icons.menu),
      tooltip: 'Меню',
    ),
    IconButton(
      onPressed: () => showProductSearchSheet(context),
      icon: const Icon(Icons.search),
      tooltip: 'Поиск',
    ),
    const NotificationsAppBarButton(),
  ];
}
