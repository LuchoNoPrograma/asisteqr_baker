import 'dart:convert';

import 'package:asisteqr_baker/core/network/api_client.dart';
import 'package:asisteqr_baker/core/storage/secure_token_store.dart';
import 'package:asisteqr_baker/features/schedules/data/api_schedule_planner_repository.dart';
import 'package:asisteqr_baker/features/schedules/domain/schedule_planner_models.dart';
import 'package:asisteqr_baker/features/schedules/domain/schedule_planner_repository.dart';
import 'package:asisteqr_baker/features/schedules/domain/teacher_schedule_editor_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('crea materias con el contrato del catálogo académico', () async {
    final adapter = _ScheduleCatalogAdapter();
    final repository = _repository(adapter);

    final saved = await repository.saveSubject(
      const ScheduleSubjectDraft(name: '  MATEMÁTICA  '),
    );

    expect(saved.id, 1);
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
        id: 1,
      );

      expect(saved.name, 'Laboratorio de Física');
      expect(saved.capacity, 28);
      expect(adapter.lastMethod, 'PATCH');
      expect(adapter.lastPath, '/aulas/1');
      expect(adapter.lastPayload, {
        'nombre': 'Laboratorio de Física',
        'capacidad': 28,
        'ubicacion': 'Bloque B',
      });
    },
  );

  test('envía la carga semanal requerida en el guardado batch', () async {
    final adapter = _ScheduleCatalogAdapter();
    final repository = _repository(adapter);

    final version = await repository.savePlanner(
      periodId: 1,
      version: 1,
      assignments: const [
        AcademicAssignment(
          courseId: 1,
          subjectId: 1,
          teacherId: 1,
          weeklyMinutes: 600,
        ),
      ],
      blocks: const [],
      removedAssignmentIds: const <int>{},
      removedBlockIds: const <int>{},
    );

    expect(version, 2);
    final assignment = (adapter.lastPayload!['asignaciones'] as List).single;
    expect((assignment as Map)['minutosSemanales'], 600);
  });

  test('devuelve la versión confirmada al guardar configuración', () async {
    final adapter = _ScheduleCatalogAdapter();
    final repository = _repository(adapter);

    final version = await repository.saveGeneralConfig(
      const GeneralScheduleDraft(
        periodId: 1,
        version: 1,
        startTime: '07:30',
        endTime: '20:00',
        toleranceMinutes: 5,
        breaks: [],
      ),
    );

    expect(version, 2);
    expect(adapter.lastPath, '/horarios-clase/configuracion/general');
    expect(adapter.lastPayload!['version'], 1);
  });

  test('conserva los datos estructurados de un conflicto batch', () async {
    final adapter = _ScheduleCatalogAdapter()
      ..plannerError = {
        'message': 'El docente ya tiene una clase en ese horario.',
        'code': 'SCHEDULE_CONFLICT',
        'versionActual': 4,
        'diaSemana': 2,
        'horaInicio': '09:00',
        'horaFin': '10:00',
        'docente': 'Rodrigo Flores',
        'curso': '1.º Secundaria A',
        'aula': 'Aula 1',
      };
    final repository = _repository(adapter);

    await expectLater(
      repository.savePlanner(
        periodId: 1,
        version: 3,
        assignments: const [],
        blocks: const [],
        removedAssignmentIds: const <int>{},
        removedBlockIds: const <int>{},
      ),
      throwsA(
        isA<SchedulePlannerSaveException>()
            .having((error) => error.code, 'code', 'SCHEDULE_CONFLICT')
            .having((error) => error.currentVersion, 'version', 4)
            .having((error) => error.weekday, 'día', 2)
            .having((error) => error.teacher, 'docente', 'Rodrigo Flores')
            .having((error) => error.startTime, 'inicio', '09:00'),
      ),
    );
  });

  test('crea un borrador de configuración para un periodo nuevo', () async {
    final adapter = _ScheduleCatalogAdapter()
      ..plannerGetResponse = {
        'periodo': {'id': 1, 'nombre': 'Gestión', 'gestion': 2026},
        'configuracion': null,
        'recreos': <Object>[],
        'cursos': <Object>[],
        'materias': <Object>[],
        'aulas': <Object>[],
        'docentes': <Object>[],
        'asignaciones': <Object>[],
        'bloques': <Object>[],
      };
    final repository = _repository(adapter);

    final planner = await repository.getPlanner();

    expect(planner.configurationPending, isTrue);
    expect(planner.config.periodId, 1);
    expect(planner.config.version, 0);
    expect(planner.config.intervalMinutes, 30);
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
  Future<String?> readToken() async => 'session-token';
}

class _ScheduleCatalogAdapter implements HttpClientAdapter {
  String? lastMethod;
  String? lastPath;
  Map<String, dynamic>? lastPayload;
  Map<String, dynamic>? plannerError;
  Map<String, dynamic>? plannerGetResponse;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastMethod = options.method;
    lastPath = options.path;
    lastPayload = options.data is Map
        ? (options.data as Map).cast<String, dynamic>()
        : null;
    expect(options.headers['Authorization'], 'Bearer session-token');
    if (options.method == 'GET' &&
        options.path == '/horarios-clase/planificador' &&
        plannerGetResponse != null) {
      return ResponseBody.fromString(
        jsonEncode(plannerGetResponse),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    if (options.path == '/horarios-clase/planificador' &&
        plannerError != null) {
      return ResponseBody.fromString(
        jsonEncode(plannerError),
        409,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    final response =
        options.path == '/horarios-clase/planificador' ||
            options.path == '/horarios-clase/configuracion/general'
        ? {'version': 2}
        : options.path.startsWith('/materias')
        ? {'id': 1, 'nombre': lastPayload!['nombre']}
        : {
            'id': 1,
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
