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
  List<AttendanceShift> availableShifts = const [];
  AttendanceShift? selectedShift;
  bool loadingShifts = false;
  String? shiftsError;
  int _shiftLoadGeneration = 0;

  Future<void> loadShifts() async {
    final generation = ++_shiftLoadGeneration;
    loadingShifts = true;
    shiftsError = null;
    notifyListeners();
    try {
      final loaded = await _repository.getAvailableShifts();
      if (generation != _shiftLoadGeneration) return;
      availableShifts = List.unmodifiable(loaded);
      if (loaded.length == 1) {
        selectedShift = loaded.single;
      } else if (!loaded.contains(selectedShift)) {
        selectedShift = null;
      }
    } on AttendanceException catch (error) {
      if (generation != _shiftLoadGeneration) return;
      shiftsError = error.message;
    } on Object {
      if (generation != _shiftLoadGeneration) return;
      shiftsError = 'No se pudieron cargar las jornadas disponibles.';
    } finally {
      if (generation == _shiftLoadGeneration) {
        loadingShifts = false;
        notifyListeners();
      }
    }
  }

  void selectShift(AttendanceShift? shift) {
    if (selectedShift == shift) return;
    selectedShift = shift;
    notifyListeners();
  }

  Future<ScanResult?> submitQr(String token) =>
      _submitWithShift((shift) => _repository.registerQr(token, shift));

  Future<ScanResult?> submitManual(int studentCode) => _submitWithShift(
    (shift) => _repository.registerManual(studentCode, shift),
  );

  Future<ScanResult?> _submitWithShift(
    Future<ScanResult> Function(AttendanceShift shift) command,
  ) {
    final shift = selectedShift;
    if (shift == null) {
      failure = const AttendanceException(
        AttendanceFailureKind.missingShift,
        'Selecciona la jornada antes de registrar asistencia.',
      );
      phase = ScanPhase.failure;
      notifyListeners();
      return Future.value();
    }
    return _submit(() => command(shift));
  }

  Future<ScanResult?> _submit(Future<ScanResult> Function() command) async {
    if (phase == ScanPhase.validating) return null;
    phase = ScanPhase.validating;
    failure = null;
    notifyListeners();
    try {
      result = await command();
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

  @override
  void dispose() {
    _shiftLoadGeneration++;
    super.dispose();
  }
}
