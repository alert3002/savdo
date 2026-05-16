import '../../api/api_client.dart';
import 'slider_item.dart';

class SliderRepository {
  SliderRepository(this._api);
  final ApiClient _api;

  Future<List<SliderItem>> fetchActive() async {
    final raw = await _api.getJsonAny('/api/v1/slider/');
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(SliderItem.fromJson)
          .toList(growable: false);
    }
    if (raw is Map<String, dynamic>) {
      final results = raw['results'];
      if (results is List) {
        return results
            .whereType<Map<String, dynamic>>()
            .map(SliderItem.fromJson)
            .toList(growable: false);
      }
      if (raw.containsKey('id')) {
        return [SliderItem.fromJson(raw)];
      }
    }
    return const [];
  }
}
