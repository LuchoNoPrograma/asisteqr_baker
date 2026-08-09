import 'package:asisteqr_baker/app/providers.dart';
import 'package:asisteqr_baker/features/auth/data/auth_repositories.dart';
import 'package:asisteqr_baker/features/courses/data/mock_course_repository.dart';
import 'package:asisteqr_baker/features/people/data/mock_people_repository.dart';
import 'package:asisteqr_baker/features/schedules/domain/teaching_schedule_models.dart';
import 'package:asisteqr_baker/features/schedules/domain/teaching_schedule_repository.dart';
import 'package:asisteqr_baker/features/schedules/presentation/teaching_schedules_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra materia, docente, curso, rango y contacto en tabla', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final container = _container();
    addTearDown(container.dispose);
    await _signIn(tester, container);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TeachingSchedulesPage()),
      ),
    );
    await _pumpUi(tester);

    expect(find.text('Materia'), findsWidgets);
    expect(find.text('MATEMÁTICA'), findsOneWidget);
    expect(find.text('MARÍA ELENA RODRÍGUEZ FLORES'), findsOneWidget);
    expect(find.text('4.º Secundaria B'), findsWidgets);
    expect(find.text('08:00 - 09:30'), findsOneWidget);
    expect(find.text('70112233'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el formulario de horario no desborda a 320 px y texto 130%', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final container = _container();
    addTearDown(container.dispose);
    await _signIn(tester, container);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TeachingSchedulesPage()),
      ),
    );
    await _pumpUi(tester);
    await tester.tap(find.text('Nuevo'));
    await _pumpUi(tester);

    expect(find.text('Nuevo horario'), findsWidgets);
    expect(find.text('Docente'), findsOneWidget);
    expect(find.text('Materia'), findsOneWidget);
    expect(find.text('Curso'), findsOneWidget);
    expect(find.text('Día'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

ProviderContainer _container() => ProviderContainer(
  overrides: [
    authRepositoryProvider.overrideWithValue(MockAuthRepository()),
    peopleRepositoryProvider.overrideWithValue(MockPeopleRepository()),
    courseRepositoryProvider.overrideWithValue(MockCourseRepository()),
    teachingScheduleRepositoryProvider.overrideWithValue(
      _TeachingScheduleRepository(),
    ),
  ],
);

Future<void> _signIn(WidgetTester tester, ProviderContainer container) =>
    tester.runAsync(
      () => container
          .read(sessionViewModelProvider)
          .signIn(
            MockAuthRepository.testUsername,
            MockAuthRepository.testPassword,
          ),
    );

Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

class _TeachingScheduleRepository implements TeachingScheduleRepository {
  final schedules = <TeachingSchedule>[
    const TeachingSchedule(
      id: 'schedule-1',
      teacherId: 'teacher-1',
      teacherCode: 1,
      teacherName: 'MARÍA ELENA RODRÍGUEZ FLORES',
      teacherSpecialty: 'MATEMÁTICA Y FÍSICA',
      teacherPhone: '70112233',
      courseId: 'course-4b',
      courseName: '4.º Secundaria B',
      subject: 'MATEMÁTICA',
      weekday: DateTime.monday,
      startTime: '08:00',
      endTime: '09:30',
      active: true,
    ),
  ];

  @override
  Future<List<TeachingSchedule>> getSchedules() async => schedules;

  @override
  Future<TeachingSchedule> createSchedule(TeachingScheduleDraft draft) async =>
      schedules.first;

  @override
  Future<TeachingSchedule> updateSchedule(
    String id,
    TeachingScheduleDraft draft,
  ) async => schedules.first;

  @override
  Future<void> deactivateSchedule(String id) async {}
}
