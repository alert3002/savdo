import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ApiClient {
  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  static const Duration _timeout = Duration(seconds: 45);

  Future<http.Response> _get(Uri uri, Map<String, String> headers) =>
      _http.get(uri, headers: headers).timeout(_timeout);

  Future<http.Response> _post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) =>
      _http
          .post(uri, headers: headers, body: body)
          .timeout(_timeout);

  Future<http.Response> _patch(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) =>
      _http
          .patch(uri, headers: headers, body: body)
          .timeout(_timeout);

  Future<Object?> getJsonAny(
    String path, {
    Map<String, String>? query,
    Map<String, String>? headers,
    String? bearerToken,
  }) async {
    final uri = AppConfig.apiUri(path, query);
    final h = <String, String>{
      'accept': 'application/json',
      ...?headers,
    };
    if (bearerToken != null && bearerToken.isNotEmpty) {
      h['Authorization'] = 'Bearer $bearerToken';
    }
    final resp = await _get(uri, h);
    final body = utf8.decode(resp.bodyBytes);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw ApiException(resp.statusCode, body);
    }
    if (body.trim().isEmpty) return null;
    return jsonDecode(body);
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
    Map<String, String>? headers,
    String? bearerToken,
  }) async {
    final uri = AppConfig.apiUri(path, query);
    final h = <String, String>{
      'accept': 'application/json',
      ...?headers,
    };
    if (bearerToken != null && bearerToken.isNotEmpty) {
      h['Authorization'] = 'Bearer $bearerToken';
    }
    final resp = await _get(uri, h);
    final body = utf8.decode(resp.bodyBytes);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw ApiException(resp.statusCode, body);
    }
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw ApiException(resp.statusCode, 'Unexpected response shape');
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, String>? query,
    Map<String, String>? headers,
    Object? body,
    String? bearerToken,
  }) async {
    final uri = AppConfig.apiUri(path, query);
    final h = <String, String>{
      'accept': 'application/json',
      'content-type': 'application/json',
      ...?headers,
    };
    if (bearerToken != null && bearerToken.isNotEmpty) {
      h['Authorization'] = 'Bearer $bearerToken';
    }
    final resp = await _post(
      uri,
      headers: h,
      body: body == null ? null : jsonEncode(body),
    );
    final respBody = utf8.decode(resp.bodyBytes);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw ApiException(resp.statusCode, respBody);
    }
    if (respBody.trim().isEmpty) return const <String, dynamic>{};
    final decoded = jsonDecode(respBody);
    if (decoded is Map<String, dynamic>) return decoded;
    return const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, String>? headers,
    Object? body,
    String? bearerToken,
  }) async {
    final uri = AppConfig.apiUri(path);
    final h = <String, String>{
      'accept': 'application/json',
      'content-type': 'application/json',
      ...?headers,
    };
    if (bearerToken != null && bearerToken.isNotEmpty) {
      h['Authorization'] = 'Bearer $bearerToken';
    }
    final resp = await _patch(
      uri,
      headers: h,
      body: body == null ? null : jsonEncode(body),
    );
    final respBody = utf8.decode(resp.bodyBytes);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw ApiException(resp.statusCode, respBody);
    }
    if (respBody.trim().isEmpty) return const <String, dynamic>{};
    final decoded = jsonDecode(respBody);
    if (decoded is Map<String, dynamic>) return decoded;
    return const <String, dynamic>{};
  }
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.body);
  final int statusCode;
  final String body;

  @override
  String toString() => 'ApiException($statusCode): $body';
}

