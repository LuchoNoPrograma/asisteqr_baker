import 'package:asisteqr_baker/features/attendance/domain/attendance_models.dart';
import 'package:asisteqr_baker/features/attendance/domain/attendance_repository.dart';
import 'package:flutter/foundation.dart';

enum ScanPhase { ready, validating, success, failure }

class ScannerViewModel extends ChangeNotifier {
  ScannerViewModel(this._repository);
  final AttendanceRepository _repository;
  ScanPhase phase = ScanPhase.ready;
  ScanResult? result;
  AttendanceException? failure;

  Future<ScanResult?> submit(String token) async {
    if (phase == ScanPhase.validating) return null;
    phase = ScanPhase.validating;
    failure = null;
    notifyListeners();
    try {
      result = await _repository.registerQr(token);
      phase = ScanPhase.success;
      notifyListeners();
      return result;
    } on AttendanceException catch (error) {
      failure = error;
      phase = ScanPhase.failure;
      notifyListeners();
      return null;
    } on Object {
      failure = const AttendanceException(
        AttendanceFailureKind.unknown,
        'Ocurrió un problema al validar la credencial.',
      );
      phase = ScanPhase.failure;
      notifyListeners();
      return null;
    }
  }

  void retry() {
    phase = ScanPhase.ready;
    failure = null;
    notifyListeners();
  }
}
