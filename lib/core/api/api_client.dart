import 'dart:async';

import 'package:dio/dio.dart';

import '../config.dart';
import '../storage/token_store.dart';
import 'api_exception.dart';

/// The single HTTP layer for every network call in the app.
///
/// - Injects the bearer token on every request.
/// - Transparent refresh-on-401 with a single-flight refresh (the backend
///   rotates refresh tokens, so parallel refreshes would invalidate each
///   other) — mirrors `GH-Web/src/lib/api/http.ts`.
class ApiClient {
  ApiClient(this._tokens) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      // We map error payloads ourselves; let all statuses through.
      validateStatus: (_) => true,
    ));
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      final token = _tokens.access;
      if (token != null && options.headers['Authorization'] == null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    }));
  }

  final TokenStore _tokens;
  late final Dio _dio;

  /// Fired when the session is irrecoverably dead (refresh failed).
  void Function()? onSessionExpired;

  Completer<bool>? _refreshInFlight;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) =>
      _request('GET', path, query: query);

  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    FormData? form,
  }) =>
      _request('POST', path, body: form ?? body);

  Future<Map<String, dynamic>> put(String path, {Object? body}) =>
      _request('PUT', path, body: body);

  Future<Map<String, dynamic>> patch(String path, {Object? body}) =>
      _request('PATCH', path, body: body);

  Future<Map<String, dynamic>> delete(String path) => _request('DELETE', path);

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool isRetry = false,
  }) async {
    Response<dynamic> response;
    try {
      response = await _dio.request(
        path,
        data: body,
        queryParameters: query,
        options: Options(method: method),
      );
    } on DioException catch (err) {
      throw ApiException(0, 'Cannot reach the Gyan Hub server ($err)');
    }

    final status = response.statusCode ?? 0;
    final payload = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : <String, dynamic>{};

    if (status == 401 && !isRetry && _tokens.refresh != null) {
      final refreshed = await _refreshTokens();
      if (refreshed) {
        return _request(method, path, body: body, query: query, isRetry: true);
      }
      await _tokens.clear();
      onSessionExpired?.call();
    }

    if (status >= 400 || payload['success'] == false) {
      throw ApiException(
        status,
        (payload['message'] as String?) ?? 'Request failed ($status)',
      );
    }
    return payload;
  }

  Future<bool> _refreshTokens() async {
    if (_refreshInFlight != null) return _refreshInFlight!.future;
    final completer = Completer<bool>();
    _refreshInFlight = completer;
    try {
      final refresh = _tokens.refresh;
      if (refresh == null) {
        completer.complete(false);
      } else {
        final res = await _dio.post(
          '/auth/refresh-token',
          data: {'refreshToken': refresh},
          options: Options(headers: {'Authorization': null}),
        );
        final data = res.data;
        if (res.statusCode == 200 &&
            data is Map<String, dynamic> &&
            data['accessToken'] is String) {
          await _tokens.save(
            access: data['accessToken'] as String,
            refresh: data['refreshToken'] as String,
          );
          completer.complete(true);
        } else {
          completer.complete(false);
        }
      }
    } catch (_) {
      completer.complete(false);
    } finally {
      _refreshInFlight = null;
    }
    return completer.future;
  }
}
