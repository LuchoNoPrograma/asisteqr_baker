import 'package:asisteqr_baker/app/providers.dart';
import 'package:asisteqr_baker/features/auth/data/auth_repositories.dart';
import 'package:asisteqr_baker/features/courses/data/mock_course_repository.dart';
import 'package:asisteqr_baker/features/reports/presentation/courses_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
