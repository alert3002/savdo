import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/auth/auth_controller.dart';
import '../../features/auth/sms_login_form.dart';
import '../../config/app_config.dart';
import '../../routing/app_routes.dart';
import '../../ui/navigation/shop_layer_app_bar.dart';

class MlmScreen extends ConsumerWidget {
  const MlmScreen({super.key});

  Future<void> _openReferralActionsSheet(
    BuildContext context, {
    required String referralCode,
  }) async {
    final code = referralCode.trim();
    final link = AppConfig.referralLink(code);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Реферальный код',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    code.isEmpty ? '—' : code,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.tonalIcon(
                  onPressed: code.isEmpty
                      ? null
                      : () async {
                          await Clipboard.setData(ClipboardData(text: code));
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Код скопирован')),
                          );
                        },
                  icon: const Icon(Icons.copy_all_outlined),
                  label: const Text('Копировать код'),
                ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: code.isEmpty
                      ? null
                      : () async {
                          await Clipboard.setData(ClipboardData(text: link.toString()));
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Ссылка скопирована')),
                          );
                        },
                  icon: const Icon(Icons.link),
                  label: const Text('Копировать ссылку'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: code.isEmpty
                      ? null
                      : () async {
                          final ok = await launchUrl(
                            link,
                            mode: LaunchMode.externalApplication,
                          );
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                          if (!ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Не удалось открыть ссылку')),
                            );
                          }
                        },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Открыть ссылку'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final auth = ref.watch(authControllerProvider);
    final profile = auth.profile;

    if (!auth.isAuthenticated || profile == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('MLM'),
          actions: shopLayerAppBarActions(context),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Войдите, чтобы открыть кабинет агента.',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 14),
            SmsLoginForm(
              initialPhone: '',
              onVerified: () {
                // Stay on MLM: auth state change will rebuild this screen.
                ref.read(authControllerProvider.notifier).refreshProfile();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Вход выполнен')),
                );
              },
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('MLM'),
        actions: shopLayerAppBarActions(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Кабинет агента',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Реферальный код',
            value: profile.referralCode.isEmpty ? '—' : profile.referralCode,
            icon: Icons.qr_code_2,
            trailing: IconButton(
              onPressed: profile.referralCode.isEmpty
                  ? null
                  : () async {
                      await _openReferralActionsSheet(
                        context,
                        referralCode: profile.referralCode,
                      );
                    },
              icon: const Icon(Icons.copy),
              tooltip: 'Копировать / ссылка',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InfoCard(
                  title: 'Личный оборот',
                  value: '${profile.personalTurnover} TJS',
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoCard(
                  title: 'Командный оборот',
                  value: '${profile.teamTurnover} TJS',
                  icon: Icons.groups,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Дерево команды',
            value: 'Открыть',
            icon: Icons.account_tree,
            trailing: Icon(
              Icons.chevron_right,
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
            onTap: () => context.push(AppRoutes.mlmTeamTree),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Бонусы',
            value: '${profile.bonusBalance} TJS',
            icon: Icons.wallet,
            trailing: Icon(
              Icons.chevron_right,
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
            onTap: () => context.push(AppRoutes.profileWallet),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            trailing ?? const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

