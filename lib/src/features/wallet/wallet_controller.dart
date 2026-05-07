import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../auth/auth_controller.dart';
import '../search/product_search_controller.dart' show apiClientProvider;
import 'wallet_repository.dart';
import 'topup_item.dart';
import 'withdrawal_item.dart';

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => WalletRepository(ref.watch(apiClientProvider)),
);

final topUpsProvider = FutureProvider<List<TopUpItem>>((ref) async {
  final token = ref.watch(authControllerProvider).accessToken;
  if (token == null || token.isEmpty) {
    return const [];
  }
  try {
    return ref.read(walletRepositoryProvider).fetchTopUps(bearerToken: token);
  } on ApiException catch (e) {
    if (e.statusCode == 401) {
      await ref.read(authControllerProvider.notifier).logout();
      return const [];
    }
    rethrow;
  }
});

final withdrawalsProvider = FutureProvider<List<WithdrawalItem>>((ref) async {
  final token = ref.watch(authControllerProvider).accessToken;
  if (token == null || token.isEmpty) {
    return const [];
  }
  try {
    return ref.read(walletRepositoryProvider).fetchWithdrawals(bearerToken: token);
  } on ApiException catch (e) {
    if (e.statusCode == 401) {
      await ref.read(authControllerProvider.notifier).logout();
      return const [];
    }
    rethrow;
  }
});

