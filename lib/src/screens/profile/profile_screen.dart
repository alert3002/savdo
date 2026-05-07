import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../brand/brand_assets.dart';
import '../../ui/navigation/shop_layer_app_bar.dart';
import '../../features/auth/sms_login_form.dart';
import '../../features/auth/auth_controller.dart';
import '../../routing/app_routes.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final logo = isDark ? BrandAssets.logoWhiteHorizontal : BrandAssets.logoBlackHorizontal;
    final auth = ref.watch(authControllerProvider);
    final profile = auth.profile;

    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Профиль'),
          actions: shopLayerAppBarActions(context),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          logo,
                          width: 200,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 16),
                        SmsLoginForm(
                          initialPhone: '',
                          onVerified: () {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Вход выполнен')),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Войдите по SMS, чтобы открыть данные профиля и историю заказов.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.72),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: shopLayerAppBarActions(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Image.asset(
              logo,
              width: 200,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 16),
          if (auth.isAuthenticated && profile != null) ...[
            ListTile(
              title: Text(profile.phone, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('${profile.firstName} ${profile.lastName}'.trim()),
            ),
            const Divider(),
          ],
          if (auth.isAuthenticated) ...[
            _Tile(
              icon: Icons.person,
              title: 'Мои данные',
              subtitle: (profile?.address.isEmpty ?? true) ? 'Адрес не указан' : profile!.address,
              onTap: () => context.push(AppRoutes.profileMyData),
            ),
            const SizedBox(height: 10),
            _Tile(
              icon: Icons.receipt_long,
              title: 'Мои заказы',
              subtitle: 'История покупок',
              onTap: () => context.push(AppRoutes.profileMyOrders),
            ),
            const SizedBox(height: 10),
            _Tile(
              icon: Icons.wallet,
              title: 'Кошелек',
              subtitle: 'Баланс: ${(profile?.bonusBalance ?? '0.00')} TJS • вывод средств',
              onTap: () => context.push(AppRoutes.profileWallet),
            ),
            const SizedBox(height: 10),
            _Tile(
              icon: Icons.tune,
              title: 'Настройки',
              subtitle: 'Язык, уведомления',
              onTap: () => context.push(AppRoutes.settings),
            ),
            const SizedBox(height: 10),
            _Tile(
              icon: Icons.logout,
              title: 'Выйти',
              subtitle: 'Сменить аккаунт',
              onTap: () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Вы вышли')),
                  );
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: scheme.onSurface.withValues(alpha: 0.35)),
          ],
        ),
      ),
    );
  }
}
