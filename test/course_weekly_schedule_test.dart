import 'package:asisteqr_baker/app/providers.dart';
import 'package:asisteqr_baker/features/auth/data/auth_repositories.dart';
import 'package:asisteqr_baker/features/courses/data/mock_course_repository.dart';
import 'package:asisteqr_baker/features/reports/presentation/courses_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pinta, reemplaza y persiste una sola planilla semanal', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = MockCourseRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        courseRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    await tester.runAsync(
      () => container
          .read(sessionViewModelProvider)
          .signIn(
            MockAuthRepository.testUsername,
            MockAuthRepository.testPassword,
          ),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CoursesPage()),
      ),
    );
    await _pumpUi(tester);
    expect(tester.takeException(), isNull, reason: 'pantalla de cursos');

    final actionsButton = find.byTooltip('Acciones del curso');
    await tester.ensureVisible(actionsButton);
    await tester.pump();
    await tester.tap(actionsButton);
    await _pumpUi(tester);
    expect(tester.takeException(), isNull, reason: 'menú de acciones');
    await tester.tap(find.text('Planilla semanal'));
    await _pumpUi(tester);
    expect(tester.takeException(), isNull, reason: 'editor abierto');

    expect(find.text('08–09'), findsOneWidget);
    expect(find.text('19–20'), findsOneWidget);
    expect(find.text('0 horas semanales · 08:00–20:00'), findsOneWidget);
    final clearButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Limpiar'),
    );
    expect(clearButton.onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('course_slot_1_8')));
    await tester.pump();
    expect(find.text('1 horas semanales · 08:00–20:00'), findsOneWidget);

    await tester.tap(find.text('Lun–Vie 08–12'));
    await tester.pump();
    expect(find.text('20 horas semanales · 08:00–20:00'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Limpiar'));
    await tester.pump();
    expect(find.text('0 horas semanales · 08:00–20:00'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'edición de celdas');

    final lastSlot = find.byKey(const ValueKey('course_slot_5_19'));
    await tester.ensureVisible(lastSlot);
    await tester.pump();
    await tester.tap(lastSlot);
    final saveButton = find.widgetWithText(FilledButton, 'Guardar horario');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull, reason: 'confirmación guardada');

    expect(repository.courses.single.weeklySchedule, hasLength(1));
    expect(repository.courses.single.weeklySchedule.single.weekday, 5);
    expect(repository.courses.single.weeklySchedule.single.hour, 19);
    if (find.text('Entendido').evaluate().isNotEmpty) {
      await tester.tap(find.text('Entendido'));
      await _pumpUi(tester);
    }
  });

  testWidgets('el editor semanal no desborda a 320 px con texto al 130%', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        courseRepositoryProvider.overrideWithValue(MockCourseRepository()),
      ],
    );
    addTearDown(container.dispose);
    await tester.runAsync(
      () => container
          .read(sessionViewModelProvider)
          .signIn(
            MockAuthRepository.testUsername,
            MockAuthRepository.testPassword,
          ),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CoursesPage()),
      ),
    );
    await _pumpUi(tester);
    await tester.tap(find.text('4.º Secundaria B'));
    await _pumpUi(tester);
    final editButton = find.widgetWithText(OutlinedButton, 'Editar');
    await tester.ensureVisible(editButton);
    await tester.pump();
    await tester.tap(editButton);
    await _pumpUi(tester);

    expect(
      find.byKey(const ValueKey('course_weekly_schedule_matrix')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('los horarios de ingreso son gestionables a 320 px', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        courseRepositoryProvider.overrideWithValue(MockCourseRepository()),
      ],
    );
    addTearDown(container.dispose);
    await tester.runAsync(
      () => container
          .read(sessionViewModelProvider)
          .signIn(
            MockAuthRepository.testUsername,
            MockAuthRepository.testPassword,
          ),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CoursesPage()),
      ),
    );
    await _pumpUi(tester);
    await tester.tap(find.text('4.º Secundaria B'));
    await _pumpUi(tester);

    final manageButton = find.byTooltip('Gestionar horarios de ingreso');
    await Scrollable.ensureVisible(
      tester.element(manageButton),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(manageButton);
    await _pumpUi(tester);
    expect(find.text('Horarios de ingreso'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final newSchedule = find.widgetWithText(FilledButton, 'Nuevo horario');
    await tester.ensureVisible(newSchedule);
    await tester.tap(newSchedule);
    await _pumpUi(tester);
    expect(find.text('Nuevo horario'), findsWidgets);
    expect(find.text('Jornada'), findsOneWidget);
    expect(find.text('Hora límite'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}
