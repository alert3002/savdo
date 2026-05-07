import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../search/product_search_controller.dart' show apiClientProvider;
import 'order_summary.dart';
import 'orders_repository.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => OrdersRepository(ref.watch(apiClientProvider)),
);

final myOrdersProvider = FutureProvider<List<OrderSummary>>((ref) async {
  final auth = ref.watch(authControllerProvider);
  final token = auth.accessToken;
  if (token == null || token.isEmpty) {
    return const [];
  }

  final repo = ref.watch(ordersRepositoryProvider);
  return repo.fetchMyOrders(bearerToken: token);
});

