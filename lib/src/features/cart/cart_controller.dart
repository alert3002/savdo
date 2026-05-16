import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../engagement/engagement_repository.dart';
import '../products/product_detail.dart';
import 'cart_models.dart';
import 'cart_storage.dart';

final cartControllerProvider = NotifierProvider<CartController, List<CartItem>>(
  CartController.new,
);

final cartCountProvider = Provider<int>((ref) {
  final items = ref.watch(cartControllerProvider);
  return items.fold<int>(0, (sum, i) => sum + i.qty);
});

class CartController extends Notifier<List<CartItem>> {
  Timer? _saveDebounce;
  bool _hydrated = false;

  @override
  List<CartItem> build() {
    if (!_hydrated) {
      _hydrated = true;
      Future.microtask(_hydrate);
    }
    ref.listen(authControllerProvider, (prev, next) {
      if (prev?.isAuthenticated != true && next.isAuthenticated) {
        Future.microtask(_mergeFromServer);
      }
    });
    return const [];
  }

  Future<void> _hydrate() async {
    final local = await CartStorage.load();
    if (local.isNotEmpty) state = local;
    final auth = ref.read(authControllerProvider);
    if (auth.isAuthenticated) await _mergeFromServer();
  }

  Future<void> _mergeFromServer() async {
    final bearer = ref.read(authControllerProvider).accessToken;
    if (bearer == null || bearer.isEmpty) return;
    try {
      final repo = ref.read(engagementRepositoryProvider);
      final data = await repo.fetchClientData(bearer);
      final remoteCart = data['cart'];
      if (remoteCart is! List || remoteCart.isEmpty) {
        await _pushToServer();
        return;
      }
      final remoteItems = remoteCart
          .whereType<Map>()
          .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.slug.isNotEmpty)
          .toList(growable: false);
      if (remoteItems.isEmpty) return;
      if (state.isEmpty) {
        state = remoteItems;
      } else {
        final merged = <String, CartItem>{};
        for (final i in remoteItems) {
          merged[i.key] = i;
        }
        for (final i in state) {
          merged[i.key] = i;
        }
        state = merged.values.toList(growable: false);
      }
      await CartStorage.save(state);
    } catch (_) {}
  }

  void _schedulePersist() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 400), () async {
      await CartStorage.save(state);
      await _pushToServer();
    });
  }

  Future<void> _pushToServer() async {
    final bearer = ref.read(authControllerProvider).accessToken;
    if (bearer == null || bearer.isEmpty) return;
    try {
      await ref.read(engagementRepositoryProvider).patchClientData(
            bearer: bearer,
            payload: ClientDataPayload(
              cart: state.map((e) => e.toJson()).toList(growable: false),
            ),
          );
    } catch (_) {}
  }

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
    _schedulePersist();
  }

  void setQty(String key, int qty) {
    if (qty <= 0) {
      state = state.where((e) => e.key != key).toList(growable: false);
      _schedulePersist();
      return;
    }
    final idx = state.indexWhere((e) => e.key == key);
    if (idx == -1) return;
    final copy = [...state];
    copy[idx] = copy[idx].copyWith(qty: qty);
    state = copy;
    _schedulePersist();
  }

  void clear() {
    state = const [];
    _schedulePersist();
  }
}
