import 'package:sis_amerinst/features/attendance/domain/attendance_models.dart';
import 'package:sis_amerinst/features/attendance/domain/attendance_repository.dart';

class MockAttendanceRepository implements AttendanceRepository {
  MockAttendanceRepository({
    this.availableShifts = const [
      AttendanceShift.morning,
      AttendanceShift.afternoon,
    ],
  });

  final List<AttendanceShift> availableShifts;

  final _valeria = const Student(
    id: 148,
    code: 'EST-2026-0148',
    fullName: 'Valeria Mendoza Rojas',
    course: '4.º Secundaria B',
    photoSource: 'assets/images/valeria-mendoza.png',
    gender: StudentGender.female,
  );

  Student _student(int id, String code, String name, String course) => Student(
    id: id,
    code: code,
    fullName: name,
    course: course,
    photoSource: 'assets/images/valeria-mendoza.png',
  );

  List<AttendanceRecord> _recordsAt(DateTime date) {
    return [
      AttendanceRecord(
        id: 1,
        student: _valeria,
        timestamp: DateTime(date.year, date.month, date.day, 7, 52),
        status: AttendanceStatus.punctual,
        shift: AttendanceShift.morning,
      ),
      AttendanceRecord(
        id: 2,
        student: _student(
          109,
          'EST-2026-0109',
          'Carlos Martínez Silva',
          '4.º Secundaria A',
        ),
        timestamp: DateTime(date.year, date.month, date.day, 8, 15),
        status: AttendanceStatus.late,
        shift: AttendanceShift.morning,
      ),
      AttendanceRecord(
        id: 3,
        student: _student(
          201,
          'EST-2026-0201',
          'Ana Lucía Torres',
          '5.º Secundaria C',
        ),
        timestamp: DateTime(date.year, date.month, date.day, 7, 58),
        status: AttendanceStatus.punctual,
        shift: AttendanceShift.morning,
      ),
      AttendanceRecord(
        id: null,
        student: _student(
          320,
          'EST-2026-0320',
          'Javier López Quispe',
          '3.º Secundaria B',
        ),
        timestamp: null,
        status: AttendanceStatus.absent,
        shift: AttendanceShift.morning,
      ),
    ];
  }

  @override
  Future<DashboardSummary> getDashboard() async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    final records = _recordsAt(DateTime.now());
    return DashboardSummary(
      expected: 342,
      present: 310,
      punctual: 285,
      late: 25,
      absent: 32,
      recent: records.take(3).toList(),
      courses: const [
        CourseAttendanceSummary(
          course: '3.º Secundaria B',
          expected: 82,
          present: 70,
          male: 41,
          female: 41,
          genderNotRegistered: 0,
        ),
        CourseAttendanceSummary(
          course: '4.º Secundaria A',
          expected: 86,
          present: 81,
          male: 44,
          female: 42,
          genderNotRegistered: 0,
        ),
        CourseAttendanceSummary(
          course: '4.º Secundaria B',
          expected: 88,
          present: 83,
          male: 46,
          female: 42,
          genderNotRegistered: 0,
        ),
        CourseAttendanceSummary(
          course: '5.º Secundaria C',
          expected: 86,
          present: 76,
          male: 40,
          female: 46,
          genderNotRegistered: 0,
        ),
      ],
    );
  }

  @override
  Future<List<AttendanceShift>> getAvailableShifts() async => availableShifts;

  @override
  Future<ScanResult> registerQr(String qrToken, AttendanceShift shift) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    final token = qrToken.trim().toUpperCase();
    if (token.contains('INVALIDO') || token.contains('INVALID')) {
      throw const AttendanceException(
        AttendanceFailureKind.invalidQr,
        'El código QR no está registrado en SIS AMERINST.',
      );
    }
    if (token.contains('DAÑADO') || token.contains('DAMAGED')) {
      throw const AttendanceException(
        AttendanceFailureKind.unreadableQr,
        'No pudimos leer el código completo. Limpia la credencial e inténtalo otra vez.',
      );
    }
    if (token.contains('INACTIVO')) {
      throw const AttendanceException(
        AttendanceFailureKind.inactiveStudent,
        'La credencial pertenece a un estudiante inactivo.',
      );
    }

    final now = DateTime.now();
    final status = now.hour > 8 || (now.hour == 8 && now.minute > 5)
        ? AttendanceStatus.late
        : AttendanceStatus.punctual;
    final record = AttendanceRecord(
      id: now.microsecondsSinceEpoch,
      student: _valeria,
      timestamp: now,
      status: status,
      shift: shift,
    );
    if (token.contains('DUPLICADO') || token.contains('DUPLICATE')) {
      return ScanResult(
        record: record,
        duplicate: true,
        originalTimestamp: DateTime(now.year, now.month, now.day, 7, 52),
      );
    }
    return ScanResult(record: record);
  }

  @override
  Future<ScanResult> registerManual(int studentCode, AttendanceShift shift) {
    if (studentCode != 148) {
      throw const AttendanceException(
        AttendanceFailureKind.studentNotFound,
        'No existe un estudiante con ese ID.',
      );
    }
    return registerQr('MANUAL-$studentCode', shift);
  }

  @override
  Future<List<AttendanceRecord>> getDaily({
    DateTime? date,
    int? courseId,
    String? course,
    AttendanceStatus? status,
    AttendanceShift? shift,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _recordsAt(date ?? DateTime.now()).where((item) {
      final matchesCourse = course == null || item.student.course == course;
      final matchesStatus = status == null || item.status == status;
      final matchesShift = shift == null || item.shift == shift;
      return matchesCourse && matchesStatus && matchesShift;
    }).toList();
  }

  @override
  Future<List<AttendanceRecord>> getStudentHistory(int studentId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    return List.generate(8, (index) {
      final status = index == 3
          ? AttendanceStatus.absent
          : index == 6
          ? AttendanceStatus.late
          : AttendanceStatus.punctual;
      return AttendanceRecord(
        id: index + 1,
        student: _valeria,
        timestamp: DateTime(
          now.year,
          now.month,
          now.day - index,
          status == AttendanceStatus.late ? 8 : 7,
          status == AttendanceStatus.late ? 14 : 51,
        ),
        status: status,
      );
    });
  }
}
