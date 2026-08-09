import 'package:asisteqr_baker/features/attendance/domain/attendance_models.dart';

abstract interface class AttendanceRepository {
  Future<DashboardSummary> getDashboard();
  Future<ScanResult> registerQr(String qrToken);
  Future<List<AttendanceRecord>> getDaily({
    String? course,
    AttendanceStatus? status,
  });
  Future<List<AttendanceRecord>> getStudentHistory(String studentId);
}
