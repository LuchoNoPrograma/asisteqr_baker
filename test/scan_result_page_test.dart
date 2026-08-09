import 'package:asisteqr_baker/app/theme/app_theme.dart';
import 'package:asisteqr_baker/features/attendance/domain/attendance_models.dart';
import 'package:asisteqr_baker/features/attendance/presentation/scan_result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CP-06 y CP-07 comunican atraso y puntualidad semánticamente', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpResult(tester, AttendanceStatus.late);
    expect(find.text('Atraso registrado'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Estado Atraso')), findsOneWidget);

    await _pumpResult(tester, AttendanceStatus.punctual);
    expect(find.text('Registro exitoso'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Estado Puntual')), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}

Future<void> _pumpResult(WidgetTester tester, AttendanceStatus status) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: ScanResultPage(
        result: ScanResult(
          record: AttendanceRecord(
            id: 'record-${status.name}',
            student: const Student(
              id: 'student-test',
              code: 'EST-2026-0148',
              fullName: 'Valeria Mendoza Rojas',
              course: '4.º Secundaria B',
            ),
            timestamp: DateTime(2026, 8, 8, 8, 10),
            status: status,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
