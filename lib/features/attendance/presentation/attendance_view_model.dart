import 'package:sis_amerinst/features/attendance/domain/attendance_models.dart';
import 'package:sis_amerinst/features/attendance/domain/attendance_repository.dart';
import 'package:flutter/foundation.dart';

class AttendanceViewModel extends ChangeNotifier {
  AttendanceViewModel(this._repository);

  final AttendanceRepository _repository;

  List<AttendanceRecord>? records;
  AttendanceStatus? status;
  AttendanceShift? shift;
  int? courseId;
  DateTime date = _dateOnly(DateTime.now());
  String? error;
  int _loadGeneration = 0;

  Future<void> load() async {
    final generation = ++_loadGeneration;
    records = null;
    error = null;
    notifyListeners();
    try {
      final loaded = await _repository.getDaily(
        date: date,
        courseId: courseId,
        status: status,
        shift: shift,
      );
      if (generation != _loadGeneration) return;
      records = List.unmodifiable(loaded);
    } on Object {
      if (generation != _loadGeneration) return;
      error = 'No se pudo cargar la asistencia diaria.';
    } finally {
      if (generation == _loadGeneration) notifyListeners();
    }
  }

  Future<void> selectDate(DateTime value) {
    date = _dateOnly(value);
    return load();
  }

  Future<void> filterCourse(int? value) {
    courseId = value;
    return load();
  }

  Future<void> filterStatus(AttendanceStatus? value) {
    status = value;
    return load();
  }

  Future<void> filterShift(AttendanceShift? value) {
    shift = value;
    return load();
  }

  Future<void> clearFilters() {
    courseId = null;
    status = null;
    shift = null;
    date = _dateOnly(DateTime.now());
    return load();
  }

  @override
  void dispose() {
    _loadGeneration++;
    super.dispose();
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
