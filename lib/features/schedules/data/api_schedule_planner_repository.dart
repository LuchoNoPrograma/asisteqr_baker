import 'package:asisteqr_baker/core/network/api_client.dart';
import 'package:asisteqr_baker/features/schedules/domain/schedule_planner_models.dart';
import 'package:asisteqr_baker/features/schedules/domain/schedule_planner_repository.dart';
import 'package:asisteqr_baker/features/schedules/domain/teacher_schedule_editor_models.dart';
import 'package:asisteqr_baker/features/schedules/domain/teaching_schedule_models.dart';
import 'package:dio/dio.dart';

class ApiSchedulePlannerRepository implements SchedulePlannerRepository {
  ApiSchedulePlannerRepository(this._client);

  final ApiClient _client;

  @override
  Future<SchedulePlannerData> getPlanner() async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/horarios-clase/planificador',
      );
      return _fromJson(response.data!);
    } on DioException catch (error) {
      throw TeachingScheduleException(
        _message(error, 'No se pudo cargar el planificador de horarios.'),
      );
    }
  }

  @override
  Future<int> savePlanner({
    required int periodId,
    required int version,
    required List<AcademicAssignment> assignments,
    required List<PlannerScheduleBlock> blocks,
    required Set<int> removedAssignmentIds,
    required Set<int> removedBlockIds,
  }) async {
    try {
      final response = await _client.dio.put<Map<String, dynamic>>(
        '/horarios-clase/planificador',
        data: {
          'periodoId': periodId,
          'version': version,
          'asignaciones': assignments
              .map(
                (item) => {
                  if (item.id != null) 'id': item.id,
                  'cursoId': item.courseId,
                  'materiaId': item.subjectId,
                  'docenteId': item.teacherId,
                  'minutosSemanales': item.weeklyMinutes,
                },
              )
              .toList(),
          'bloques': blocks
              .map(
                (item) => {
                  if (item.id != null) 'id': item.id,
                  'cursoId': item.courseId,
                  'materiaId': item.subjectId,
                  'docenteId': item.teacherId,
                  'aulaId': item.classroomId,
                  'diaSemana': item.weekday,
                  'horaInicio': item.startTime,
                  'horaFin': item.endTime,
                },
              )
              .toList(),
          'asignacionesEliminadas': removedAssignmentIds.toList(),
          'bloquesEliminados': removedBlockIds.toList(),
        },
      );
      return (response.data!['version'] as num).toInt();
    } on DioException catch (error) {
      throw _plannerSaveException(error);
    }
  }

  @override
  Future<int> saveGeneralConfig(GeneralScheduleDraft draft) async {
    try {
      final response = await _client.dio.put<Map<String, dynamic>>(
        '/horarios-clase/configuracion/general',
        data: {
          'periodoId': draft.periodId,
          'version': draft.version,
          'horaInicio': draft.startTime,
          'horaFin': draft.endTime,
          'intervaloMinutos': draft.intervalMinutes,
          'toleranciaMinutos': draft.toleranceMinutes,
          'zonaHoraria': draft.timeZone,
          'recreos': draft.breaks
              .map(
                (item) => {
                  if (item.id != null) 'id': item.id,
                  'nombre': item.name,
                  'horaInicio': item.startTime,
                  'horaFin': item.endTime,
                },
              )
              .toList(),
        },
      );
      return (response.data!['version'] as num).toInt();
    } on DioException catch (error) {
      throw TeachingScheduleException(
        _message(error, 'No se pudo guardar la configuración general.'),
      );
    }
  }

  @override
  Future<ScheduleSubject> saveSubject(
    ScheduleSubjectDraft draft, {
    int? id,
  }) async {
    try {
      final response = id == null
          ? await _client.dio.post<Map<String, dynamic>>(
              '/materias',
              data: {'nombre': draft.name.trim()},
            )
          : await _client.dio.patch<Map<String, dynamic>>(
              '/materias/$id',
              data: {'nombre': draft.name.trim()},
            );
      return _subjectFromJson(response.data!);
    } on DioException catch (error) {
      throw TeachingScheduleException(
        _message(error, 'No se pudo guardar la materia.'),
      );
    }
  }

  @override
  Future<void> deactivateSubject(int id) async {
    try {
      await _client.dio.delete<void>('/materias/$id');
    } on DioException catch (error) {
      throw TeachingScheduleException(
        _message(error, 'No se pudo desactivar la materia.'),
      );
    }
  }

  @override
  Future<ScheduleClassroom> saveClassroom(
    ScheduleClassroomDraft draft, {
    int? id,
  }) async {
    final payload = {
      'nombre': draft.name.trim(),
      'capacidad': draft.capacity,
      'ubicacion': _optional(draft.location),
    };
    try {
      final response = id == null
          ? await _client.dio.post<Map<String, dynamic>>(
              '/aulas',
              data: payload,
            )
          : await _client.dio.patch<Map<String, dynamic>>(
              '/aulas/$id',
              data: payload,
            );
      return _classroomFromJson(response.data!);
    } on DioException catch (error) {
      throw TeachingScheduleException(
        _message(error, 'No se pudo guardar el aula.'),
      );
    }
  }

  @override
  Future<void> deactivateClassroom(int id) async {
    try {
      await _client.dio.delete<void>('/aulas/$id');
    } on DioException catch (error) {
      throw TeachingScheduleException(
        _message(error, 'No se pudo desactivar el aula.'),
      );
    }
  }

  SchedulePlannerData _fromJson(Map<String, dynamic> json) {
    final period = json['periodo'] as Map<String, dynamic>;
    final config = json['configuracion'] as Map<String, dynamic>?;
    final periodId = (period['id'] as num).toInt();
    return SchedulePlannerData(
      period: SchedulePeriod(
        id: periodId,
        name: period['nombre'].toString(),
        year: (period['gestion'] as num).toInt(),
      ),
      config: GeneralScheduleConfig(
        id: (config?['id'] as num?)?.toInt(),
        periodId: (config?['periodoId'] as num?)?.toInt() ?? periodId,
        startTime: config?['horaInicio']?.toString() ?? '07:30',
        endTime: config?['horaFin']?.toString() ?? '20:00',
        intervalMinutes: (config?['intervaloMinutos'] as num?)?.toInt() ?? 30,
        toleranceMinutes: (config?['toleranciaMinutos'] as num?)?.toInt() ?? 5,
        timeZone: config?['zonaHoraria']?.toString() ?? 'America/La_Paz',
        version: (config?['version'] as num?)?.toInt() ?? 0,
      ),
      breaks: (json['recreos'] as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .map(
            (item) => ScheduleBreak(
              id: (item['id'] as num).toInt(),
              name: item['nombre'].toString(),
              startTime: item['horaInicio'].toString(),
              endTime: item['horaFin'].toString(),
            ),
          )
          .toList(),
      courses: (json['cursos'] as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .map(
            (item) => ScheduleCourse(
              id: (item['id'] as num).toInt(),
              name: item['nombre'].toString(),
            ),
          )
          .toList(),
      subjects: (json['materias'] as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .map(_subjectFromJson)
          .toList(),
      classrooms: (json['aulas'] as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .map(_classroomFromJson)
          .toList(),
      teachers: (json['docentes'] as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .map(
            (item) => ScheduleTeacher(
              id: (item['id'] as num).toInt(),
              code: (item['codigo'] as num).toInt(),
              fullName: item['nombreCompleto'].toString(),
              specialty: item['especialidad'].toString(),
              phone: item['telefono']?.toString(),
              email: item['correo']?.toString(),
              photoUrl: item['fotografiaUrl']?.toString(),
            ),
          )
          .toList(),
      assignments: (json['asignaciones'] as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .map(
            (item) => AcademicAssignment(
              id: (item['id'] as num?)?.toInt(),
              courseId: (item['cursoId'] as num).toInt(),
              subjectId: (item['materiaId'] as num).toInt(),
              teacherId: (item['docenteId'] as num).toInt(),
              weeklyMinutes: (item['minutosSemanales'] as num).toInt(),
            ),
          )
          .toList(),
      blocks: (json['bloques'] as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .map(
            (item) => PlannerScheduleBlock(
              id: (item['id'] as num).toInt(),
              courseId: (item['cursoId'] as num).toInt(),
              subjectId: (item['materiaId'] as num).toInt(),
              teacherId: (item['docenteId'] as num).toInt(),
              classroomId: (item['aulaId'] as num).toInt(),
              weekday: (item['diaSemana'] as num).toInt(),
              startTime: item['horaInicio'].toString(),
              endTime: item['horaFin'].toString(),
            ),
          )
          .toList(),
      configurationPending: config == null,
    );
  }

  String _message(DioException error, String fallback) {
    final body = error.response?.data;
    if (body is Map) {
      final message = body['message'] ?? body['mensaje'];
      if (message is List) return message.join('\n');
      if (message is Map && message['message'] != null) {
        return message['message'].toString();
      }
      if (message != null) return message.toString();
    }
    return fallback;
  }

  SchedulePlannerSaveException _plannerSaveException(DioException error) {
    const fallback = 'No se pudo guardar la planificación.';
    final body = error.response?.data;
    final raw = body is Map ? body['message'] ?? body['mensaje'] : null;
    final details = raw is Map
        ? raw
        : body is Map
        ? body
        : const <Object, Object>{};
    final message = raw is Map
        ? raw['message']?.toString() ?? fallback
        : _message(error, fallback);
    int? integer(Object? value) => value is num ? value.toInt() : null;
    return SchedulePlannerSaveException(
      message,
      code: details['code']?.toString(),
      currentVersion: integer(details['versionActual']),
      weekday: integer(details['diaSemana']),
      startTime: details['horaInicio']?.toString(),
      endTime: details['horaFin']?.toString(),
      teacher: details['docente']?.toString(),
      course: details['curso']?.toString(),
      classroom: details['aula']?.toString(),
    );
  }

  ScheduleSubject _subjectFromJson(Map<String, dynamic> json) =>
      ScheduleSubject(
        id: (json['id'] as num).toInt(),
        name: json['nombre'].toString(),
      );

  ScheduleClassroom _classroomFromJson(Map<String, dynamic> json) =>
      ScheduleClassroom(
        id: (json['id'] as num).toInt(),
        name: json['nombre'].toString(),
        capacity: (json['capacidad'] as num?)?.toInt(),
        location: json['ubicacion']?.toString(),
      );

  String? _optional(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
