import 'package:asisteqr_baker/core/network/api_client.dart';
import 'package:asisteqr_baker/features/people/domain/people_models.dart';
import 'package:asisteqr_baker/features/people/domain/people_repository.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class ApiPeopleRepository implements PeopleRepository {
  ApiPeopleRepository(this._client);
  final ApiClient _client;

  @override
  Future<List<CourseOption>> getCourses() async {
    try {
      final response = await _client.dio.get<List<dynamic>>('/cursos');
      return response.data!
          .map((item) => item as Map<String, dynamic>)
          .map(
            (item) =>
                CourseOption(id: '${item['id']}', name: '${item['nombre']}'),
          )
          .toList();
    } on DioException catch (error) {
      throw PeopleException(
        _message(error, 'No se pudieron cargar los cursos.'),
      );
    }
  }

  @override
  Future<List<StudentEntry>> getStudents({String? search}) async {
    try {
      final response = await _client.dio.get<List<dynamic>>(
        '/estudiantes',
        queryParameters: {'buscar': ?search},
      );
      return response.data!
          .map((item) => _student(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw PeopleException(
        _message(error, 'No se pudieron cargar los estudiantes.'),
      );
    }
  }

  @override
  Future<StudentEntry> createStudent(StudentDraft draft) =>
      _saveStudent(null, draft);

  @override
  Future<StudentEntry> updateStudent(String id, StudentDraft draft) =>
      _saveStudent(id, draft);

  Future<StudentEntry> _saveStudent(String? id, StudentDraft draft) async {
    try {
      final data = {
        'nombres': draft.firstNames,
        'apellidos': draft.lastNames,
        'numeroDocumento': _optional(draft.documentNumber),
        'fechaNacimiento': DateFormat('yyyy-MM-dd').format(draft.birthDate),
        'nombreTutor': draft.guardianName,
        'telefonoTutor': _optional(draft.guardianPhone),
        'fotografiaUrl': _optional(draft.photoUrl),
        'cursoId': draft.courseId,
      };
      final response = id == null
          ? await _client.dio.post<Map<String, dynamic>>(
              '/estudiantes',
              data: data,
            )
          : await _client.dio.patch<Map<String, dynamic>>(
              '/estudiantes/$id',
              data: data,
            );
      return _student(response.data!);
    } on DioException catch (error) {
      throw PeopleException(
        _message(error, 'No se pudo guardar el estudiante.'),
      );
    }
  }

  @override
  Future<void> retireStudent(String id) async {
    try {
      await _client.dio.delete<void>('/estudiantes/$id');
    } on DioException catch (error) {
      throw PeopleException(
        _message(error, 'No se pudo retirar el estudiante.'),
      );
    }
  }

  @override
  Future<List<TeacherEntry>> getTeachers({String? search}) async {
    try {
      final response = await _client.dio.get<List<dynamic>>(
        '/docentes',
        queryParameters: {'buscar': ?search},
      );
      return response.data!
          .map((item) => _teacher(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw PeopleException(
        _message(error, 'No se pudieron cargar los docentes.'),
      );
    }
  }

  @override
  Future<TeacherEntry> createTeacher(TeacherDraft draft) =>
      _saveTeacher(null, draft);

  @override
  Future<TeacherEntry> updateTeacher(String id, TeacherDraft draft) =>
      _saveTeacher(id, draft);

  Future<TeacherEntry> _saveTeacher(String? id, TeacherDraft draft) async {
    try {
      final data = {
        'nombres': draft.firstNames,
        'apellidos': draft.lastNames,
        'numeroDocumento': _optional(draft.documentNumber),
        'especialidad': draft.specialty,
        'correo': _optional(draft.email),
        'telefono': _optional(draft.phone),
        'fotografiaUrl': _optional(draft.photoUrl),
        'cursoIds': draft.courseIds,
      };
      final response = id == null
          ? await _client.dio.post<Map<String, dynamic>>(
              '/docentes',
              data: data,
            )
          : await _client.dio.patch<Map<String, dynamic>>(
              '/docentes/$id',
              data: data,
            );
      return _teacher(response.data!);
    } on DioException catch (error) {
      throw PeopleException(_message(error, 'No se pudo guardar el docente.'));
    }
  }

  @override
  Future<void> deactivateTeacher(String id) async {
    try {
      await _client.dio.delete<void>('/docentes/$id');
    } on DioException catch (error) {
      throw PeopleException(
        _message(error, 'No se pudo inactivar el docente.'),
      );
    }
  }

  StudentEntry _student(Map<String, dynamic> json) {
    final course = json['curso'] as Map<String, dynamic>?;
    return StudentEntry(
      id: '${json['id']}',
      studentCode: (json['codigoEstudiante'] as num).toInt(),
      firstNames: '${json['nombres']}',
      lastNames: '${json['apellidos']}',
      birthDate: json['fechaNacimiento'] == null
          ? null
          : DateTime.tryParse(json['fechaNacimiento'].toString()),
      documentNumber: json['numeroDocumento']?.toString(),
      guardianName: json['nombreTutor']?.toString(),
      guardianPhone: json['telefonoTutor']?.toString(),
      photoUrl: json['fotografiaUrl']?.toString(),
      status: '${json['estado']}',
      course: course == null
          ? null
          : CourseOption(id: '${course['id']}', name: '${course['nombre']}'),
    );
  }

  TeacherEntry _teacher(Map<String, dynamic> json) => TeacherEntry(
    id: '${json['id']}',
    teacherCode: (json['codigoDocente'] as num).toInt(),
    firstNames: '${json['nombres']}',
    lastNames: '${json['apellidos']}',
    specialty: '${json['especialidad']}',
    documentNumber: json['numeroDocumento']?.toString(),
    email: json['correo']?.toString(),
    phone: json['telefono']?.toString(),
    photoUrl: json['fotografiaUrl']?.toString(),
    status: '${json['estado']}',
    courses: (json['cursos'] as List<dynamic>)
        .map((item) => item as Map<String, dynamic>)
        .map(
          (item) =>
              CourseOption(id: '${item['id']}', name: '${item['nombre']}'),
        )
        .toList(),
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

  String? _optional(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
