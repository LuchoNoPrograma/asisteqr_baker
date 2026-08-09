import 'package:asisteqr_baker/core/network/api_client.dart';
import 'package:asisteqr_baker/features/attendance/domain/attendance_models.dart';
import 'package:asisteqr_baker/features/attendance/domain/attendance_repository.dart';
import 'package:dio/dio.dart';

class ApiAttendanceRepository implements AttendanceRepository {
  ApiAttendanceRepository(this._client);
  final ApiClient _client;

  @override
  Future<ScanResult> registerQr(String qrToken) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/asistencias/escanear',
        data: {'tokenQr': qrToken},
      );
      return _scanFromJson(response.data!);
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      final message = (error.response?.data as Map?)?['mensaje']?.toString();
      throw AttendanceException(
        status == 404
            ? AttendanceFailureKind.invalidQr
            : status == 403
            ? AttendanceFailureKind.unauthorized
            : AttendanceFailureKind.network,
        message ?? 'No se pudo validar la credencial. Revisa la conexión.',
      );
    }
  }

  @override
  Future<DashboardSummary> getDashboard() async {
    final records = await getDaily();
    final present = records
        .where((item) => item.status != AttendanceStatus.absent)
        .toList();
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
    );
  }

  @override
  Future<List<AttendanceRecord>> getDaily({
    String? course,
    AttendanceStatus? status,
  }) async {
    final response = await _client.dio.get<List<dynamic>>(
      '/asistencias/diaria',
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
  Future<List<AttendanceRecord>> getStudentHistory(String studentId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/estudiantes/$studentId/historial',
    );
    final body = response.data!;
    final studentJson = body['estudiante'] as Map<String, dynamic>;
    return (body['registros'] as List<dynamic>).map((item) {
      final record = item as Map<String, dynamic>;
      return AttendanceRecord(
        id: record['id'].toString(),
        student: Student(
          id: studentJson['id'].toString(),
          code: studentJson['codigo'].toString(),
          fullName: studentJson['nombreCompleto'].toString(),
          course: record['curso'].toString(),
          photoSource: studentJson['fotografiaUrl']?.toString(),
        ),
        timestamp: DateTime.parse(record['fechaHora'].toString()).toLocal(),
        status: record['estado'] == 'ATRASO'
            ? AttendanceStatus.late
            : AttendanceStatus.punctual,
      );
    }).toList();
  }

  ScanResult _scanFromJson(Map<String, dynamic> json) {
    final studentJson = json['estudiante'] as Map<String, dynamic>;
    final student = Student(
      id: studentJson['id'].toString(),
      code: studentJson['codigo'].toString(),
      fullName: studentJson['nombreCompleto'].toString(),
      course: studentJson['curso'].toString(),
      photoSource: studentJson['fotografiaUrl']?.toString(),
    );
    final record = AttendanceRecord(
      id: json['id'].toString(),
      student: student,
      timestamp: DateTime.parse(json['fechaHora'].toString()).toLocal(),
      status: json['estado'] == 'ATRASO'
          ? AttendanceStatus.late
          : AttendanceStatus.punctual,
    );
    return ScanResult(record: record, duplicate: json['duplicado'] == true);
  }

  AttendanceRecord _dailyFromJson(Map<String, dynamic> json) {
    final studentJson = json['estudiante'] as Map<String, dynamic>;
    final courseJson = json['curso'] as Map<String, dynamic>;
    final statusValue = json['estado'].toString();
    return AttendanceRecord(
      id: '${studentJson['id']}-$statusValue',
      student: Student(
        id: studentJson['id'].toString(),
        code: studentJson['codigo'].toString(),
        fullName: studentJson['nombreCompleto'].toString(),
        course: courseJson['nombre'].toString(),
        photoSource: studentJson['fotografiaUrl']?.toString(),
      ),
      timestamp: json['fechaHora'] == null
          ? DateTime.now()
          : DateTime.parse(json['fechaHora'].toString()).toLocal(),
      status: switch (statusValue) {
        'ATRASO' => AttendanceStatus.late,
        'AUSENTE' => AttendanceStatus.absent,
        _ => AttendanceStatus.punctual,
      },
    );
  }
}
