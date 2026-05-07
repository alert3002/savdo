import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/wallet/wallet_controller.dart';
import '../../features/wallet/topup_item.dart';
import '../../features/wallet/withdrawal_item.dart';
import '../../ui/navigation/shop_layer_app_bar.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final _amountCtrl = TextEditingController();
  bool _submitting = false;
  bool _topUpMode = true;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestTopUp() async {
    final token = ref.read(authControllerProvider).accessToken;
    if (token == null || token.isEmpty) return;

    final amount = _amountCtrl.text.trim().replaceAll(',', '.');
    if (amount.isEmpty) return;

    setState(() => _submitting = true);
    try {
      await ref.read(walletRepositoryProvider).requestTopUp(
            bearerToken: token,
            amount: amount,
          );
      _amountCtrl.clear();
      ref.invalidate(topUpsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заявка на пополнение отправлена')),
      );
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await ref.read(authControllerProvider.notifier).logout();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Сессия истекла. Войдите заново.')),
        );
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _requestWithdrawal() async {
    final token = ref.read(authControllerProvider).accessToken;
    if (token == null || token.isEmpty) return;

    final amount = _amountCtrl.text.trim().replaceAll(',', '.');
    if (amount.isEmpty) return;

    setState(() => _submitting = true);
    try {
      await ref.read(walletRepositoryProvider).requestWithdrawal(
            bearerToken: token,
            amount: amount,
          );
      _amountCtrl.clear();
      ref.invalidate(withdrawalsProvider);
      await ref.read(authControllerProvider.notifier).refreshProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заявка на вывод отправлена')),
      );
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await ref.read(authControllerProvider.notifier).logout();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Сессия истекла. Войдите заново.')),
        );
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _statusRu(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'В ожидании';
      case 'APPROVED':
        return 'Подтверждена';
      case 'REJECTED':
        return 'Отклонена';
      default:
        return status;
    }
  }

  String _date(DateTime? dt) {
    if (dt == null) return '-';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$d.$m.$y';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final profile = ref.watch(authControllerProvider).profile;
    final withdrawals = ref.watch(withdrawalsProvider);
    final topups = ref.watch(topUpsProvider);
    final balance = profile?.bonusBalance ?? '0.00';
    final isTopUpMode = _topUpMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Кошелек'),
        actions: shopLayerAppBarActions(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Доступный баланс',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.72),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$balance TJS',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(value: true, label: Text('Пополнить'), icon: Icon(Icons.add_circle_outline)),
              ButtonSegment<bool>(value: false, label: Text('Вывод'), icon: Icon(Icons.south_east)),
            ],
            selected: <bool>{isTopUpMode},
            onSelectionChanged: (s) => setState(() => _topUpMode = s.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: isTopUpMode ? 'Сумма пополнения' : 'Сумма на вывод',
              hintText: 'Например: 100.00',
            ),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: _submitting
                ? null
                : (isTopUpMode ? _requestTopUp : _requestWithdrawal),
            child: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isTopUpMode ? 'Отправить заявку на пополнение' : 'Отправить заявку на вывод'),
          ),
          const SizedBox(height: 18),
          Text(
            isTopUpMode ? 'История пополнений' : 'История выводов',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          (isTopUpMode ? topups : withdrawals).when(
            data: (items) {
              if (items.isEmpty) {
                return const Text('Заявок пока нет.');
              }
              return Column(
                children: items.map((x) {
                  if (x is TopUpItem) {
                    return _TopUpTile(
                      item: x,
                      dateText: _date(x.requestedAt),
                      statusText: _statusRu(x.status),
                    );
                  }
                  final w = x as WithdrawalItem;
                  return _WithdrawalTile(
                    item: w,
                    dateText: _date(w.requestedAt),
                    statusText: _statusRu(w.status),
                  );
                }).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(10),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Ошибка загрузки: $e'),
          ),
        ],
      ),
    );
  }
}

class _TopUpTile extends StatelessWidget {
  const _TopUpTile({
    required this.item,
    required this.dateText,
    required this.statusText,
  });

  final TopUpItem item;
  final String dateText;
  final String statusText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('№ ${item.reference}', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text('${item.amount} ${item.currency}'),
                const SizedBox(height: 3),
                Text(statusText, style: TextStyle(color: scheme.primary)),
              ],
            ),
          ),
          Text(dateText, style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.65))),
        ],
      ),
    );
  }
}

class _WithdrawalTile extends StatelessWidget {
  const _WithdrawalTile({
    required this.item,
    required this.dateText,
    required this.statusText,
  });

  final WithdrawalItem item;
  final String dateText;
  final String statusText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('№ ${item.reference}', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text('${item.amount} ${item.currency}'),
                const SizedBox(height: 3),
                Text(statusText, style: TextStyle(color: scheme.primary)),
              ],
            ),
          ),
          Text(dateText, style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.65))),
        ],
      ),
    );
  }
}

