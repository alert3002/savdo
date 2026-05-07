import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../products/product_detail.dart';
import 'cart_models.dart';

final cartControllerProvider = NotifierProvider<CartController, List<CartItem>>(
  CartController.new,
);

final cartCountProvider = Provider<int>((ref) {
  final items = ref.watch(cartControllerProvider);
  return items.fold<int>(0, (sum, i) => sum + i.qty);
});

class CartController extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => const [];

  void addProduct(
    ProductDetail p, {
    required int qty,
    String? variantSku,
    String? variantId,
    String? variantLabel,
    String? unitPrice,
  }) {
    final newItem = CartItem.fromProduct(
      p,
      qty: qty,
      variantSku: variantSku,
      variantId: variantId,
      variantLabel: variantLabel,
      unitPrice: unitPrice,
    );
    final key = newItem.key;
    final idx = state.indexWhere((e) => e.key == key);
    if (idx == -1) {
      state = [...state, newItem];
    } else {
      final existing = state[idx];
      final updated = existing.copyWith(qty: existing.qty + qty);
      final copy = [...state];
      copy[idx] = updated;
      state = copy;
    }
  }

  void setQty(String key, int qty) {
    if (qty <= 0) {
      state = state.where((e) => e.key != key).toList(growable: false);
      return;
    }
    final idx = state.indexWhere((e) => e.key == key);
    if (idx == -1) return;
    final copy = [...state];
    copy[idx] = copy[idx].copyWith(qty: qty);
    state = copy;
  }

  void clear() => state = const [];
}

