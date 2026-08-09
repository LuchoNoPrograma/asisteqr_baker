import 'package:asisteqr_baker/core/network/api_client.dart';
import 'package:asisteqr_baker/features/courses/domain/course_models.dart';
import 'package:asisteqr_baker/features/courses/domain/course_repository.dart';
import 'package:dio/dio.dart';

class ApiCourseRepository implements CourseRepository {
  ApiCourseRepository(this._client);
  final ApiClient _client;

  @override
  Future<List<CourseEntry>> getCourses({String? search}) async {
    try {
      final response = await _client.dio.get<List<dynamic>>(
        '/cursos',
        queryParameters: {'buscar': ?search},
      );
      return response.data!
          .map((item) => _course(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw CourseException(
        _message(error, 'No se pudieron cargar los cursos.'),
      );
    }
  }

  @override
  Future<CourseEntry> createCourse(CourseDraft draft) =>
      _saveCourse(null, draft);

  @override
  Future<CourseEntry> updateCourse(String id, CourseDraft draft) =>
      _saveCourse(id, draft);

  Future<CourseEntry> _saveCourse(String? id, CourseDraft draft) async {
    try {
      final data = {
        'nombre': draft.name,
        'nivel': draft.level,
        'paralelo': draft.parallel,
        'gestion': draft.year,
      };
      final response = id == null
          ? await _client.dio.post<Map<String, dynamic>>('/cursos', data: data)
          : await _client.dio.patch<Map<String, dynamic>>(
              '/cursos/$id',
              data: data,
            );
      return _course(response.data!);
    } on DioException catch (error) {
      throw CourseException(_message(error, 'No se pudo guardar el curso.'));
    }
  }

  @override
  Future<void> deactivateCourse(String id) async {
    try {
      await _client.dio.delete<void>('/cursos/$id');
    } on DioException catch (error) {
      throw CourseException(_message(error, 'No se pudo inactivar el curso.'));
    }
  }

  @override
  Future<CourseSchedule> createSchedule(String courseId, ScheduleDraft draft) =>
      _saveSchedule(courseId, null, draft);

  @override
  Future<CourseSchedule> updateSchedule(
    String courseId,
    String scheduleId,
    ScheduleDraft draft,
  ) => _saveSchedule(courseId, scheduleId, draft);

  Future<CourseSchedule> _saveSchedule(
    String courseId,
    String? scheduleId,
    ScheduleDraft draft,
  ) async {
    try {
      final data = {'jornada': draft.shift, 'horaLimite': draft.deadline};
      final response = scheduleId == null
          ? await _client.dio.post<Map<String, dynamic>>(
              '/cursos/$courseId/horarios',
              data: data,
            )
          : await _client.dio.patch<Map<String, dynamic>>(
              '/cursos/$courseId/horarios/$scheduleId',
              data: data,
            );
      return _schedule(response.data!);
    } on DioException catch (error) {
      throw CourseException(_message(error, 'No se pudo guardar el horario.'));
    }
  }

  @override
  Future<void> deactivateSchedule(String courseId, String scheduleId) async {
    try {
      await _client.dio.delete<void>('/cursos/$courseId/horarios/$scheduleId');
    } on DioException catch (error) {
      throw CourseException(_message(error, 'No se pudo retirar el horario.'));
    }
  }

  @override
  Future<List<WeeklyCourseSlot>> replaceWeeklySchedule(
    String courseId,
    Iterable<WeeklyCourseSlot> slots,
  ) async {
    try {
      final normalized = WeeklyCourseSlot.normalize(slots);
      final response = await _client.dio.put<Map<String, dynamic>>(
        '/cursos/$courseId/planilla-horaria',
        data: {
          'celdas': [
            for (final slot in normalized)
              {'diaSemana': slot.weekday, 'hora': slot.hour},
          ],
        },
      );
      return (response.data!['celdas'] as List<dynamic>? ?? const [])
          .map((item) => _weeklySlot(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw CourseException(
        _message(error, 'No se pudo guardar la planilla horaria.'),
      );
    }
  }

  CourseEntry _course(Map<String, dynamic> json) => CourseEntry(
    id: '${json['id']}',
    name: '${json['nombre']}',
    level: '${json['nivel']}',
    parallel: '${json['paralelo']}',
    year: (json['gestion'] as num).toInt(),
    studentCount: (json['cantidadEstudiantes'] as num?)?.toInt() ?? 0,
    teacherCount: (json['cantidadDocentes'] as num?)?.toInt() ?? 0,
    schedules: (json['horarios'] as List<dynamic>? ?? const [])
        .map((item) => _schedule(item as Map<String, dynamic>))
        .toList(),
    weeklySchedule: (json['planillaHorario'] as List<dynamic>? ?? const [])
        .map((item) => _weeklySlot(item as Map<String, dynamic>))
        .toList(),
  );

  CourseSchedule _schedule(Map<String, dynamic> json) => CourseSchedule(
    id: '${json['id']}',
    shift: '${json['jornada']}',
    deadline: '${json['horaLimite']}',
    toleranceMinutes: (json['toleranciaMinutos'] as num).toInt(),
    timeZone: '${json['zonaHoraria']}',
  );

  WeeklyCourseSlot _weeklySlot(Map<String, dynamic> json) => WeeklyCourseSlot(
    weekday: (json['diaSemana'] as num).toInt(),
    hour: (json['hora'] as num).toInt(),
  );

  String _message(DioException error, String fallback) {
    if (error.response?.statusCode == 401) {
      return 'Tu sesión venció. Cierra sesión e ingresa nuevamente.';
    }
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message'];
      if (message is List) return message.join('. ');
      return message?.toString() ?? fallback;
    }
    return fallback;
  }
}
