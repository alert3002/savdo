import 'package:shared_preferences/shared_preferences.dart';

import '../../api/api_client.dart';
import 'auth_models.dart';

const _kAccess = 'grass_jwt_access';
const _kRefresh = 'grass_jwt_refresh';

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  Future<AuthState> loadSavedTokens() async {
    final prefs = await SharedPreferences.getInstance();
    final access = prefs.getString(_kAccess);
    final refresh = prefs.getString(_kRefresh);
    if (access == null || access.isEmpty) {
      return const AuthState();
    }
    try {
      final profile = await fetchProfile(access);
      return AuthState(
        accessToken: access,
        refreshToken: refresh,
        profile: profile,
      );
    } catch (_) {
      await clearTokens();
      return const AuthState();
    }
  }

  Future<void> saveTokens({required String access, String? refresh}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccess, access);
    if (refresh != null && refresh.isNotEmpty) {
      await prefs.setString(_kRefresh, refresh);
    }
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccess);
    await prefs.remove(_kRefresh);
  }

  /// JWT: поле [phone] + [password] (как в Django USERNAME_FIELD).
  Future<AuthState> login({
    required String phone,
    required String password,
  }) async {
    final body = await _api.postJson(
      '/api/v1/auth/token/',
      body: {'phone': phone.trim(), 'password': password},
    );
    final access = body['access'] as String?;
    final refresh = body['refresh'] as String?;
    if (access == null || access.isEmpty) {
      throw StateError('Нет access token в ответе');
    }
    await saveTokens(access: access, refresh: refresh);
    final profile = await fetchProfile(access);
    return AuthState(
      accessToken: access,
      refreshToken: refresh,
      profile: profile,
    );
  }

  Future<UserProfile> fetchProfile(String bearer) async {
    final json = await _api.getJson(
      '/api/v1/users/me/',
      bearerToken: bearer,
    );
    return UserProfile.fromJson(json);
  }

  Future<UserProfile> updateAddress({
    required String bearer,
    required String address,
  }) async {
    final json = await _api.patchJson(
      '/api/v1/users/me/',
      body: {'address': address},
      bearerToken: bearer,
    );
    return UserProfile.fromJson(json);
  }

  Future<UserProfile> updateProfile({
    required String bearer,
    required String firstName,
    required String lastName,
    required String address,
    String? birthDate,
  }) async {
    final json = await _api.patchJson(
      '/api/v1/users/me/',
      body: {
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'address': address.trim(),
        'birth_date': (birthDate == null || birthDate.isEmpty) ? null : birthDate,
      },
      bearerToken: bearer,
    );
    return UserProfile.fromJson(json);
  }

  /// SMS OTP барои воридшавӣ.
  Future<bool> requestLoginOtp({required String phone}) async {
    final normalized = phone.trim();
    final json = await _api.postJson(
      '/api/v1/users/request-login-otp/',
      body: {'phone': normalized},
    );
    final isRegistered = json['is_registered'];
    return isRegistered == true;
  }

  /// Бо OTP ворид шудан (SMS login) ва JWT захира кардан.
  Future<AuthState> loginWithSmsOtp({
    required String phone,
    required String otpCode,
    String? referralCode,
  }) async {
    final normalized = phone.trim();
    final code = otpCode.trim();

    final tokens = await _api.postJson(
      '/api/v1/users/verify-login-otp/',
      body: {
        'phone': normalized,
        'otp_code': code,
        if (referralCode != null && referralCode.trim().isNotEmpty)
          'referral_code': referralCode.trim(),
      },
    );

    final access = tokens['access'] as String?;
    final refresh = tokens['refresh'] as String?;
    if (access == null || access.isEmpty) {
      throw StateError('Нет access token в ответе');
    }
    await saveTokens(access: access, refresh: refresh);
    final profile = await fetchProfile(access);
    return AuthState(
      accessToken: access,
      refreshToken: refresh,
      profile: profile,
    );
  }

  Future<void> logout() => clearTokens();

  Future<void> registerPushToken({
    required String bearer,
    required String token,
    required String platform,
  }) async {
    if (bearer.trim().isEmpty || token.trim().isEmpty) return;
    await _api.postJson(
      '/api/v1/users/push-token/',
      bearerToken: bearer,
      body: {
        'token': token.trim(),
        'platform': platform.trim(),
      },
    );
  }
}
