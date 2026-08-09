import 'dart:convert';

import 'package:asisteqr_baker/core/network/api_client.dart';
import 'package:asisteqr_baker/core/storage/secure_token_store.dart';
import 'package:asisteqr_baker/features/attendance/data/api_attendance_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('consulta la jornada y el curso seleccionados en la API', () async {
    final adapter = _AttendanceApiAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = adapter;
    final repository = ApiAttendanceRepository(
      ApiClient(_TokenStore(), httpClient: dio),
    );

    await repository.getDaily(
      date: DateTime(2026, 7, 14),
      courseId: 'course-4b',
    );

    expect(adapter.requests, 1);
  });
}

class _TokenStore extends SecureTokenStore {
  @override
  Future<String?> readAccessToken() async => 'access-token';

  @override
  Future<String?> readRefreshToken() async => null;
}

class _AttendanceApiAdapter implements HttpClientAdapter {
  int requests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    expect(options.method, 'GET');
    expect(options.path, contains('/asistencias/diaria'));
    expect(options.queryParameters['fecha'], '2026-07-14');
    expect(options.queryParameters['cursoId'], 'course-4b');
    expect(options.headers['Authorization'], 'Bearer access-token');
    return ResponseBody.fromString(
      jsonEncode([]),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
