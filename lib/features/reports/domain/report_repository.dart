class ReportSummary {
  const ReportSummary({
    required this.from,
    required this.to,
    required this.consideredPeriods,
    required this.enrolledStudents,
    required this.punctualAttendances,
    required this.lateAttendances,
    required this.totalRecords,
    required this.schoolDays,
    required this.nonInstructionalDays,
    required this.expectedAttendances,
    required this.absences,
    required this.ignoredRecords,
    required this.attendancePercentage,
    required this.punctualityPercentage,
  });

  final DateTime from;
  final DateTime to;
  final int consideredPeriods;
  final int enrolledStudents;
  final int punctualAttendances;
  final int lateAttendances;
  final int totalRecords;
  final int schoolDays;
  final int nonInstructionalDays;
  final int expectedAttendances;
  final int absences;
  final int ignoredRecords;
  final double attendancePercentage;
  final double punctualityPercentage;
}

abstract interface class ReportRepository {
  Future<ReportSummary> getSummary({
    required DateTime from,
    required DateTime to,
    int? courseId,
  });

  Future<String> exportPdf({
    required DateTime from,
    required DateTime to,
    int? courseId,
  });
}

class ReportExportException implements Exception {
  const ReportExportException(this.message);
  final String message;
}
