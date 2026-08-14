import 'dart:convert';

import 'package:asisteqr_baker/core/network/api_client.dart';
import 'package:asisteqr_baker/core/storage/secure_token_store.dart';
import 'package:asisteqr_baker/features/schedules/data/api_schedule_planner_repository.dart';
import 'package:asisteqr_baker/features/schedules/domain/schedule_planner_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('crea materias con el contrato del catálogo académico', () async {
    final adapter = _ScheduleCatalogAdapter();
    final repository = _repository(adapter);

    final saved = await repository.saveSubject(
      const ScheduleSubjectDraft(name: '  MATEMÁTICA  '),
    );

    expect(saved.id, 'subject-1');
    expect(saved.name, 'MATEMÁTICA');
    expect(adapter.lastMethod, 'POST');
    expect(adapter.lastPath, '/materias');
    expect(adapter.lastPayload, {'nombre': 'MATEMÁTICA'});
  });

  test(
    'actualiza aulas por nombre preservando capacidad y ubicación',
    () async {
      final adapter = _ScheduleCatalogAdapter();
      final repository = _repository(adapter);

      final saved = await repository.saveClassroom(
        const ScheduleClassroomDraft(
          name: ' Laboratorio de Física ',
          capacity: 28,
          location: ' Bloque B ',
        ),
        id: 'classroom-1',
      );

      expect(saved.name, 'Laboratorio de Física');
      expect(saved.capacity, 28);
      expect(adapter.lastMethod, 'PATCH');
      expect(adapter.lastPath, '/aulas/classroom-1');
      expect(adapter.lastPayload, {
        'nombre': 'Laboratorio de Física',
        'capacidad': 28,
        'ubicacion': 'Bloque B',
      });
    },
  );

  test('delega el cálculo de carga semanal al backend', () async {
    final adapter = _ScheduleCatalogAdapter();
    final repository = _repository(adapter);

    final version = await repository.savePlanner(
      periodId: 'period-1',
      version: 1,
      assignments: const [
        AcademicAssignment(
          courseId: 'course-1',
          subjectId: 'subject-1',
          teacherId: 'teacher-1',
          weeklyMinutes: 600,
        ),
      ],
      blocks: const [],
      removedAssignmentIds: const <String>{},
      removedBlockIds: const <String>{},
    );

    expect(version, 2);
    final assignment = (adapter.lastPayload!['asignaciones'] as List).single;
    expect((assignment as Map).containsKey('minutosSemanales'), isFalse);
  });
}

ApiSchedulePlannerRepository _repository(HttpClientAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
    ..httpClientAdapter = adapter;
  return ApiSchedulePlannerRepository(
    ApiClient(_TokenStore(), httpClient: dio),
  );
}

class _TokenStore extends SecureTokenStore {
  @override
  Future<String?> readAccessToken() async => 'access-token';

  @override
  Future<String?> readRefreshToken() async => null;
}

class _ScheduleCatalogAdapter implements HttpClientAdapter {
  String? lastMethod;
  String? lastPath;
  Map<String, dynamic>? lastPayload;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastMethod = options.method;
    lastPath = options.path;
    lastPayload = (options.data as Map).cast<String, dynamic>();
    expect(options.headers['Authorization'], 'Bearer access-token');
    final response = options.path == '/horarios-clase/planificador'
        ? {'version': 2}
        : options.path.startsWith('/materias')
        ? {'id': 'subject-1', 'nombre': lastPayload!['nombre']}
        : {
            'id': 'classroom-1',
            'nombre': lastPayload!['nombre'],
            'capacidad': lastPayload!['capacidad'],
            'ubicacion': lastPayload!['ubicacion'],
          };
    return ResponseBody.fromString(
      jsonEncode(response),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
