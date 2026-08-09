import 'dart:convert';

import 'package:asisteqr_baker/core/network/api_client.dart';
import 'package:asisteqr_baker/core/storage/secure_token_store.dart';
import 'package:asisteqr_baker/features/credentials/data/api_credential_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('carga credenciales imprimibles desde el contrato real', () async {
    final adapter = _CredentialApiAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = adapter;
    final repository = ApiCredentialRepository(
      ApiClient(_TokenStore(), httpClient: dio),
    );

    final students = await repository.getStudents();

    expect(adapter.requests, 1);
    expect(students, hasLength(1));
    expect(students.single.fullName, 'VALERIA MENDOZA ROJAS');
    expect(students.single.code, 'EST-2026-0001');
    expect(students.single.course, '4.º Secundaria B');
    expect(students.single.qrPayload, startsWith('AQB1.v2_'));
    expect(students.single.photoSource, 'data:image/png;base64,cGhvdG8=');
  });
}

class _TokenStore extends SecureTokenStore {
  @override
  Future<String?> readAccessToken() async => 'access-token';

  @override
  Future<String?> readRefreshToken() async => null;
}

class _CredentialApiAdapter implements HttpClientAdapter {
  int requests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    expect(options.method, 'POST');
    expect(options.path, contains('/credenciales/imprimibles'));
    expect(options.headers['Authorization'], 'Bearer access-token');
    return ResponseBody.fromString(
      jsonEncode([
        {
          'estudiante': {
            'id': '20000000-0000-4000-8000-000000000001',
            'codigoEstudiante': 1,
            'nombres': 'VALERIA',
            'apellidos': 'MENDOZA ROJAS',
            'nombreCompleto': 'VALERIA MENDOZA ROJAS',
            'estado': 'ACTIVO',
            'fotografiaUrl': 'data:image/png;base64,cGhvdG8=',
            'curso': {
              'id': '30000000-0000-4000-8000-000000000001',
              'nombre': '4.º Secundaria B',
              'gestion': 2026,
            },
          },
          'tokenQr': 'AQB1.v2_test-token',
        },
      ]),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
