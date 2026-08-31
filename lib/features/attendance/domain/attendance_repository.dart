import 'package:asisteqr_baker/features/attendance/domain/attendance_models.dart';

abstract interface class AttendanceRepository {
  Future<DashboardSummary> getDashboard();
  Future<List<AttendanceShift>> getAvailableShifts();
  Future<ScanResult> registerQr(String qrToken, AttendanceShift shift);
  Future<ScanResult> registerManual(int studentCode, AttendanceShift shift);
  Future<List<AttendanceRecord>> getDaily({
    DateTime? date,
    int? courseId,
    String? course,
    AttendanceStatus? status,
    AttendanceShift? shift,
  });
  Future<List<AttendanceRecord>> getStudentHistory(int studentId);
}
