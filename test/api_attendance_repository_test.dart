import 'dart:convert';

import 'package:asisteqr_baker/core/network/api_client.dart';
import 'package:asisteqr_baker/core/storage/secure_token_store.dart';
import 'package:asisteqr_baker/features/attendance/data/api_attendance_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registra asistencia manual por ID de estudiante', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = _ManualAttendanceApiAdapter();
    final repository = ApiAttendanceRepository(
      ApiClient(_TokenStore(), httpClient: dio),
    );

    final result = await repository.registerManual(148);

    expect(result.record.student.code, '148');
    expect(result.record.student.fullName, 'Valeria Mendoza Rojas');
    expect(result.duplicate, isFalse);
  });

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

  test('agrupa asistencia y genero por curso para el inicio', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = _DashboardApiAdapter();
    final repository = ApiAttendanceRepository(
      ApiClient(_TokenStore(), httpClient: dio),
    );

    final summary = await repository.getDashboard();

    expect(summary.expected, 3);
    expect(summary.present, 2);
    expect(summary.courses, hasLength(2));
    final fourthA = summary.courses.firstWhere(
      (item) => item.course == '4.º Secundaria A',
    );
    expect(fourthA.expected, 2);
    expect(fourthA.present, 1);
    expect(fourthA.male, 1);
    expect(fourthA.female, 1);
    expect(fourthA.genderNotRegistered, 0);
    expect(summary.courses.last.genderNotRegistered, 1);
  });
}

class _ManualAttendanceApiAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    expect(options.method, 'POST');
    expect(options.path, contains('/asistencias/manual'));
    expect(options.data, {'codigoEstudiante': 148});
    expect(options.headers['Authorization'], 'Bearer access-token');
    return ResponseBody.fromString(
      jsonEncode({
        'id': 'attendance-manual-1',
        'fechaHora': '2026-08-13T12:00:00.000Z',
        'estado': 'PUNTUAL',
        'duplicado': false,
        'estudiante': {
          'id': 'student-148',
          'codigo': 148,
          'nombreCompleto': 'Valeria Mendoza Rojas',
          'curso': '4.º Secundaria B',
          'fotografiaUrl': null,
        },
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

class _DashboardApiAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    expect(options.method, 'GET');
    expect(options.path, contains('/asistencias/diaria'));
    return ResponseBody.fromString(
      jsonEncode([
        _record(
          id: 'student-1',
          name: 'Ana Flores',
          course: '4.º Secundaria A',
          status: 'PUNTUAL',
          genderKey: 'genero',
          gender: 'FEMENINO',
        ),
        _record(
          id: 'student-2',
          name: 'Luis Perez',
          course: '4.º Secundaria A',
          status: 'AUSENTE',
          genderKey: 'sexo',
          gender: 'M',
        ),
        _record(
          id: 'student-3',
          name: 'Alex Rojas',
          course: '5.º Secundaria B',
          status: 'ATRASO',
        ),
      ]),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  Map<String, Object?> _record({
    required String id,
    required String name,
    required String course,
    required String status,
    String? genderKey,
    String? gender,
  }) {
    final student = <String, Object?>{
      'id': id,
      'codigo': id,
      'nombreCompleto': name,
      'fotografiaUrl': null,
      ?genderKey: gender,
    };
    return {
      'estudiante': student,
      'curso': {'id': course, 'nombre': course},
      'fechaHora': status == 'AUSENTE' ? null : '2026-07-14T12:00:00.000Z',
      'estado': status,
    };
  }

  @override
  void close({bool force = false}) {}
}
