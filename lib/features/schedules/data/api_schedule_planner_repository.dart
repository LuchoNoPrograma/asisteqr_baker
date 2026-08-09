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
    required String periodId,
    required int version,
    required List<AcademicAssignment> assignments,
    required List<PlannerScheduleBlock> blocks,
    required Set<String> removedAssignmentIds,
    required Set<String> removedBlockIds,
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
      throw TeachingScheduleException(
        _message(error, 'No se pudo guardar la planificación.'),
      );
    }
  }

  @override
  Future<void> saveGeneralConfig(GeneralScheduleDraft draft) async {
    try {
      await _client.dio.put<Map<String, dynamic>>(
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
    } on DioException catch (error) {
      throw TeachingScheduleException(
        _message(error, 'No se pudo guardar la configuración general.'),
      );
    }
  }

  SchedulePlannerData _fromJson(Map<String, dynamic> json) {
    final period = json['periodo'] as Map<String, dynamic>;
    final config = json['configuracion'] as Map<String, dynamic>;
    return SchedulePlannerData(
      period: SchedulePeriod(
        id: period['id'].toString(),
        name: period['nombre'].toString(),
        year: (period['gestion'] as num).toInt(),
      ),
      config: GeneralScheduleConfig(
        id: config['id'].toString(),
        periodId: config['periodoId'].toString(),
        startTime: config['horaInicio'].toString(),
        endTime: config['horaFin'].toString(),
        intervalMinutes: (config['intervaloMinutos'] as num).toInt(),
        toleranceMinutes: (config['toleranciaMinutos'] as num).toInt(),
        timeZone: config['zonaHoraria'].toString(),
        version: (config['version'] as num).toInt(),
      ),
      breaks: (json['recreos'] as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .map(
            (item) => ScheduleBreak(
              id: item['id'].toString(),
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
              id: item['id'].toString(),
              name: item['nombre'].toString(),
            ),
          )
          .toList(),
      subjects: (json['materias'] as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .map(
            (item) => ScheduleSubject(
              id: item['id'].toString(),
              code: item['codigo'].toString(),
              name: item['nombre'].toString(),
            ),
          )
          .toList(),
      classrooms: (json['aulas'] as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .map(
            (item) => ScheduleClassroom(
              id: item['id'].toString(),
              code: item['codigo'].toString(),
              name: item['nombre'].toString(),
              capacity: (item['capacidad'] as num?)?.toInt(),
              location: item['ubicacion']?.toString(),
            ),
          )
          .toList(),
      teachers: (json['docentes'] as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .map(
            (item) => ScheduleTeacher(
              id: item['id'].toString(),
              code: (item['codigo'] as num).toInt(),
              fullName: item['nombreCompleto'].toString(),
              specialty: item['especialidad'].toString(),
              photoUrl: item['fotografiaUrl']?.toString(),
            ),
          )
          .toList(),
      assignments: (json['asignaciones'] as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .map(
            (item) => AcademicAssignment(
              id: item['id'].toString().startsWith('derivada-')
                  ? null
                  : item['id'].toString(),
              courseId: item['cursoId'].toString(),
              subjectId: item['materiaId'].toString(),
              teacherId: item['docenteId'].toString(),
              weeklyMinutes: (item['minutosSemanales'] as num).toInt(),
            ),
          )
          .toList(),
      blocks: (json['bloques'] as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .map(
            (item) => PlannerScheduleBlock(
              id: item['id'].toString(),
              courseId: item['cursoId'].toString(),
              subjectId: item['materiaId'].toString(),
              teacherId: item['docenteId'].toString(),
              classroomId: item['aulaId'].toString(),
              weekday: (item['diaSemana'] as num).toInt(),
              startTime: item['horaInicio'].toString(),
              endTime: item['horaFin'].toString(),
            ),
          )
          .toList(),
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
}
