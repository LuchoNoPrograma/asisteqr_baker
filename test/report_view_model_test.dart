import 'package:asisteqr_baker/features/reports/domain/report_repository.dart';
import 'package:asisteqr_baker/features/reports/presentation/report_export_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'CP-10 y CP-11 cargan rangos semanal y mensual y exportan el filtro activo',
    () async {
      final repository = _ReportRepository();
      final model = ReportExportViewModel(repository);
      final selectedDate = DateTime(2025, 4, 16);

      await model.load(
        'Semanal',
        selectedCourseId: 'course-1',
        referenceDate: selectedDate,
      );

      expect(model.loading, isFalse);
      expect(model.summary?.totalRecords, 8);
      expect(repository.summaryCourseId, 'course-1');
      expect(repository.summaryFrom, DateTime(2025, 4, 14));
      expect(repository.summaryTo, DateTime(2025, 4, 20));
      expect(await model.export('Semanal'), isTrue);
      expect(repository.exportCourseId, 'course-1');
      expect(repository.exportFrom, repository.summaryFrom);
      expect(repository.exportTo, repository.summaryTo);

      await model.load(
        'Mensual',
        selectedCourseId: 'course-1',
        referenceDate: selectedDate,
      );

      expect(repository.summaryFrom, DateTime(2025, 4));
      expect(repository.summaryTo, DateTime(2025, 4, 30));
      expect(await model.export('Mensual'), isTrue);
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
