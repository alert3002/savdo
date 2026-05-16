import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_controller.dart';
import '../../features/mlm/mlm_repository.dart';
import 'mlm_screen.dart' show mlmRepositoryProvider;
import '../../ui/error_retry.dart';
import '../../ui/navigation/shop_layer_app_bar.dart';

final bonusesListProvider = FutureProvider<List<BonusItem>>((ref) async {
  final bearer = ref.watch(authControllerProvider).accessToken;
  if (bearer == null || bearer.isEmpty) return const [];
  return ref.watch(mlmRepositoryProvider).fetchBonuses(bearer: bearer);
});

class MlmBonusesScreen extends ConsumerWidget {
  const MlmBonusesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final async = ref.watch(bonusesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('История бонусов'),
        actions: shopLayerAppBarActions(context),
      ),
      body: async.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Text(
                'Пока нет начислений',
                style: textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(bonusesListProvider);
              await ref.read(bonusesListProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final b = items[i];
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.35)),
                  ),
                  tileColor: scheme.surfaceContainerHighest.withValues(alpha: 0.25),
                  title: Text(
                    '${b.amount} TJS • ${b.bonusType}',
                    style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text('Уровень ${b.level} • ${b.status}'),
                  trailing: Text(
                    b.createdAt?.substring(0, 10) ?? '',
                    style: textTheme.bodySmall,
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetryPanel(
          message: friendlyErrorMessage(e),
          onRetry: () => ref.invalidate(bonusesListProvider),
        ),
      ),
    );
  }
}
