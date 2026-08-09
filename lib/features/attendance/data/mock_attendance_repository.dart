import 'package:asisteqr_baker/features/attendance/domain/attendance_models.dart';
import 'package:asisteqr_baker/features/attendance/domain/attendance_repository.dart';

class MockAttendanceRepository implements AttendanceRepository {
  final _valeria = const Student(
    id: 'est-0148',
    code: 'EST-2026-0148',
    fullName: 'Valeria Mendoza Rojas',
    course: '4.º Secundaria B',
    photoSource: 'assets/images/valeria-mendoza.png',
  );

  Student _student(String id, String code, String name, String course) =>
      Student(
        id: id,
        code: code,
        fullName: name,
        course: course,
        photoSource: 'assets/images/valeria-mendoza.png',
      );

  List<AttendanceRecord> get _records {
    final now = DateTime.now();
    return [
      AttendanceRecord(
        id: 'a1',
        student: _valeria,
        timestamp: DateTime(now.year, now.month, now.day, 7, 52),
        status: AttendanceStatus.punctual,
      ),
      AttendanceRecord(
        id: 'a2',
        student: _student(
          'est-0109',
          'EST-2026-0109',
          'Carlos Martínez Silva',
          '4.º Secundaria A',
        ),
        timestamp: DateTime(now.year, now.month, now.day, 8, 15),
        status: AttendanceStatus.late,
      ),
      AttendanceRecord(
        id: 'a3',
        student: _student(
          'est-0201',
          'EST-2026-0201',
          'Ana Lucía Torres',
          '5.º Secundaria C',
        ),
        timestamp: DateTime(now.year, now.month, now.day, 7, 58),
        status: AttendanceStatus.punctual,
      ),
      AttendanceRecord(
        id: 'a4',
        student: _student(
          'est-0320',
          'EST-2026-0320',
          'Javier López Quispe',
          '3.º Secundaria B',
        ),
        timestamp: DateTime(now.year, now.month, now.day, 8, 21),
        status: AttendanceStatus.absent,
      ),
    ];
  }

  @override
  Future<DashboardSummary> getDashboard() async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    return DashboardSummary(
      expected: 342,
      present: 310,
      punctual: 285,
      late: 25,
      absent: 32,
      recent: _records.take(3).toList(),
    );
  }

  @override
  Future<ScanResult> registerQr(String qrToken) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    final token = qrToken.trim().toUpperCase();
    if (token.contains('INVALIDO') || token.contains('INVALID')) {
      throw const AttendanceException(
        AttendanceFailureKind.invalidQr,
        'El código QR no está registrado en AsisteQR Baker.',
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
      id: 'scan-${now.microsecondsSinceEpoch}',
      student: _valeria,
      timestamp: now,
      status: status,
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
  Future<List<AttendanceRecord>> getDaily({
    String? course,
    AttendanceStatus? status,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _records.where((item) {
      final matchesCourse = course == null || item.student.course == course;
      final matchesStatus = status == null || item.status == status;
      return matchesCourse && matchesStatus;
    }).toList();
  }

  @override
  Future<List<AttendanceRecord>> getStudentHistory(String studentId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    return List.generate(8, (index) {
      final status = index == 3
          ? AttendanceStatus.absent
          : index == 6
          ? AttendanceStatus.late
          : AttendanceStatus.punctual;
      return AttendanceRecord(
        id: 'hist-$index',
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
