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
    expect(students, hasLength(2));
    expect(students.first.fullName, 'VALERIA MENDOZA ROJAS');
    expect(students.first.code, '1');
    expect(students.first.course, '4.º Secundaria B');
    expect(students.first.managementYear, 2026);
    expect(students.first.guardianName, 'ANA ROJAS');
    expect(students.first.guardianPhone, '71234567');
    expect(students.first.qrPayload, startsWith('AQB1.v2_'));
    expect(students.first.photoSource, 'data:image/png;base64,cGhvdG8=');
    expect(students.last.code, '27');
    expect(students.last.fullName, 'CARLOS QUISPE FLORES');
    expect(students.last.guardianName, 'MARTA FLORES');
    expect(students.last.qrPayload, isNot(students.first.qrPayload));
  });
}

class _TokenStore extends SecureTokenStore {
  @override
  Future<String?> readToken() async => 'session-token';
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
    expect(options.headers['Authorization'], 'Bearer session-token');
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
            'nombreTutor': 'ANA ROJAS',
            'telefonoTutor': '71234567',
            'fotografiaUrl': 'data:image/png;base64,cGhvdG8=',
            'curso': {
              'id': '30000000-0000-4000-8000-000000000001',
              'nombre': '4.º Secundaria B',
              'gestion': 2026,
            },
          },
          'tokenQr': 'AQB1.v2_test-token',
        },
        {
          'estudiante': {
            'id': '20000000-0000-4000-8000-000000000027',
            'codigoEstudiante': 27,
            'nombres': 'CARLOS',
            'apellidos': 'QUISPE FLORES',
            'nombreCompleto': 'CARLOS QUISPE FLORES',
            'estado': 'ACTIVO',
            'nombreTutor': 'MARTA FLORES',
            'telefonoTutor': '76543210',
            'curso': {
              'id': '30000000-0000-4000-8000-000000000002',
              'nombre': '5.º Secundaria A',
              'gestion': 2026,
            },
          },
          'tokenQr': 'AQB1.v2_another-student-token',
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
