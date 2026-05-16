import '../../api/api_client.dart';

class BonusItem {
  const BonusItem({
    required this.id,
    required this.level,
    required this.bonusType,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final int level;
  final String bonusType;
  final String amount;
  final String status;
  final String? createdAt;

  factory BonusItem.fromJson(Map<String, dynamic> json) => BonusItem(
        id: (json['id'] ?? '').toString(),
        level: json['level'] is int ? json['level'] as int : int.tryParse('${json['level']}') ?? 0,
        bonusType: (json['bonus_type'] ?? '').toString(),
        amount: (json['amount'] ?? '0').toString(),
        status: (json['status'] ?? '').toString(),
        createdAt: json['created_at'] as String?,
      );
}

class StatusThresholdItem {
  const StatusThresholdItem({
    required this.status,
    required this.minPersonal,
    required this.minTeam,
  });

  final String status;
  final String minPersonal;
  final String minTeam;

  factory StatusThresholdItem.fromJson(Map<String, dynamic> json) => StatusThresholdItem(
        status: (json['status'] ?? '').toString(),
        minPersonal: (json['min_personal_turnover'] ?? '0').toString(),
        minTeam: (json['min_team_turnover'] ?? '0').toString(),
      );
}

class MlmRepository {
  MlmRepository(this._api);
  final ApiClient _api;

  Future<List<BonusItem>> fetchBonuses({
    required String bearer,
    int page = 1,
    int pageSize = 30,
  }) async {
    final json = await _api.getJson(
      '/api/v1/bonuses/',
      bearerToken: bearer,
      query: {'page': '$page', 'page_size': '$pageSize'},
    );
    final results = json['results'];
    if (results is! List) return const [];
    return results
        .whereType<Map<String, dynamic>>()
        .map(BonusItem.fromJson)
        .toList(growable: false);
  }

  Future<List<StatusThresholdItem>> fetchThresholds({required String bearer}) async {
    final raw = await _api.getJsonAny('/api/v1/mlm/thresholds/', bearerToken: bearer);
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(StatusThresholdItem.fromJson)
          .toList(growable: false);
    }
    if (raw is Map<String, dynamic>) {
      final results = raw['results'];
      if (results is List) {
        return results
            .whereType<Map<String, dynamic>>()
            .map(StatusThresholdItem.fromJson)
            .toList(growable: false);
      }
    }
    return const [];
  }
}
