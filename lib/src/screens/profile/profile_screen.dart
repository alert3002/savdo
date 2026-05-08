import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_client.dart';
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
            const SizedBox(height: 16),
            _DestructiveTile(
              title: 'Удалить аккаунт',
              subtitle: 'Безвозвратно: данные профиля и вход по этому номеру',
              onTap: () => _confirmDeleteAccount(context, ref),
            ),
          ],
        ],
      ),
    );
  }
}

String _apiErrorMessage(Object error) {
  if (error is ApiException) {
    try {
      final decoded = jsonDecode(error.body);
      if (decoded is Map<String, dynamic>) {
        final d = decoded['detail'];
        if (d is String && d.isNotEmpty) return d;
      }
    } catch (_) {}
    if (error.body.trim().isNotEmpty) return error.body.trim();
  }
  return error.toString();
}

Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
  final scheme = Theme.of(context).colorScheme;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Удалить аккаунт?'),
      content: const Text(
        'Аккаунт будет закрыт: личные данные и номер телефона удалятся с сервера, '
        'войти снова с этим номером можно будет только как с новым пользователем. '
        'История заказов в системе может сохраняться без персональных данных.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(foregroundColor: scheme.error),
          child: const Text('Удалить'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;

  try {
    await ref.read(authControllerProvider.notifier).deleteAccount();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Аккаунт удалён')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_apiErrorMessage(e))),
      );
    }
  }
}

class _DestructiveTile extends StatelessWidget {
  const _DestructiveTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final error = scheme.error;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: error.withValues(alpha: 0.45)),
        ),
        child: Row(
          children: [
            Icon(Icons.delete_forever_outlined, color: error),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: error,
                    ),
                  ),
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
