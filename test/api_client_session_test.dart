import 'dart:convert';

import 'package:asisteqr_baker/core/network/api_client.dart';
import 'package:asisteqr_baker/core/storage/secure_token_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'envía la sesión opaca y la elimina cuando el servidor responde 401',
    () async {
      final tokens = _MemoryTokenStore('sesion-opaca');
      final adapter = _UnauthorizedAdapter();
      final httpClient = Dio()..httpClientAdapter = adapter;
      final client = ApiClient(tokens, httpClient: httpClient);

      await expectLater(
        client.dio.get<List<dynamic>>('/docentes'),
        throwsA(isA<DioException>()),
      );

      expect(adapter.authorization, 'Bearer sesion-opaca');
      expect(await tokens.readToken(), isNull);
    },
  );
}

class _MemoryTokenStore extends SecureTokenStore {
  _MemoryTokenStore(this.token);

  String? token;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String token) async {
    this.token = token;
  }

  @override
  Future<void> clear() async {
    token = null;
  }
}

class _UnauthorizedAdapter implements HttpClientAdapter {
  String? authorization;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    authorization = options.headers['Authorization']?.toString();
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
