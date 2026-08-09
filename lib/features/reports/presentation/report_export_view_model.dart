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

  Future<void> load(String period, {String? selectedCourseId}) async {
    final range = _range(period);
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

    final range = _range(period);
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

  (DateTime, DateTime) _range(String period) {
    final now = DateTime.now();
    return switch (period) {
      'Diario' => (DateTime(now.year, now.month, now.day), now),
      'Mensual' => (
        DateTime(now.year, now.month),
        DateTime(now.year, now.month + 1, 0),
      ),
      _ => (DateTime(now.year, now.month, now.day - now.weekday + 1), now),
    };
  }
}
