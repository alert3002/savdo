import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_controller.dart';
import '../../features/orders/order_detail.dart';
import '../../features/orders/order_summary.dart';
import '../../features/orders/orders_controller.dart';
import '../../ui/navigation/shop_layer_app_bar.dart';

class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
  final Set<String> _cancellingOrderIds = <String>{};

  Future<void> _showProductsSheet(OrderSummary order) async {
    final token = ref.read(authControllerProvider).accessToken;
    if (token == null || token.isEmpty) return;

    final repo = ref.read(ordersRepositoryProvider);
    final detail = await repo.fetchOrderDetail(
      bearerToken: token,
      orderId: order.id,
    );

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Товары заказа',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          Text(
                            'Заказ ${order.id.split('-').first.toUpperCase()}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.72),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (detail.items.isEmpty)
                  const Text('В этом заказе нет товаров.')
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: detail.items.length,
                      separatorBuilder: (context, index) => const Divider(height: 14),
                      itemBuilder: (context, index) {
                        final item = detail.items[index];
                        return _OrderItemRow(item: item);
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _cancelOrder(OrderSummary order) async {
    final token = ref.read(authControllerProvider).accessToken;
    if (token == null || token.isEmpty) return;

    setState(() => _cancellingOrderIds.add(order.id));
    try {
      await ref.read(ordersRepositoryProvider).cancelOrder(
            bearerToken: token,
            orderId: order.id,
          );
      ref.invalidate(myOrdersProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заказ отменен')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка отмены: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _cancellingOrderIds.remove(order.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final asyncOrders = ref.watch(myOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои заказы'),
        actions: shopLayerAppBarActions(context),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myOrdersProvider);
          await ref.read(myOrdersProvider.future);
        },
        child: asyncOrders.when(
          data: (orders) {
            if (orders.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'У вас пока нет заказов.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.75),
                        ),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final order = orders[index];
                return _OrderTile(
                  order: order,
                  isCancelling: _cancellingOrderIds.contains(order.id),
                  onViewProducts: () => _showProductsSheet(order),
                  onCancel: () => _cancelOrder(order),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Ошибка загрузки заказов: $e',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.error,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({
    required this.order,
    required this.isCancelling,
    required this.onViewProducts,
    required this.onCancel,
  });

  final OrderSummary order;
  final bool isCancelling;
  final VoidCallback onViewProducts;
  final VoidCallback onCancel;

  String _statusText(String status) {
    switch (status.toUpperCase()) {
      case 'CREATED':
        return 'Создан';
      case 'CONFIRMED':
        return 'Подтвержден';
      case 'RESERVED':
        return 'Забронирован';
      case 'SHIPPED':
        return 'Отправлен';
      case 'DELIVERED':
        return 'Доставлен';
      case 'CANCELLED':
        return 'Отменен';
      default:
        return status;
    }
  }

  String _dateText(DateTime? dt) {
    if (dt == null) return '-';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$d.$m.$y';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final statusText = _statusText(order.status);
    final grand = order.grandTotal.isEmpty ? '-' : order.grandTotal;
    final currency = order.currency.isEmpty ? '' : ' ${order.currency}';
    final idNumber = order.id.split('-').first.toUpperCase();
    final isCreated = order.status.toUpperCase() == 'CREATED';

    return Ink(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Заказ $idNumber',
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                _dateText(order.createdAt),
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            statusText,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Сумма: $grand$currency',
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: onViewProducts,
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('Товары заказа'),
              ),
              if (isCreated)
                OutlinedButton(
                  onPressed: isCancelling ? null : onCancel,
                  child: isCancelling
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Отменить'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});

  final OrderItemLine item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final variantLabel = item.variantSku != null && item.variantSku!.isNotEmpty
        ? 'SKU: ${item.variantSku}'
        : (item.variantId.isNotEmpty ? 'Variant: ${item.variantId}' : null);
    final unitPrice = item.unitPrice.isEmpty ? '-' : item.unitPrice;
    final lineTotal = item.lineTotal.isEmpty ? '-' : item.lineTotal;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.productName.isEmpty ? 'Товар' : item.productName,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (variantLabel != null) ...[
            const SizedBox(height: 4),
            Text(
              variantLabel,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              Text(
                'Кол-во: x${item.quantity}',
                style: textTheme.bodySmall,
              ),
              Text(
                'Цена: $unitPrice TJS',
                style: textTheme.bodySmall,
              ),
              Text(
                'Итого: $lineTotal TJS',
                style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

