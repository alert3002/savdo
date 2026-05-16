import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_controller.dart';
import '../engagement/engagement_repository.dart';

/// Шумораи ҳадди аксар барои рӯйхати «сравнение».
const kCompareMaxItems = 4;

final favoriteProductSlugsProvider =
    AsyncNotifierProvider<FavoriteProductSlugsNotifier, Set<String>>(FavoriteProductSlugsNotifier.new);

class FavoriteProductSlugsNotifier extends AsyncNotifier<Set<String>> {
  static const _k = 'favorite_product_slugs';

  @override
  Future<Set<String>> build() async {
    final p = await SharedPreferences.getInstance();
    var local = (p.getStringList(_k) ?? []).toSet();
    ref.listen(authControllerProvider, (prev, next) {
      if (prev?.isAuthenticated != true && next.isAuthenticated) {
        Future.microtask(() async {
          final merged = await _fetchMerged(local);
          state = AsyncData(merged);
        });
      }
    });
    if (ref.read(authControllerProvider).isAuthenticated) {
      local = await _fetchMerged(local);
    }
    return local;
  }

  Future<Set<String>> _fetchMerged(Set<String> local) async {
    final bearer = ref.read(authControllerProvider).accessToken;
    if (bearer == null || bearer.isEmpty) return local;
    try {
      final data = await ref.read(engagementRepositoryProvider).fetchClientData(bearer);
      final remote = _parseSlugList(data['favorite_slugs']);
      final merged = {...local, ...remote};
      final p = await SharedPreferences.getInstance();
      await p.setStringList(_k, merged.toList());
      await _pushToServer(merged);
      return merged;
    } catch (_) {
      return local;
    }
  }

  Set<String> _parseSlugList(Object? raw) {
    if (raw is! List) return {};
    return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toSet();
  }

  Future<void> _pushToServer(Set<String> slugs) async {
    final bearer = ref.read(authControllerProvider).accessToken;
    if (bearer == null || bearer.isEmpty) return;
    try {
      await ref.read(engagementRepositoryProvider).patchClientData(
            bearer: bearer,
            payload: ClientDataPayload(favoriteSlugs: slugs.toList(growable: false)),
          );
    } catch (_) {}
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
    await _pushToServer(next);
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
    var local = p.getStringList(_k) ?? [];
    ref.listen(authControllerProvider, (prev, next) {
      if (prev?.isAuthenticated != true && next.isAuthenticated) {
        Future.microtask(() async {
          final merged = await _fetchMerged(local);
          state = AsyncData(merged);
        });
      }
    });
    if (ref.read(authControllerProvider).isAuthenticated) {
      local = await _fetchMerged(local);
    }
    return local;
  }

  Future<List<String>> _fetchMerged(List<String> local) async {
    final bearer = ref.read(authControllerProvider).accessToken;
    if (bearer == null || bearer.isEmpty) return local;
    try {
      final data = await ref.read(engagementRepositoryProvider).fetchClientData(bearer);
      final remote = (data['compare_slugs'] is List)
          ? (data['compare_slugs'] as List).map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : <String>[];
      var merged = <String>{...local, ...remote}.toList();
      if (merged.length > kCompareMaxItems) {
        merged = merged.sublist(merged.length - kCompareMaxItems);
      }
      final p = await SharedPreferences.getInstance();
      await p.setStringList(_k, merged);
      await _pushToServer(merged);
      return merged;
    } catch (_) {
      return local;
    }
  }

  Future<void> _pushToServer(List<String> slugs) async {
    final bearer = ref.read(authControllerProvider).accessToken;
    if (bearer == null || bearer.isEmpty) return;
    try {
      await ref.read(engagementRepositoryProvider).patchClientData(
            bearer: bearer,
            payload: ClientDataPayload(compareSlugs: slugs),
          );
    } catch (_) {}
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
      await _pushToServer(current);
      return true;
    }
    if (current.length >= kCompareMaxItems) {
      return false;
    }
    current.add(slug);
    state = AsyncData(current);
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_k, current);
    await _pushToServer(current);
    return true;
  }
}
