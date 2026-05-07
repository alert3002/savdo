import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Шумораи ҳадди аксар барои рӯйхати «сравнение».
const kCompareMaxItems = 4;

final favoriteProductSlugsProvider =
    AsyncNotifierProvider<FavoriteProductSlugsNotifier, Set<String>>(FavoriteProductSlugsNotifier.new);

class FavoriteProductSlugsNotifier extends AsyncNotifier<Set<String>> {
  static const _k = 'favorite_product_slugs';

  @override
  Future<Set<String>> build() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_k) ?? []).toSet();
  }

  Future<void> toggle(String slug) async {
    if (slug.isEmpty) return;
    final current = state.maybeWhen(
      data: (s) => s,
      orElse: () => <String>{},
    );
    final next = {...current};
    if (next.contains(slug)) {
      next.remove(slug);
    } else {
      next.add(slug);
    }
    state = AsyncData(next);
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_k, next.toList());
  }
}

final compareProductSlugsProvider =
    AsyncNotifierProvider<CompareProductSlugsNotifier, List<String>>(CompareProductSlugsNotifier.new);

/// Тартиб нигоҳ дошта мешавад (аввалин иловашуда = қадимтар).
class CompareProductSlugsNotifier extends AsyncNotifier<List<String>> {
  static const _k = 'compare_product_slugs';

  @override
  Future<List<String>> build() async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList(_k) ?? [];
  }

  /// `true` агар тағйир дода шуд, `false` агар ҳад пур бошад ва илова нашуд.
  Future<bool> toggle(String slug) async {
    if (slug.isEmpty) return false;
    final current = List<String>.from(
      state.maybeWhen(data: (s) => s, orElse: () => const []),
    );
    final idx = current.indexOf(slug);
    if (idx >= 0) {
      current.removeAt(idx);
      state = AsyncData(current);
      final p = await SharedPreferences.getInstance();
      await p.setStringList(_k, current);
      return true;
    }
    if (current.length >= kCompareMaxItems) {
      return false;
    }
    current.add(slug);
    state = AsyncData(current);
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_k, current);
    return true;
  }
}
