import 'dart:convert';

import 'package:asisteqr_baker/core/network/api_client.dart';
import 'package:asisteqr_baker/core/storage/secure_token_store.dart';
import 'package:asisteqr_baker/features/auth/data/auth_repositories.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('guarda una sesión opaca y restaura el usuario desde la API', () async {
    final tokens = _MemoryTokenStore();
    final adapter = _AuthAdapter();
    final httpClient = Dio()..httpClientAdapter = adapter;
    final repository = ApiAuthRepository(
      ApiClient(tokens, httpClient: httpClient),
      tokens,
    );

    final signedIn = await repository.signIn(
      username: 'admin',
      password: 'correcta',
    );
    final restored = await repository.restoreSession();

    expect(await tokens.readToken(), 'sesion-opaca');
    expect(signedIn.name, 'Administrador Baker');
    expect(restored?.role, 'ADMINISTRADOR');
    expect(adapter.sessionAuthorization, 'Bearer sesion-opaca');
  });
}

class _MemoryTokenStore extends SecureTokenStore {
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

class _AuthAdapter implements HttpClientAdapter {
  String? sessionAuthorization;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.endsWith('/autenticacion/iniciar-sesion')) {
      return _json({
        'token': 'sesion-opaca',
        'expiraEn': '2026-09-13T12:00:00.000Z',
        'usuario': _user,
      });
    }
    if (options.path.endsWith('/autenticacion/sesion')) {
      sessionAuthorization = options.headers['Authorization']?.toString();
      return _json({'usuario': _user});
    }
    return ResponseBody.fromString('', 404);
  }

  ResponseBody _json(Map<String, dynamic> body) => ResponseBody.fromString(
    jsonEncode(body),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  static const _user = {
    'id': 'usuario-1',
    'usuario': 'admin',
    'nombreCompleto': 'Administrador Baker',
    'rol': 'ADMINISTRADOR',
  };

  @override
  void close({bool force = false}) {}
}
