import '../../api/api_client.dart';
import 'topup_item.dart';
import 'withdrawal_item.dart';

class WalletRepository {
  WalletRepository(this._api);

  final ApiClient _api;

  Future<List<TopUpItem>> fetchTopUps({
    required String bearerToken,
  }) async {
    final json = await _api.getJson(
      '/api/v1/topups/',
      bearerToken: bearerToken,
      query: const {'page_size': '50'},
    );
    final results = json['results'];
    if (results is! List) return const [];
    return results
        .whereType<Map<String, dynamic>>()
        .map(TopUpItem.fromJson)
        .toList(growable: false);
  }

  Future<void> requestTopUp({
    required String bearerToken,
    required String amount,
  }) async {
    await _api.postJson(
      '/api/v1/topups/',
      bearerToken: bearerToken,
      body: {
        'amount': amount,
      },
    );
  }

  Future<List<WithdrawalItem>> fetchWithdrawals({
    required String bearerToken,
  }) async {
    final json = await _api.getJson(
      '/api/v1/withdrawals/',
      bearerToken: bearerToken,
      query: const {'page_size': '50'},
    );
    final results = json['results'];
    if (results is! List) return const [];
    return results
        .whereType<Map<String, dynamic>>()
        .map(WithdrawalItem.fromJson)
        .toList(growable: false);
  }

  Future<void> requestWithdrawal({
    required String bearerToken,
    required String amount,
  }) async {
    await _api.postJson(
      '/api/v1/withdrawals/',
      bearerToken: bearerToken,
      body: {
        'amount': amount,
      },
    );
  }
}

