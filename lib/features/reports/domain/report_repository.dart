class ReportSummary {
  const ReportSummary({
    required this.from,
    required this.to,
    required this.enrolledStudents,
    required this.punctualAttendances,
    required this.lateAttendances,
    required this.totalRecords,
    required this.schoolDays,
    required this.expectedAttendances,
    required this.absences,
    required this.attendancePercentage,
    required this.punctualityPercentage,
  });

  final DateTime from;
  final DateTime to;
  final int enrolledStudents;
  final int punctualAttendances;
  final int lateAttendances;
  final int totalRecords;
  final int schoolDays;
  final int expectedAttendances;
  final int absences;
  final double attendancePercentage;
  final double punctualityPercentage;
}

abstract interface class ReportRepository {
  Future<ReportSummary> getSummary({
    required DateTime from,
    required DateTime to,
    String? courseId,
  });

  Future<String> exportPdf({
    required DateTime from,
    required DateTime to,
    String? courseId,
  });
}

class ReportExportException implements Exception {
  const ReportExportException(this.message);
  final String message;
}
