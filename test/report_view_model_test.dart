import 'package:asisteqr_baker/features/reports/domain/report_repository.dart';
import 'package:asisteqr_baker/features/reports/presentation/report_export_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'CP-10 carga el resumen semanal real y exporta el mismo filtro',
    () async {
      final repository = _ReportRepository();
      final model = ReportExportViewModel(repository);

      await model.load('Semanal', selectedCourseId: 'course-1');

      expect(model.loading, isFalse);
      expect(model.summary?.totalRecords, 8);
      expect(repository.summaryCourseId, 'course-1');
      expect(await model.export('Semanal'), isTrue);
      expect(repository.exportCourseId, 'course-1');
      expect(repository.exportFrom, repository.summaryFrom);
      expect(repository.exportTo, repository.summaryTo);
    },
  );
}

class _ReportRepository implements ReportRepository {
  DateTime? summaryFrom;
  DateTime? summaryTo;
  String? summaryCourseId;
  DateTime? exportFrom;
  DateTime? exportTo;
  String? exportCourseId;

  @override
  Future<ReportSummary> getSummary({
    required DateTime from,
    required DateTime to,
    String? courseId,
  }) async {
    summaryFrom = from;
    summaryTo = to;
    summaryCourseId = courseId;
    return ReportSummary(
      from: from,
      to: to,
      enrolledStudents: 2,
      punctualAttendances: 7,
      lateAttendances: 1,
      totalRecords: 8,
      schoolDays: 5,
      expectedAttendances: 10,
      absences: 2,
      attendancePercentage: 80,
      punctualityPercentage: 87.5,
    );
  }

  @override
  Future<String> exportPdf({
    required DateTime from,
    required DateTime to,
    String? courseId,
  }) async {
    exportFrom = from;
    exportTo = to;
    exportCourseId = courseId;
    return '/tmp/report.pdf';
  }
}
