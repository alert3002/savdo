import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../brand/brand_assets.dart';
import '../../features/notifications/notifications_controller.dart';
import '../../features/products/product_engagement_controller.dart';
import '../../features/settings/app_settings.dart';
import '../../routing/app_routes.dart';
import 'app_shell_scaffold_key.dart';

/// Drawer-и пурра аз чап — тамоми навигация ва бахшҳои иттилоотӣ.
class ShopNavigationDrawer extends ConsumerWidget {
  const ShopNavigationDrawer({super.key});

  void _closeAndPush(BuildContext context, String location) {
    appShellScaffoldKey.currentState?.closeDrawer();
    GoRouter.of(context).push(location);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = scheme.brightness == Brightness.dark;
    final logo = isDark ? BrandAssets.logoWhiteHorizontal : BrandAssets.logoBlackHorizontal;
    final fullW = MediaQuery.sizeOf(context).width;
    final settings = ref.watch(appSettingsProvider).maybeWhen(
          data: (s) => s,
          orElse: () => null,
        );
    final showShop = settings?.showShopFeatures ?? true;

    final favCount = ref.watch(favoriteProductSlugsProvider).maybeWhen(
          data: (s) => s.length,
          orElse: () => 0,
        );
    final cmpCount = ref.watch(compareProductSlugsProvider).maybeWhen(
          data: (s) => s.length,
          orElse: () => 0,
        );
    final unread = ref.watch(unreadNotificationsCountProvider).maybeWhen(
          data: (v) => v,
          orElse: () => 0,
        );

    return Drawer(
      width: fullW,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => appShellScaffoldKey.currentState?.closeDrawer(),
                    icon: const Icon(Icons.close),
                    tooltip: 'Закрыть',
                  ),
                  Expanded(
                    child: Center(
                      child: Image.asset(logo, height: 28, fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.35)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  if (showShop) ...[
                    _SectionLabel(text: 'Мои списки', scheme: scheme, textTheme: textTheme),
                    _DrawerTile(
                      icon: Icons.favorite_outline,
                      title: 'Избранное',
                      badge: favCount > 0 ? '$favCount' : null,
                      onTap: () => _closeAndPush(context, AppRoutes.favorites),
                    ),
                    _DrawerTile(
                      icon: Icons.compare_arrows,
                      title: 'Сравнение',
                      badge: cmpCount > 0 ? '$cmpCount' : null,
                      onTap: () => _closeAndPush(context, AppRoutes.compare),
                    ),
                    const SizedBox(height: 8),
                  ],
                  _SectionLabel(text: 'Сервис', scheme: scheme, textTheme: textTheme),
                  _DrawerTile(
                    icon: Icons.notifications_outlined,
                    title: 'Push-уведомления',
                    badge: unread > 0 ? '$unread' : null,
                    onTap: () => _closeAndPush(context, AppRoutes.notifications),
                  ),
                  _DrawerTile(
                    icon: Icons.settings_outlined,
                    title: 'Настройки',
                    onTap: () => _closeAndPush(context, AppRoutes.settings),
                  ),
                  const SizedBox(height: 8),
                  _SectionLabel(text: 'Информация', scheme: scheme, textTheme: textTheme),
                  _DrawerTile(
                    icon: Icons.info_outline,
                    title: 'О нас',
                    onTap: () => _closeAndPush(context, AppRoutes.infoAbout),
                  ),
                  _DrawerTile(
                    icon: Icons.payment_outlined,
                    title: 'Как оплатить',
                    onTap: () => _closeAndPush(context, AppRoutes.infoPayment),
                  ),
                  _DrawerTile(
                    icon: Icons.assignment_return_outlined,
                    title: 'Возврат',
                    onTap: () => _closeAndPush(context, AppRoutes.infoReturns),
                  ),
                  _DrawerTile(
                    icon: Icons.policy_outlined,
                    title: 'Политика конфиденциальности',
                    onTap: () => _closeAndPush(context, AppRoutes.infoPrivacy),
                  ),
                  _DrawerTile(
                    icon: Icons.help_outline,
                    title: 'Поддержка',
                    onTap: () => _closeAndPush(context, AppRoutes.infoSupport),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.text,
    required this.scheme,
    required this.textTheme,
  });

  final String text;
  final ColorScheme scheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 6),
      child: Text(
        text,
        style: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: scheme.primary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: scheme.onSurface.withValues(alpha: 0.88)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge!,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: scheme.primary,
                    ),
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}
