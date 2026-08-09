import 'package:asisteqr_baker/app/providers.dart';
import 'package:asisteqr_baker/features/attendance/data/mock_attendance_repository.dart';
import 'package:asisteqr_baker/features/attendance/domain/attendance_models.dart';
import 'package:asisteqr_baker/features/attendance/presentation/student_history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  testWidgets('CP-12 y CP-13 muestran historial e identidad del propietario', (
    tester,
  ) async {
    final repository = _LoadedHistoryRepository();
    await _pumpHistory(tester, repository);

    expect(repository.requestedStudentId, 'student-test');
    expect(find.text('Valeria Mendoza Rojas'), findsOneWidget);
    expect(find.text('EST-2026-0148'), findsOneWidget);
    expect(find.text('4.º Secundaria B'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('Atrasos'), findsOneWidget);
    expect(find.text('Ausencia'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('muestra un estado vacío cuando no existen registros', (
    tester,
  ) async {
    await _pumpHistory(tester, _EmptyHistoryRepository());

    expect(
      find.text('Este estudiante todavía no tiene registros.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('muestra el error de carga y permite reintentar', (tester) async {
    final repository = _FailingHistoryRepository();
    await _pumpHistory(tester, repository);

    expect(find.text('No se pudo cargar el historial'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(repository.requests, 2);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpHistory(
  WidgetTester tester,
  MockAttendanceRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [attendanceRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(
        home: StudentHistoryPage(studentId: 'student-test'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _EmptyHistoryRepository extends MockAttendanceRepository {
  @override
  Future<List<AttendanceRecord>> getStudentHistory(String studentId) async =>
      const [];
}

class _FailingHistoryRepository extends MockAttendanceRepository {
  int requests = 0;

  @override
  Future<List<AttendanceRecord>> getStudentHistory(String studentId) async {
    requests++;
    throw const AttendanceException(
      AttendanceFailureKind.network,
      'Fallo controlado',
    );
  }
}

class _LoadedHistoryRepository extends MockAttendanceRepository {
  String? requestedStudentId;

  @override
  Future<List<AttendanceRecord>> getStudentHistory(String studentId) async {
    requestedStudentId = studentId;
    const student = Student(
      id: 'student-test',
      code: 'EST-2026-0148',
      fullName: 'Valeria Mendoza Rojas',
      course: '4.º Secundaria B',
      photoSource: 'assets/images/valeria-mendoza.png',
    );
    return [
      AttendanceRecord(
        id: 'history-1',
        student: student,
        timestamp: DateTime(2026, 8, 8, 7, 50),
        status: AttendanceStatus.punctual,
      ),
      AttendanceRecord(
        id: 'history-2',
        student: student,
        timestamp: DateTime(2026, 8, 7, 8, 12),
        status: AttendanceStatus.late,
      ),
    ];
  }
}
