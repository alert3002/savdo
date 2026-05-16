import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../search/product_search_controller.dart' show apiClientProvider;
import 'slider_item.dart';
import 'slider_repository.dart';

final sliderRepositoryProvider = Provider<SliderRepository>(
  (ref) => SliderRepository(ref.watch(apiClientProvider)),
);

final sliderItemsProvider = FutureProvider<List<SliderItem>>((ref) async {
  final repo = ref.watch(sliderRepositoryProvider);
  return repo.fetchActive();
});
