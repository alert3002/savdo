import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../search/product_search_controller.dart';
import 'auth_models.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  AuthState build() => const AuthState();

  Future<void> restoreSession() async {
    final s = await _repo.loadSavedTokens();
    state = s;
    await _syncPushToken();
  }

  Future<void> login({required String phone, required String password}) async {
    final s = await _repo.login(phone: phone, password: password);
    state = s;
    await _syncPushToken();
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState();
  }

  Future<void> refreshProfile() async {
    final t = state.accessToken;
    if (t == null || t.isEmpty) return;
    final p = await _repo.fetchProfile(t);
    state = state.copyWith(profile: p);
  }

  Future<bool> requestLoginOtp({required String phone}) async {
    return _repo.requestLoginOtp(phone: phone);
  }

  Future<void> loginWithSmsOtp({
    required String phone,
    required String otpCode,
    String? referralCode,
  }) async {
    final next = await _repo.loginWithSmsOtp(
      phone: phone,
      otpCode: otpCode,
      referralCode: referralCode,
    );
    state = next;
    await _syncPushToken();
  }

  /// Синхронизирует адрес в профиле (до/после заказа по желанию).
  Future<void> persistAddress(String address) async {
    final t = state.accessToken;
    if (t == null || t.isEmpty) return;
    final p = await _repo.updateAddress(bearer: t, address: address);
    state = state.copyWith(profile: p);
  }

  Future<void> updateProfileData({
    required String firstName,
    required String lastName,
    required String address,
    String? birthDate,
  }) async {
    final t = state.accessToken;
    if (t == null || t.isEmpty) return;
    final p = await _repo.updateProfile(
      bearer: t,
      firstName: firstName,
      lastName: lastName,
      address: address,
      birthDate: birthDate,
    );
    state = state.copyWith(profile: p);
  }

  Future<void> _syncPushToken() async {
    final bearer = state.accessToken;
    if (bearer == null || bearer.isEmpty) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      final platform = switch (defaultTargetPlatform) {
        TargetPlatform.iOS => 'ios',
        TargetPlatform.android => 'android',
        _ => 'other',
      };
      await _repo.registerPushToken(
        bearer: bearer,
        token: token,
        platform: platform,
      );
    } catch (_) {
      // Ignore push registration failures during auth flow.
    }
  }
}
