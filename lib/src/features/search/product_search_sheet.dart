import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../products/product_summary.dart';
import 'product_search_controller.dart';

Future<void> showProductSearchSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (context) {
      return const _ProductSearchSheet();
    },
  );
}

class _ProductSearchSheet extends ConsumerStatefulWidget {
  const _ProductSearchSheet();

  @override
  ConsumerState<_ProductSearchSheet> createState() => _ProductSearchSheetState();
}

class _ProductSearchSheetState extends ConsumerState<_ProductSearchSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(productSearchControllerProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          top: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              onChanged: (v) => ref.read(productSearchControllerProvider.notifier).setQuery(v),
              decoration: InputDecoration(
                hintText: 'Поиск товара...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () {
                    _controller.clear();
                    ref.read(productSearchControllerProvider.notifier).setQuery('');
                  },
                  icon: const Icon(Icons.close),
                  tooltip: 'Очистить',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: _Results(state: state, surface: scheme.surfaceContainerHighest),
            ),
          ],
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.state, required this.surface});

  final ProductSearchState state;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    if (state is ProductSearchIdle) {
      if (state.query.isEmpty) {
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Наберите минимум 3 буквы для поиска.',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.70),
            ),
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          'Введите ещё ${3 - state.query.length} символ(а)...',
          style: textTheme.bodyMedium?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.70),
          ),
        ),
      );
    }

    if (state is ProductSearchLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ProductSearchError) {
      return Text(
        (state as ProductSearchError).message,
        style: textTheme.bodyMedium?.copyWith(color: scheme.error),
      );
    }

    final data = state as ProductSearchData;
    if (data.items.isEmpty) {
      return Text(
        'Ничего не найдено.',
        style: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurface.withValues(alpha: 0.70),
        ),
      );
    }

    return ListView.separated(
      itemCount: data.items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _ProductRow(item: data.items[index]),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.item});
  final ProductSummary item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {},
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.local_car_wash_outlined, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.categoryName ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.70),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${item.effectivePrice} ${item.currency}',
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

