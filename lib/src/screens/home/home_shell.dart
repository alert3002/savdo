import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/cart/cart_controller.dart';
import '../../features/settings/app_settings.dart';
import '../../ui/navigation/app_shell_scaffold_key.dart';
import '../../ui/navigation/grass_footer_nav.dart';
import '../../ui/navigation/shop_navigation_drawer.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  @override
  Widget build(BuildContext context) {
    final cartCount = ref.watch(cartCountProvider);
    final settings = ref.watch(appSettingsProvider).maybeWhen(
          data: (s) => s,
          orElse: () => null,
        );

    final allowedBranches = <int>[
      0, // main
      if (settings?.showShopFeatures ?? true) ...[1, 2], // catalog, cart
      if (settings?.showMlmFeatures ?? true) 3, // mlm
      4, // profile
    ];

    // If user is currently on a hidden tab, bounce to the first allowed tab.
    final current = widget.navigationShell.currentIndex;
    if (!allowedBranches.contains(current)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.navigationShell.goBranch(allowedBranches.first);
      });
    }

    return Scaffold(
      key: appShellScaffoldKey,
      drawer: const ShopNavigationDrawer(),
      drawerEdgeDragWidth: MediaQuery.sizeOf(context).width * 0.2,
      body: widget.navigationShell,
      bottomNavigationBar: GrassFooterNav(
        navigationShell: widget.navigationShell,
        cartBadgeCount: cartCount,
        allowedBranches: allowedBranches,
      ),
    );
  }
}

