import 'package:asisteqr_baker/core/network/api_client.dart';
import 'package:asisteqr_baker/features/schedules/domain/teaching_schedule_models.dart';
import 'package:asisteqr_baker/features/schedules/domain/teaching_schedule_repository.dart';
import 'package:dio/dio.dart';

class ApiTeachingScheduleRepository implements TeachingScheduleRepository {
  ApiTeachingScheduleRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<TeachingSchedule>> getSchedules() async {
    try {
      final response = await _client.dio.get<List<dynamic>>('/horarios-clase');
      return response.data!
          .map((item) => _fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw TeachingScheduleException(
        _message(error, 'No se pudieron cargar los horarios.'),
      );
    }
  }

  @override
  Future<TeachingSchedule> createSchedule(TeachingScheduleDraft draft) =>
      _save(null, draft);

  @override
  Future<TeachingSchedule> updateSchedule(
    String id,
    TeachingScheduleDraft draft,
  ) => _save(id, draft);

  Future<TeachingSchedule> _save(
    String? id,
    TeachingScheduleDraft draft,
  ) async {
    try {
      final data = {
        'docenteId': draft.teacherId,
        'cursoId': draft.courseId,
        'materia': draft.subject.trim(),
        'diaSemana': draft.weekday,
        'horaInicio': draft.startTime,
        'horaFin': draft.endTime,
      };
      final response = id == null
          ? await _client.dio.post<Map<String, dynamic>>(
              '/horarios-clase',
              data: data,
            )
          : await _client.dio.patch<Map<String, dynamic>>(
              '/horarios-clase/$id',
              data: data,
            );
      return _fromJson(response.data!);
    } on DioException catch (error) {
      throw TeachingScheduleException(
        _message(error, 'No se pudo guardar el horario.'),
      );
    }
  }

  @override
  Future<void> deactivateSchedule(String id) async {
    try {
      await _client.dio.delete<void>('/horarios-clase/$id');
    } on DioException catch (error) {
      throw TeachingScheduleException(
        _message(error, 'No se pudo retirar el horario.'),
      );
    }
  }

  TeachingSchedule _fromJson(Map<String, dynamic> json) {
    final teacher = json['docente'] as Map<String, dynamic>;
    final course = json['curso'] as Map<String, dynamic>;
    return TeachingSchedule(
      id: json['id'].toString(),
      teacherId: teacher['id'].toString(),
      teacherCode: (teacher['codigo'] as num).toInt(),
      teacherName: teacher['nombreCompleto'].toString(),
      teacherSpecialty: teacher['especialidad'].toString(),
      teacherPhone: teacher['telefono']?.toString(),
      courseId: course['id'].toString(),
      courseName: course['nombre'].toString(),
      subject: json['materia'].toString(),
      weekday: (json['diaSemana'] as num).toInt(),
      startTime: json['horaInicio'].toString(),
      endTime: json['horaFin'].toString(),
      active: json['activo'] == true,
    );
  }

  String _message(DioException error, String fallback) {
    final body = error.response?.data;
    if (body is Map) {
      final message = body['message'] ?? body['mensaje'];
      if (message is List) return message.join('\n');
      if (message != null) return message.toString();
    }
    return fallback;
  }
}
