import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/home/home_shell.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/catalog/catalog_screen.dart';
import '../screens/catalog/category_products_screen.dart';
import '../screens/mlm/mlm_screen.dart';
import '../screens/mlm/team_tree_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/my_data_screen.dart';
import '../screens/profile/my_orders_screen.dart';
import '../screens/profile/wallet_screen.dart';
import '../screens/misc/compare_screen.dart';
import '../screens/misc/favorites_screen.dart';
import '../screens/misc/info_page_screen.dart';
import '../screens/misc/settings_screen.dart';
import '../screens/product/product_detail_screen.dart';
import '../screens/shop/shop_screen.dart';
import '../screens/splash/splash_screen.dart';
import 'app_routes.dart';

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.main,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ShopScreen()),
                routes: [
                  GoRoute(
                    path: 'notifications',
                    builder: (context, state) =>
                        const NotificationsScreen(),
                  ),
                  GoRoute(
                    path: 'favorites',
                    builder: (context, state) => const FavoritesScreen(),
                  ),
                  GoRoute(
                    path: 'compare',
                    builder: (context, state) => const CompareScreen(),
                  ),
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => const SettingsScreen(),
                  ),
                  GoRoute(
                    path: 'info/about',
                    builder: (context, state) =>
                        const InfoPageScreen(page: InfoPageKey.about),
                  ),
                  GoRoute(
                    path: 'info/delivery',
                    builder: (context, state) =>
                        const InfoPageScreen(page: InfoPageKey.delivery),
                  ),
                  GoRoute(
                    path: 'info/payment',
                    builder: (context, state) =>
                        const InfoPageScreen(page: InfoPageKey.payment),
                  ),
                  GoRoute(
                    path: 'info/returns',
                    builder: (context, state) =>
                        const InfoPageScreen(page: InfoPageKey.returns),
                  ),
                  GoRoute(
                    path: 'info/privacy',
                    builder: (context, state) =>
                        const InfoPageScreen(page: InfoPageKey.privacy),
                  ),
                  GoRoute(
                    path: 'info/support',
                    builder: (context, state) =>
                        const InfoPageScreen(page: InfoPageKey.support),
                  ),
                  GoRoute(
                    path: 'product/:slug',
                    builder: (context, state) {
                      final slug = state.pathParameters['slug'] ?? '';
                      return ProductDetailScreen(slug: slug);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.catalog,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: CatalogScreen()),
                routes: [
                  GoRoute(
                    path: 'category/:slug',
                    builder: (context, state) {
                      final slug = state.pathParameters['slug'] ?? '';
                      final name = state.extra as String?;
                      return CategoryProductsScreen(
                        categorySlug: slug,
                        categoryName: name,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.cart,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: CartScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.mlm,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: MlmScreen()),
                routes: [
                  GoRoute(
                    path: 'tree',
                    builder: (context, state) => const TeamTreeScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ProfileScreen()),
                routes: [
                  GoRoute(
                    path: 'my-data',
                    builder: (context, state) => const MyDataScreen(),
                  ),
                  GoRoute(
                    path: 'my-orders',
                    builder: (context, state) => const MyOrdersScreen(),
                  ),
                  GoRoute(
                    path: 'wallet',
                    builder: (context, state) => const WalletScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.home,
        redirect: (context, state) => AppRoutes.main,
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route error: ${state.error}'),
      ),
    ),
  );
}

