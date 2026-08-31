import 'dart:convert';

import 'package:asisteqr_baker/core/network/api_client.dart';
import 'package:asisteqr_baker/core/storage/secure_token_store.dart';
import 'package:asisteqr_baker/features/attendance/data/api_attendance_repository.dart';
import 'package:asisteqr_baker/features/attendance/domain/attendance_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registra asistencia manual por ID de estudiante', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = _ManualAttendanceApiAdapter();
    final repository = ApiAttendanceRepository(
      ApiClient(_TokenStore(), httpClient: dio),
    );

    final result = await repository.registerManual(
      148,
      AttendanceShift.afternoon,
    );

    expect(result.record.student.code, '148');
    expect(result.record.student.fullName, 'Valeria Mendoza Rojas');
    expect(result.record.shift, AttendanceShift.afternoon);
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
      courseId: 1,
      shift: AttendanceShift.afternoon,
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
    expect(summary.recent.first.student.id, 3);
    expect(summary.recent.every((record) => record.timestamp != null), isTrue);
  });

  test('representa la ausencia por jornada sin inventar una hora', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = _DashboardApiAdapter();
    final repository = ApiAttendanceRepository(
      ApiClient(_TokenStore(), httpClient: dio),
    );

    final records = await repository.getDaily();
    final absence = records.singleWhere(
      (record) => record.status == AttendanceStatus.absent,
    );

    expect(absence.timestamp, isNull);
    expect(absence.shift, AttendanceShift.morning);
    expect(absence.scheduleId, isNotNull);
  });

  test('carga las jornadas operativas disponibles', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = _AvailableShiftsApiAdapter();
    final repository = ApiAttendanceRepository(
      ApiClient(_TokenStore(), httpClient: dio),
    );

    final shifts = await repository.getAvailableShifts();

    expect(shifts, [AttendanceShift.morning, AttendanceShift.afternoon]);
  });

  test('mapea los codigos funcionales estables de asistencia', () async {
    const cases = <({String code, AttendanceFailureKind kind, bool qr})>[
      (code: 'QR_INVALIDO', kind: AttendanceFailureKind.invalidQr, qr: true),
      (
        code: 'ESTUDIANTE_NO_ENCONTRADO',
        kind: AttendanceFailureKind.studentNotFound,
        qr: false,
      ),
      (
        code: 'ESTUDIANTE_INACTIVO',
        kind: AttendanceFailureKind.inactiveStudent,
        qr: false,
      ),
      (
        code: 'INSCRIPCION_ACTIVA_AUSENTE',
        kind: AttendanceFailureKind.missingEnrollment,
        qr: false,
      ),
      (
        code: 'HORARIO_ACTIVO_AUSENTE',
        kind: AttendanceFailureKind.missingSchedule,
        qr: false,
      ),
      (
        code: 'HORARIO_JORNADA_AUSENTE',
        kind: AttendanceFailureKind.missingSchedule,
        qr: false,
      ),
      (
        code: 'CONFIGURACION_HORARIA_AUSENTE',
        kind: AttendanceFailureKind.missingScheduleConfiguration,
        qr: false,
      ),
    ];

    for (final item in cases) {
      final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
        ..httpClientAdapter = _AttendanceErrorAdapter(item.code);
      final repository = ApiAttendanceRepository(
        ApiClient(_TokenStore(), httpClient: dio),
      );

      final request = item.qr
          ? repository.registerQr('QR-NO-REGISTRADO', AttendanceShift.morning)
          : repository.registerManual(148, AttendanceShift.morning);
      await expectLater(
        request,
        throwsA(
          isA<AttendanceException>()
              .having((error) => error.kind, 'kind', item.kind)
              .having((error) => error.message, 'message', 'Detalle funcional'),
        ),
      );
    }
  });
}

class _AttendanceErrorAdapter implements HttpClientAdapter {
  _AttendanceErrorAdapter(this.code);

  final String code;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final status = code == 'QR_INVALIDO' || code == 'ESTUDIANTE_NO_ENCONTRADO'
        ? 404
        : 400;
    return ResponseBody.fromString(
      jsonEncode({'code': code, 'message': 'Detalle funcional'}),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
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
    expect(options.data, {'codigoEstudiante': 148, 'jornada': 'TARDE'});
    expect(options.headers['Authorization'], 'Bearer session-token');
    return ResponseBody.fromString(
      jsonEncode({
        'id': 1,
        'fechaHora': '2026-08-13T12:00:00.000Z',
        'estado': 'PUNTUAL',
        'duplicado': false,
        'horario': {'id': 2, 'jornada': 'TARDE', 'horaLimite': '14:00'},
        'estudiante': {
          'id': 148,
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
  Future<String?> readToken() async => 'session-token';
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
    expect(options.queryParameters['cursoId'], 1);
    expect(options.queryParameters['jornada'], 'TARDE');
    expect(options.headers['Authorization'], 'Bearer session-token');
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
          id: 1,
          name: 'Ana Flores',
          course: '4.º Secundaria A',
          status: 'PUNTUAL',
          genderKey: 'genero',
          gender: 'FEMENINO',
          timestamp: '2026-07-14T12:00:00.000Z',
        ),
        _record(
          id: 2,
          name: 'Luis Perez',
          course: '4.º Secundaria A',
          status: 'AUSENTE',
          genderKey: 'sexo',
          gender: 'M',
        ),
        _record(
          id: 3,
          name: 'Alex Rojas',
          course: '5.º Secundaria B',
          status: 'ATRASO',
          timestamp: '2026-07-14T13:00:00.000Z',
        ),
      ]),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  Map<String, Object?> _record({
    required int id,
    required String name,
    required String course,
    required String status,
    String? genderKey,
    String? gender,
    String? timestamp,
  }) {
    final student = <String, Object?>{
      'id': id,
      'codigo': id,
      'nombreCompleto': name,
      'fotografiaUrl': null,
      ?genderKey: gender,
    };
    return {
      'id': status == 'AUSENTE' ? null : id,
      'estudiante': student,
      'curso': {'id': id, 'nombre': course},
      'horario': {'id': id, 'jornada': 'MANANA', 'horaLimite': '08:00'},
      'fechaHora': timestamp,
      'estado': status,
    };
  }

  @override
  void close({bool force = false}) {}
}

class _AvailableShiftsApiAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    expect(options.method, 'GET');
    expect(options.path, contains('/asistencias/jornadas'));
    return ResponseBody.fromString(
      jsonEncode([
        {'jornada': 'MANANA'},
        {'jornada': 'TARDE'},
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
