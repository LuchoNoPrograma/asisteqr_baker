import 'package:asisteqr_baker/core/network/api_client.dart';
import 'package:asisteqr_baker/features/schedules/domain/teacher_schedule_editor_models.dart';
import 'package:asisteqr_baker/features/schedules/domain/teacher_schedule_editor_repository.dart';
import 'package:asisteqr_baker/features/schedules/domain/teaching_schedule_models.dart';
import 'package:dio/dio.dart';

class ApiTeacherScheduleEditorRepository
    implements TeacherScheduleEditorRepository {
  ApiTeacherScheduleEditorRepository(this._client);

  final ApiClient _client;

  @override
  Future<TeacherScheduleEditorData> getEditor(String teacherId) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/horarios-clase/docente/$teacherId/editor',
      );
      return _editorFromJson(response.data!);
    } on DioException catch (error) {
      throw TeachingScheduleException(
        _message(error, 'No se pudo cargar el horario del docente.'),
      );
    }
  }

  @override
  Future<({int version, List<TeacherScheduleBlock> blocks})> saveMatrix({
    required String teacherId,
    required String periodId,
    required int version,
    required List<TeacherScheduleBlock> blocks,
  }) async {
    try {
      final response = await _client.dio.put<Map<String, dynamic>>(
        '/horarios-clase/docente/$teacherId/editor',
        data: {
          'periodoId': periodId,
          'version': version,
          'bloques': blocks
              .map(
                (block) => {
                  'clientId': block.id,
                  'cursoId': block.courseId,
                  'materiaId': block.subjectId,
                  'aulaId': block.classroomId,
                  'diaSemana': block.weekday,
                  'horaInicio': block.startTime,
                  'horaFin': block.endTime,
                },
              )
              .toList(),
        },
      );
      final json = response.data!;
      return (
        version: (json['version'] as num).toInt(),
        blocks: (json['bloques'] as List<dynamic>)
            .map((item) => _blockFromJson(item as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (error) {
      throw TeachingScheduleException(
        _message(error, 'No se pudo guardar la matriz de horario.'),
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

  TeacherScheduleEditorData _editorFromJson(Map<String, dynamic> json) {
    final teacher = json['docente'] as Map<String, dynamic>;
    final period = json['periodo'] as Map<String, dynamic>;
    final config = json['configuracion'] as Map<String, dynamic>;
    return TeacherScheduleEditorData(
      teacher: ScheduleTeacher(
        id: teacher['id'].toString(),
        code: (teacher['codigo'] as num).toInt(),
        fullName: teacher['nombreCompleto'].toString(),
        specialty: teacher['especialidad'].toString(),
        phone: teacher['telefono']?.toString(),
        email: teacher['correo']?.toString(),
        photoUrl: teacher['fotografiaUrl']?.toString(),
      ),
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
          .map((item) => _breakFromJson(item as Map<String, dynamic>))
          .toList(),
      courses: (json['cursos'] as List<dynamic>)
          .map(
            (item) => ScheduleCourse(
              id: (item as Map<String, dynamic>)['id'].toString(),
              name: item['nombre'].toString(),
            ),
          )
          .toList(),
      subjects: (json['materias'] as List<dynamic>)
          .map(
            (item) => ScheduleSubject(
              id: (item as Map<String, dynamic>)['id'].toString(),
              name: item['nombre'].toString(),
            ),
          )
          .toList(),
      classrooms: (json['aulas'] as List<dynamic>)
          .map((item) => _classroomFromJson(item as Map<String, dynamic>))
          .toList(),
      blocks: (json['bloques'] as List<dynamic>)
          .map((item) => _blockFromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  ScheduleBreak _breakFromJson(Map<String, dynamic> json) => ScheduleBreak(
    id: json['id'].toString(),
    name: json['nombre'].toString(),
    startTime: json['horaInicio'].toString(),
    endTime: json['horaFin'].toString(),
  );

  ScheduleClassroom _classroomFromJson(Map<String, dynamic> json) =>
      ScheduleClassroom(
        id: json['id'].toString(),
        name: json['nombre'].toString(),
        capacity: (json['capacidad'] as num?)?.toInt(),
        location: json['ubicacion']?.toString(),
      );

  TeacherScheduleBlock _blockFromJson(Map<String, dynamic> json) =>
      TeacherScheduleBlock(
        id: json['id'].toString(),
        courseId: json['cursoId'].toString(),
        courseName: json['cursoNombre'].toString(),
        subjectId: json['materiaId'].toString(),
        subjectName: json['materiaNombre'].toString(),
        classroomId: json['aulaId'].toString(),
        classroomName: json['aulaNombre']?.toString() ?? 'Sin aula',
        weekday: (json['diaSemana'] as num).toInt(),
        startTime: json['horaInicio'].toString(),
        endTime: json['horaFin'].toString(),
      );

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
