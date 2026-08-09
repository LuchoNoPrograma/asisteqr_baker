import 'package:asisteqr_baker/features/reports/domain/report_repository.dart';
import 'package:flutter/foundation.dart';

enum ReportExportStatus { idle, exporting, success, failure }

class ReportExportViewModel extends ChangeNotifier {
  ReportExportViewModel(this._repository);

  final ReportRepository _repository;
  ReportExportStatus status = ReportExportStatus.idle;
  String? message;
  ReportSummary? summary;
  bool loading = false;
  String? loadError;
  DateTime? from;
  DateTime? to;
  String? courseId;

  Future<void> load(
    String period, {
    String? selectedCourseId,
    DateTime? referenceDate,
  }) async {
    final range = _range(period, referenceDate ?? DateTime.now());
    loading = true;
    loadError = null;
    courseId = selectedCourseId;
    from = range.$1;
    to = range.$2;
    notifyListeners();
    try {
      summary = await _repository.getSummary(
        from: range.$1,
        to: range.$2,
        courseId: selectedCourseId,
      );
    } on ReportExportException catch (error) {
      loadError = error.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> export(String period) async {
    status = ReportExportStatus.exporting;
    message = null;
    notifyListeners();

    final range = _range(period, DateTime.now());
    final exportFrom = from ?? range.$1;
    final exportTo = to ?? range.$2;

    try {
      await _repository.exportPdf(
        from: exportFrom,
        to: exportTo,
        courseId: courseId,
      );
      status = ReportExportStatus.success;
      message = 'Reporte PDF exportado correctamente.';
      notifyListeners();
      return true;
    } on ReportExportException catch (error) {
      status = ReportExportStatus.failure;
      message = error.message;
      notifyListeners();
      return false;
    }
  }

  (DateTime, DateTime) _range(String period, DateTime referenceDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );
    DateTime notAfterToday(DateTime value) =>
        value.isAfter(today) ? today : value;
    return switch (period) {
      'Diario' => (selected, selected),
      'Mensual' => (
        DateTime(selected.year, selected.month),
        notAfterToday(DateTime(selected.year, selected.month + 1, 0)),
      ),
      _ => (
        DateTime(
          selected.year,
          selected.month,
          selected.day - selected.weekday + 1,
        ),
        notAfterToday(
          DateTime(
            selected.year,
            selected.month,
            selected.day - selected.weekday + 7,
          ),
        ),
      ),
    };
  }
}
