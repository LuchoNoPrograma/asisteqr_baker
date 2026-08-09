import 'dart:convert';

import 'package:asisteqr_baker/core/network/api_client.dart';
import 'package:asisteqr_baker/core/storage/secure_token_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('renueva el token tras un 401 y repite la solicitud original', () async {
    final tokens = _MemoryTokenStore('acceso-vencido', 'renovacion-valida');
    final apiAdapter = _ApiAdapter();
    final refreshAdapter = _RefreshAdapter();
    final httpClient = Dio()..httpClientAdapter = apiAdapter;
    final refreshClient = Dio()..httpClientAdapter = refreshAdapter;
    final client = ApiClient(
      tokens,
      httpClient: httpClient,
      refreshClient: refreshClient,
    );

    final response = await client.dio.get<List<dynamic>>('/docentes');

    expect(response.statusCode, 200);
    expect(apiAdapter.requests, 2);
    expect(refreshAdapter.requests, 1);
    expect(await tokens.readAccessToken(), 'acceso-nuevo');
    expect(await tokens.readRefreshToken(), 'renovacion-nueva');
  });
}

class _MemoryTokenStore extends SecureTokenStore {
  _MemoryTokenStore(this.accessToken, this.refreshToken);

  String? accessToken;
  String? refreshToken;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
  }
}

class _ApiAdapter implements HttpClientAdapter {
  int requests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    final authorization = options.headers['Authorization'];
    if (authorization == 'Bearer acceso-nuevo') {
      return ResponseBody.fromString(
        '[]',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode({'message': 'Unauthorized'}),
      401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _RefreshAdapter implements HttpClientAdapter {
  int requests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    expect(options.path, contains('/autenticacion/renovar'));
    return ResponseBody.fromString(
      jsonEncode({
        'tokenAcceso': 'acceso-nuevo',
        'tokenRenovacion': 'renovacion-nueva',
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
