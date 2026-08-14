import 'package:asisteqr_baker/features/attendance/domain/attendance_models.dart';

abstract interface class AttendanceRepository {
  Future<DashboardSummary> getDashboard();
  Future<ScanResult> registerQr(String qrToken);
  Future<ScanResult> registerManual(int studentCode);
  Future<List<AttendanceRecord>> getDaily({
    DateTime? date,
    String? courseId,
    String? course,
    AttendanceStatus? status,
  });
  Future<List<AttendanceRecord>> getStudentHistory(String studentId);
}
