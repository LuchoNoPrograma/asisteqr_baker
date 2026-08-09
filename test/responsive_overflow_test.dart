import 'package:asisteqr_baker/app/app.dart';
import 'package:asisteqr_baker/app/providers.dart';
import 'package:asisteqr_baker/app/router/app_router.dart';
import 'package:asisteqr_baker/features/attendance/data/mock_attendance_repository.dart';
import 'package:asisteqr_baker/features/attendance/domain/attendance_models.dart';
import 'package:asisteqr_baker/features/auth/data/auth_repositories.dart';
import 'package:asisteqr_baker/features/courses/data/mock_course_repository.dart';
import 'package:asisteqr_baker/features/credentials/data/mock_credential_repository.dart';
import 'package:asisteqr_baker/features/people/data/mock_people_repository.dart';
import 'package:asisteqr_baker/features/reports/domain/report_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final scanResult = ScanResult(
    record: AttendanceRecord(
      id: 'responsive-audit',
      student: const Student(
        id: 'student-audit',
        code: 'EST-0000000001',
        fullName: 'Nombre estudiantil particularmente extenso',
        course: '6.º de Secundaria Comunitaria Productiva A',
      ),
      timestamp: DateTime(2026, 8, 8, 7, 45),
      status: AttendanceStatus.late,
    ),
  );
  const routes = <String>[
    '/inicio',
    '/escaner',
    '/resultado',
    '/asistencia',
    '/historial',
    '/reportes',
    '/cursos',
    '/estudiantes',
    '/docentes',
    '/credenciales',
  ];

  for (final scenario in <({Size size, double textScale})>[
    (size: const Size(320, 568), textScale: 1),
    (size: const Size(390, 844), textScale: 1),
    (size: const Size(390, 844), textScale: 1.3),
    (size: const Size(1280, 1024), textScale: 1),
  ]) {
    testWidgets('las vistas no desbordan en ${scenario.size.width.toInt()} px '
        'con escala ${scenario.textScale}', (tester) async {
      final size = scenario.size;
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.platformDispatcher.textScaleFactorTestValue = scenario.textScale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final container = _container();
      addTearDown(container.dispose);
      final session = container.read(sessionViewModelProvider);
      await tester.runAsync(session.restore);
      final signedIn = await tester.runAsync(
        () => session.signIn(
          MockAuthRepository.testUsername,
          MockAuthRepository.testPassword,
        ),
      );
      expect(signedIn, isTrue);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const AsisteQrApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      final router = container.read(appRouterProvider);
      final layoutErrors = <String>[];
      for (final route in routes) {
        router.go(route, extra: route == '/resultado' ? scanResult : null);
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));

        final exceptions = <Object>[];
        Object? exception;
        while ((exception = tester.takeException()) != null) {
          exceptions.add(exception!);
        }
        layoutErrors.addAll(exceptions.map((error) => '$route: $error'));
      }
      expect(
        layoutErrors,
        isEmpty,
        reason: 'Se detectaron excepciones de layout en $size',
      );
    });
  }

  testWidgets('los formularios modales no desbordan en movil', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final container = _container();
    addTearDown(container.dispose);
    final session = container.read(sessionViewModelProvider);
    await tester.runAsync(session.restore);
    await tester.runAsync(
      () => session.signIn(
        MockAuthRepository.testUsername,
        MockAuthRepository.testPassword,
      ),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AsisteQrApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    final router = container.read(appRouterProvider);
    final layoutErrors = <String>[];
    for (final route in ['/estudiantes', '/docentes', '/cursos']) {
      router.go(route);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      final newButton = find.widgetWithText(ElevatedButton, 'Nuevo');
      expect(newButton, findsOneWidget, reason: route);
      await tester.tap(newButton);
      await tester.pump(const Duration(milliseconds: 300));

      Object? exception;
      while ((exception = tester.takeException()) != null) {
        layoutErrors.add('$route/dialogo: $exception');
      }

      Navigator.of(tester.element(find.byType(AlertDialog))).pop();
      await tester.pump(const Duration(milliseconds: 300));
    }

    expect(layoutErrors, isEmpty);
  });

  testWidgets('el acceso no desborda en movil con texto ampliado', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const ProviderScope(child: AsisteQrApp()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
  });
}

ProviderContainer _container() => ProviderContainer(
  overrides: [
    authRepositoryProvider.overrideWithValue(MockAuthRepository()),
    attendanceRepositoryProvider.overrideWithValue(MockAttendanceRepository()),
    peopleRepositoryProvider.overrideWithValue(MockPeopleRepository()),
    courseRepositoryProvider.overrideWithValue(MockCourseRepository()),
    credentialRepositoryProvider.overrideWithValue(MockCredentialRepository()),
    reportRepositoryProvider.overrideWithValue(_ReportRepositoryStub()),
  ],
);

class _ReportRepositoryStub implements ReportRepository {
  @override
  Future<ReportSummary> getSummary({
    required DateTime from,
    required DateTime to,
    String? courseId,
  }) async => ReportSummary(
    from: from,
    to: to,
    enrolledStudents: 1,
    punctualAttendances: 1,
    lateAttendances: 0,
    totalRecords: 1,
    schoolDays: 1,
    expectedAttendances: 1,
    absences: 0,
    attendancePercentage: 100,
    punctualityPercentage: 100,
  );

  @override
  Future<String> exportPdf({
    required DateTime from,
    required DateTime to,
    String? courseId,
  }) async => '/tmp/reporte.pdf';
}
