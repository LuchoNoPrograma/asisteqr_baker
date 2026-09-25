import 'dart:async';

import 'package:sis_amerinst/features/reports/domain/report_repository.dart';
import 'package:sis_amerinst/features/reports/presentation/report_export_view_model.dart';
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
        selectedCourseId: 1,
        referenceDate: selectedDate,
      );

      expect(model.loading, isFalse);
      expect(model.summary?.totalRecords, 8);
      expect(repository.summaryCourseId, 1);
      expect(repository.summaryFrom, DateTime(2025, 4, 14));
      expect(repository.summaryTo, DateTime(2025, 4, 20));
      expect(await model.export('Semanal'), isTrue);
      expect(repository.exportCourseId, 1);
      expect(repository.exportFrom, repository.summaryFrom);
      expect(repository.exportTo, repository.summaryTo);

      await model.load(
        'Mensual',
        selectedCourseId: 1,
        referenceDate: selectedDate,
      );

      expect(repository.summaryFrom, DateTime(2025, 4));
      expect(repository.summaryTo, DateTime(2025, 4, 30));
      expect(await model.export('Mensual'), isTrue);
      expect(repository.exportFrom, repository.summaryFrom);
      expect(repository.exportTo, repository.summaryTo);
    },
  );

  test(
    'descarta una respuesta de reporte anterior al filtro vigente',
    () async {
      final repository = _DeferredReportRepository();
      final model = ReportExportViewModel(repository);

      final oldLoad = model.load(
        'Diario',
        selectedCourseId: 1,
        referenceDate: DateTime(2026, 8, 20),
      );
      final currentLoad = model.load(
        'Diario',
        selectedCourseId: 2,
        referenceDate: DateTime(2026, 8, 21),
      );

      repository.loads[1].complete(_summary(totalRecords: 2));
      await currentLoad;

      expect(model.summary?.totalRecords, 2);
      expect(model.courseId, 2);
      expect(model.loading, isFalse);

      repository.loads[0].completeError(
        const ReportExportException('Error de un filtro anterior'),
      );
      await oldLoad;

      expect(model.summary?.totalRecords, 2);
      expect(model.loadError, isNull);
      expect(model.loading, isFalse);
    },
  );
}

ReportSummary _summary({required int totalRecords}) => ReportSummary(
  from: DateTime(2026, 8, 21),
  to: DateTime(2026, 8, 21),
  consideredPeriods: 1,
  enrolledStudents: 2,
  punctualAttendances: totalRecords,
  lateAttendances: 0,
  totalRecords: totalRecords,
  schoolDays: 1,
  nonInstructionalDays: 0,
  expectedAttendances: 2,
  absences: 0,
  ignoredRecords: 0,
  attendancePercentage: 100,
  punctualityPercentage: 100,
);

class _DeferredReportRepository implements ReportRepository {
  final loads = <Completer<ReportSummary>>[];

  @override
  Future<ReportSummary> getSummary({
    required DateTime from,
    required DateTime to,
    int? courseId,
  }) {
    final load = Completer<ReportSummary>();
    loads.add(load);
    return load.future;
  }

  @override
  Future<String> exportPdf({
    required DateTime from,
    required DateTime to,
    int? courseId,
  }) => throw UnimplementedError();
}

class _ReportRepository implements ReportRepository {
  DateTime? summaryFrom;
  DateTime? summaryTo;
  int? summaryCourseId;
  DateTime? exportFrom;
  DateTime? exportTo;
  int? exportCourseId;

  @override
  Future<ReportSummary> getSummary({
    required DateTime from,
    required DateTime to,
    int? courseId,
  }) async {
    summaryFrom = from;
    summaryTo = to;
    summaryCourseId = courseId;
    return ReportSummary(
      from: from,
      to: to,
      consideredPeriods: 1,
      enrolledStudents: 2,
      punctualAttendances: 7,
      lateAttendances: 1,
      totalRecords: 8,
      schoolDays: 5,
      nonInstructionalDays: 0,
      expectedAttendances: 10,
      absences: 2,
      ignoredRecords: 0,
      attendancePercentage: 80,
      punctualityPercentage: 87.5,
    );
  }

  @override
  Future<String> exportPdf({
    required DateTime from,
    required DateTime to,
    int? courseId,
  }) async {
    exportFrom = from;
    exportTo = to;
    exportCourseId = courseId;
    return '/tmp/report.pdf';
  }
}
