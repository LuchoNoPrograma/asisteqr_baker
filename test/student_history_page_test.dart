import 'package:asisteqr_baker/app/providers.dart';
import 'package:asisteqr_baker/features/attendance/data/mock_attendance_repository.dart';
import 'package:asisteqr_baker/features/attendance/domain/attendance_models.dart';
import 'package:asisteqr_baker/features/attendance/presentation/student_history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
