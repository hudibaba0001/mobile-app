import 'dart:convert';

import 'package:http/http.dart' as http;

import 'supabase_auth_service.dart';

class AuthExpiredException implements Exception {
  AuthExpiredException(
      [this.message = 'Session expired. Please sign in again.']);

  final String message;

  @override
  String toString() => message;
}

class AuthHttpClient {
  AuthHttpClient({
    SupabaseAuthService? authService,
    http.Client? client,
    Future<bool> Function()? refreshSession,
    Future<void> Function()? signOut,
    String? Function()? accessTokenProvider,
  })  : _authService = authService,
        _client = client ?? http.Client(),
        _refreshSession = refreshSession,
        _signOut = signOut,
        _accessTokenProvider = accessTokenProvider;

  SupabaseAuthService? _authService;
  final http.Client _client;
  final Future<bool> Function()? _refreshSession;
  final Future<void> Function()? _signOut;
  final String? Function()? _accessTokenProvider;

  Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 15),
  }) {
    return _sendWithAuthRetry(
      timeout: timeout,
      send: (authHeaders) => _client.get(uri, headers: authHeaders),
      baseHeaders: headers,
    );
  }

  Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration timeout = const Duration(seconds: 15),
  }) {
    return _sendWithAuthRetry(
      timeout: timeout,
      send: (authHeaders) => _client.post(
        uri,
        headers: authHeaders,
        body: body,
        encoding: encoding,
      ),
      baseHeaders: headers,
    );
  }

  Future<http.Response> delete(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration timeout = const Duration(seconds: 15),
  }) {
    return _sendWithAuthRetry(
      timeout: timeout,
      send: (authHeaders) => _client.delete(
        uri,
        headers: authHeaders,
        body: body,
        encoding: encoding,
      ),
      baseHeaders: headers,
    );
  }

  Future<http.Response> _sendWithAuthRetry({
    required Future<http.Response> Function(Map<String, String> headers) send,
    required Map<String, String>? baseHeaders,
    required Duration timeout,
  }) async {
    Future<http.Response> requestOnce() async {
      final headers = _buildHeaders(baseHeaders);
      return send(headers).timeout(timeout);
    }

    final first = await requestOnce();
    if (first.statusCode != 401) {
      return first;
    }

    final refreshed = await _refresh();
    if (refreshed) {
      final retry = await requestOnce();
      if (retry.statusCode != 401) {
        return retry;
      }
    }

    await _safeSignOut();
    throw AuthExpiredException();
  }

  Map<String, String> _buildHeaders(Map<String, String>? baseHeaders) {
    final headers = <String, String>{...?baseHeaders};
    final token = _accessTokenProvider?.call() ??
        _ensureAuthService().currentSession?.accessToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<bool> _refresh() async {
    if (_refreshSession != null) {
      return _refreshSession!.call();
    }
    return _ensureAuthService().refreshSession();
  }

  Future<void> _safeSignOut() async {
    try {
      if (_signOut != null) {
        await _signOut!.call();
      } else {
        await _ensureAuthService().signOut();
      }
    } catch (_) {
      // Best-effort sign-out should never hide auth expiry.
    }
  }

  SupabaseAuthService _ensureAuthService() {
    _authService ??= SupabaseAuthService();
    return _authService!;
  }
}
