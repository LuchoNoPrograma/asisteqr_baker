import 'package:asisteqr_baker/features/attendance/domain/attendance_models.dart';
import 'package:asisteqr_baker/features/attendance/domain/attendance_repository.dart';
import 'package:flutter/foundation.dart';

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel(this._repository) {
    load();
  }
  final AttendanceRepository _repository;
  DashboardSummary? summary;
  bool loading = true;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      summary = await _repository.getDashboard();
    } on Object {
      error = 'No se pudo cargar el resumen. Desliza para intentar de nuevo.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
