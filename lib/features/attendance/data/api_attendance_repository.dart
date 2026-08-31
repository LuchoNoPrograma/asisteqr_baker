import 'package:asisteqr_baker/core/network/api_client.dart';
import 'package:asisteqr_baker/features/attendance/domain/attendance_models.dart';
import 'package:asisteqr_baker/features/attendance/domain/attendance_repository.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class ApiAttendanceRepository implements AttendanceRepository {
  ApiAttendanceRepository(this._client);
  final ApiClient _client;

  @override
  Future<List<AttendanceShift>> getAvailableShifts() async {
    try {
      final response = await _client.dio.get<List<dynamic>>(
        '/asistencias/jornadas',
      );
      return response.data!
          .map(
            (item) => AttendanceShift.fromApi(
              (item as Map<String, dynamic>)['jornada'].toString(),
            ),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw _attendanceException(
        error,
        notFoundKind: AttendanceFailureKind.missingSchedule,
        fallback: 'No se pudieron cargar las jornadas disponibles.',
      );
    }
  }

  @override
  Future<ScanResult> registerQr(String qrToken, AttendanceShift shift) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/asistencias/escanear',
        data: {'tokenQr': qrToken, 'jornada': shift.apiValue},
      );
      return _scanFromJson(response.data!);
    } on DioException catch (error) {
      throw _attendanceException(
        error,
        notFoundKind: AttendanceFailureKind.invalidQr,
        fallback: 'No se pudo validar la credencial. Revisa la conexión.',
      );
    }
  }

  @override
  Future<ScanResult> registerManual(
    int studentCode,
    AttendanceShift shift,
  ) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/asistencias/manual',
        data: {'codigoEstudiante': studentCode, 'jornada': shift.apiValue},
      );
      return _scanFromJson(response.data!);
    } on DioException catch (error) {
      throw _attendanceException(
        error,
        notFoundKind: AttendanceFailureKind.studentNotFound,
        fallback: 'No se pudo registrar la asistencia. Revisa la conexión.',
      );
    }
  }

  @override
  Future<DashboardSummary> getDashboard() async {
    final records = await getDaily();
    final present =
        records.where((item) => item.status != AttendanceStatus.absent).toList()
          ..sort(
            (first, second) => second.timestamp!.compareTo(first.timestamp!),
          );
    return DashboardSummary(
      expected: records.length,
      present: present.length,
      punctual: records
          .where((item) => item.status == AttendanceStatus.punctual)
          .length,
      late: records
          .where((item) => item.status == AttendanceStatus.late)
          .length,
      absent: records
          .where((item) => item.status == AttendanceStatus.absent)
          .length,
      recent: present.take(5).toList(),
      courses: _courseSummaries(records),
    );
  }

  @override
  Future<List<AttendanceRecord>> getDaily({
    DateTime? date,
    int? courseId,
    String? course,
    AttendanceStatus? status,
    AttendanceShift? shift,
  }) async {
    final formattedDate = date == null
        ? null
        : DateFormat('yyyy-MM-dd').format(date);
    final response = await _client.dio.get<List<dynamic>>(
      '/asistencias/diaria',
      queryParameters: {
        'fecha': ?formattedDate,
        'cursoId': ?courseId,
        'jornada': ?shift?.apiValue,
      },
    );
    return response.data!
        .map((item) => _dailyFromJson(item as Map<String, dynamic>))
        .where((item) {
          final matchesCourse = course == null || item.student.course == course;
          final matchesStatus = status == null || item.status == status;
          return matchesCourse && matchesStatus;
        })
        .toList();
  }

  @override
  Future<List<AttendanceRecord>> getStudentHistory(int studentId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/estudiantes/$studentId/historial',
    );
    final body = response.data!;
    final studentJson = body['estudiante'] as Map<String, dynamic>;
    return (body['registros'] as List<dynamic>).map((item) {
      final record = item as Map<String, dynamic>;
      return AttendanceRecord(
        id: (record['id'] as num).toInt(),
        student: Student(
          id: (studentJson['id'] as num).toInt(),
          code: studentJson['codigo'].toString(),
          fullName: studentJson['nombreCompleto'].toString(),
          course: record['curso'].toString(),
          photoSource: studentJson['fotografiaUrl']?.toString(),
          gender: _studentGender(studentJson),
        ),
        timestamp: DateTime.parse(record['fechaHora'].toString()).toLocal(),
        status: record['estado'] == 'ATRASO'
            ? AttendanceStatus.late
            : AttendanceStatus.punctual,
        scheduleId: ((record['horario'] as Map?)?['id'] as num?)?.toInt(),
        shift: _optionalShift(record),
      );
    }).toList();
  }

  ScanResult _scanFromJson(Map<String, dynamic> json) {
    final studentJson = json['estudiante'] as Map<String, dynamic>;
    final student = Student(
      id: (studentJson['id'] as num).toInt(),
      code: studentJson['codigo'].toString(),
      fullName: studentJson['nombreCompleto'].toString(),
      course: studentJson['curso'].toString(),
      photoSource: studentJson['fotografiaUrl']?.toString(),
      gender: _studentGender(studentJson),
    );
    final record = AttendanceRecord(
      id: (json['id'] as num).toInt(),
      student: student,
      timestamp: DateTime.parse(json['fechaHora'].toString()).toLocal(),
      status: json['estado'] == 'ATRASO'
          ? AttendanceStatus.late
          : AttendanceStatus.punctual,
      scheduleId: ((json['horario'] as Map<String, dynamic>)['id'] as num)
          .toInt(),
      shift: AttendanceShift.fromApi(
        (json['horario'] as Map<String, dynamic>)['jornada'].toString(),
      ),
    );
    return ScanResult(record: record, duplicate: json['duplicado'] == true);
  }

  AttendanceRecord _dailyFromJson(Map<String, dynamic> json) {
    final studentJson = json['estudiante'] as Map<String, dynamic>;
    final courseJson = json['curso'] as Map<String, dynamic>;
    final scheduleJson = json['horario'] as Map<String, dynamic>;
    final statusValue = json['estado'].toString();
    return AttendanceRecord(
      id: (json['id'] as num?)?.toInt(),
      student: Student(
        id: (studentJson['id'] as num).toInt(),
        code: studentJson['codigo'].toString(),
        fullName: studentJson['nombreCompleto'].toString(),
        course: courseJson['nombre'].toString(),
        photoSource: studentJson['fotografiaUrl']?.toString(),
        gender: _studentGender(studentJson),
      ),
      timestamp: json['fechaHora'] == null
          ? null
          : DateTime.parse(json['fechaHora'].toString()).toLocal(),
      status: switch (statusValue) {
        'ATRASO' => AttendanceStatus.late,
        'AUSENTE' => AttendanceStatus.absent,
        _ => AttendanceStatus.punctual,
      },
      scheduleId: (scheduleJson['id'] as num).toInt(),
      shift: AttendanceShift.fromApi(scheduleJson['jornada'].toString()),
    );
  }

  AttendanceShift? _optionalShift(Map<String, dynamic> json) {
    final schedule = json['horario'];
    if (schedule is Map && schedule['jornada'] != null) {
      return AttendanceShift.fromApi(schedule['jornada'].toString());
    }
    if (json['jornada'] != null) {
      return AttendanceShift.fromApi(json['jornada'].toString());
    }
    return null;
  }

  List<CourseAttendanceSummary> _courseSummaries(
    List<AttendanceRecord> records,
  ) {
    final byCourse = <String, List<AttendanceRecord>>{};
    for (final record in records) {
      byCourse.putIfAbsent(record.student.course, () => []).add(record);
    }
    final summaries = byCourse.entries.map((entry) {
      final courseRecords = entry.value;
      final male = courseRecords
          .where((item) => item.student.gender == StudentGender.male)
          .length;
      final female = courseRecords
          .where((item) => item.student.gender == StudentGender.female)
          .length;
      return CourseAttendanceSummary(
        course: entry.key,
        expected: courseRecords.length,
        present: courseRecords
            .where((item) => item.status != AttendanceStatus.absent)
            .length,
        male: male,
        female: female,
        genderNotRegistered: courseRecords.length - male - female,
      );
    }).toList()..sort((left, right) => left.course.compareTo(right.course));
    return summaries;
  }

  StudentGender? _studentGender(Map<String, dynamic> json) {
    final value = (json['genero'] ?? json['sexo'])?.toString().toUpperCase();
    return switch (value) {
      'M' || 'MASCULINO' || 'HOMBRE' => StudentGender.male,
      'F' || 'FEMENINO' || 'MUJER' => StudentGender.female,
      _ => null,
    };
  }

  AttendanceException _attendanceException(
    DioException error, {
    required AttendanceFailureKind notFoundKind,
    required String fallback,
  }) {
    final status = error.response?.statusCode;
    final body = error.response?.data;
    final code = body is Map ? body['code']?.toString() : null;
    final rawMessage = body is Map ? body['message'] ?? body['mensaje'] : null;
    final message = switch (rawMessage) {
      List<dynamic> values => values.join('\n'),
      null => null,
      _ => rawMessage.toString(),
    };
    final kind = switch (code) {
      'QR_INVALIDO' => AttendanceFailureKind.invalidQr,
      'ESTUDIANTE_NO_ENCONTRADO' => AttendanceFailureKind.studentNotFound,
      'ESTUDIANTE_INACTIVO' => AttendanceFailureKind.inactiveStudent,
      'INSCRIPCION_ACTIVA_AUSENTE' => AttendanceFailureKind.missingEnrollment,
      'HORARIO_ACTIVO_AUSENTE' => AttendanceFailureKind.missingSchedule,
      'HORARIO_JORNADA_AUSENTE' => AttendanceFailureKind.missingSchedule,
      'CONFIGURACION_HORARIA_AUSENTE' =>
        AttendanceFailureKind.missingScheduleConfiguration,
      _ => switch (status) {
        401 || 403 => AttendanceFailureKind.unauthorized,
        404 => notFoundKind,
        400 => AttendanceFailureKind.unknown,
        _ => AttendanceFailureKind.network,
      },
    };
    return AttendanceException(kind, message ?? fallback);
  }
}
