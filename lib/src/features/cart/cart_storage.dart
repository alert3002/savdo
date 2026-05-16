import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'cart_models.dart';

const _kCartItems = 'grass_cart_items_v1';

class CartStorage {
  static Future<List<CartItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCartItems);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return list
          .whereType<Map>()
          .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  static Future<void> save(List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_kCartItems, encoded);
  }
}
