import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../search/product_search_controller.dart';
import 'checkout_repository.dart';

final checkoutRepositoryProvider = Provider<CheckoutRepository>(
  (ref) => CheckoutRepository(ref.watch(apiClientProvider)),
);
