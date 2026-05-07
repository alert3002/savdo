import 'package:flutter/foundation.dart';

class AppConfig {
  /// Якбора аз муҳити иҷро: `--dart-define=API_BASE_URL=https://savdo.tech`
  /// ё барои компи ҷойгир: `--dart-define=API_BASE_URL=http://192.168.1.5:8003`
  static const String apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

  /// Пешфарз: `https://savdo.tech` (web ва мобил, ҳам debug, ҳам release).
  /// Чаро: Android debug дар телефони воқеӣ бо `10.0.2.2` кор намекунад; насби APK аксар вақт
  /// ҳамон мушкилро медиҳад. Барои эмулятор/локал: `--dart-define=API_BASE_URL=http://10.0.2.2:8000`
  static String get apiBaseUrl {
    if (apiBaseUrlOverride.trim().isNotEmpty) {
      return apiBaseUrlOverride.trim().replaceAll(RegExp(r'\/+$'), '');
    }
    if (kIsWeb) {
      return 'https://savdo.tech';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'https://savdo.tech';
    }
    // iOS/macOS simulator — одатан backend дар Mac
    if (kReleaseMode || kProfileMode) {
      return 'https://savdo.tech';
    }
    return 'http://127.0.0.1:8000';
  }

  /// Public website used in referral links shared with clients.
  /// Change this to your production domain later.
  static const String publicBaseUrl = String.fromEnvironment(
    'PUBLIC_BASE_URL',
    defaultValue: 'https://savdo.tech',
  );

  static Uri apiUri(String path, [Map<String, String>? query]) {
    final base = Uri.parse(apiBaseUrl);
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: path.startsWith('/') ? path : '/$path',
      queryParameters: query,
    );
  }

  /// Normalize media/image URL from API:
  /// - relative `/media/...` -> absolute using api host
  /// - protocol-relative `//host/path` -> with current scheme
  /// - `http://<same-host>/...` -> upgrade to https in production
  static String? normalizeMediaUrl(String? raw) {
    final s = (raw ?? '').trim();
    if (s.isEmpty) return null;
    final base = Uri.parse(apiBaseUrl);

    if (s.startsWith('//')) {
      return '${base.scheme}:$s';
    }
    if (s.startsWith('/')) {
      return Uri(
        scheme: base.scheme,
        host: base.host,
        port: base.hasPort ? base.port : null,
        path: s,
      ).toString();
    }

    final u = Uri.tryParse(s);
    if (u == null) return s;
    if (!u.hasScheme || u.host.isEmpty) {
      return Uri(
        scheme: base.scheme,
        host: base.host,
        port: base.hasPort ? base.port : null,
        path: s.startsWith('/') ? s : '/$s',
      ).toString();
    }
    if (u.scheme == 'http' && u.host == base.host) {
      return u.replace(scheme: base.scheme, port: base.hasPort ? base.port : null).toString();
    }
    return s;
  }

  /// Link that can be shared with clients. For now it's a web landing link
  /// with `?ref=CODE`. Later you can enable deep links and route it in-app.
  static Uri referralLink(String referralCode) {
    final code = referralCode.trim();
    final base = Uri.parse(publicBaseUrl);
    if (code.isEmpty) return base;
    return base.replace(queryParameters: {'ref': code});
  }
}

