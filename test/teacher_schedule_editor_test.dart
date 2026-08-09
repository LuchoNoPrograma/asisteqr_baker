import 'package:asisteqr_baker/app/providers.dart';
import 'package:asisteqr_baker/features/auth/data/auth_repositories.dart';
import 'package:asisteqr_baker/features/schedules/domain/teacher_schedule_editor_models.dart';
import 'package:asisteqr_baker/features/schedules/domain/teacher_schedule_editor_repository.dart';
import 'package:asisteqr_baker/features/schedules/presentation/teacher_schedule_editor_page.dart';
import 'package:asisteqr_baker/features/schedules/presentation/teacher_schedule_editor_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'edita por rangos, bloquea recreos y guarda la matriz una sola vez',
    () async {
      final repository = _EditorRepository();
      final model = TeacherScheduleEditorViewModel(repository, 'teacher-1');
      await model.load();

      expect(
        model.addRange(
          weekday: DateTime.monday,
          startMinutes: 9 * 60,
          endMinutes: 10 * 60,
        ),
        isTrue,
      );
      expect(
        model.addRange(
          weekday: DateTime.tuesday,
          startMinutes: 10 * 60,
          endMinutes: 10 * 60 + 30,
        ),
        isFalse,
      );
      expect(model.error, contains('recreo general'));
      expect(
        model.addRange(
          weekday: DateTime.monday,
          startMinutes: 8 * 60 + 30,
          endMinutes: 9 * 60 + 30,
        ),
        isFalse,
      );

      expect(await model.save(), isTrue);
      expect(repository.saveCalls, 1);
      expect(model.dirty, isFalse);
      expect(model.data!.config.version, 2);
    },
  );

  for (final scenario in <({Size size, double scale})>[
    (size: const Size(320, 568), scale: 1.3),
    (size: const Size(390, 844), scale: 1.3),
    (size: const Size(1280, 900), scale: 1),
  ]) {
    testWidgets(
      'la vista especializada no desborda a ${scenario.size.width.toInt()} px',
      (tester) async {
        await tester.binding.setSurfaceSize(scenario.size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        tester.platformDispatcher.textScaleFactorTestValue = scenario.scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final repository = _EditorRepository();
        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(MockAuthRepository()),
            teacherScheduleEditorRepositoryProvider.overrideWithValue(
              repository,
            ),
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
            child: const MaterialApp(
              home: TeacherScheduleEditorPage(teacherId: 'teacher-1'),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.text('MARÍA ELENA RODRÍGUEZ FLORES'), findsOneWidget);
        if (scenario.size.width < 840) {
          expect(find.text('Agregar clase'), findsOneWidget);
        } else {
          expect(find.text('Lunes'), findsOneWidget);
          expect(find.text('Viernes'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _EditorRepository implements TeacherScheduleEditorRepository {
  int saveCalls = 0;

  @override
  Future<TeacherScheduleEditorData> getEditor(String teacherId) async => data;

  @override
  Future<({List<TeacherScheduleBlock> blocks, int version})> saveMatrix({
    required String teacherId,
    required String periodId,
    required int version,
    required List<TeacherScheduleBlock> blocks,
  }) async {
    saveCalls += 1;
    return (blocks: blocks, version: version + 1);
  }

  @override
  Future<void> saveGeneralConfig(GeneralScheduleDraft draft) async {}

  static const data = TeacherScheduleEditorData(
    teacher: ScheduleTeacher(
      id: 'teacher-1',
      code: 1,
      fullName: 'MARÍA ELENA RODRÍGUEZ FLORES',
      specialty: 'MATEMÁTICA Y FÍSICA',
      phone: '70112233',
    ),
    period: SchedulePeriod(
      id: 'period-1',
      name: 'Segundo semestre',
      year: 2026,
    ),
    config: GeneralScheduleConfig(
      id: 'config-1',
      periodId: 'period-1',
      startTime: '07:30',
      endTime: '13:30',
      intervalMinutes: 30,
      toleranceMinutes: 5,
      timeZone: 'America/La_Paz',
      version: 1,
    ),
    breaks: [
      ScheduleBreak(
        id: 'break-1',
        name: 'RECREO GENERAL',
        startTime: '10:00',
        endTime: '10:30',
      ),
    ],
    courses: [ScheduleCourse(id: 'course-1', name: '4.º Secundaria B')],
    subjects: [
      ScheduleSubject(id: 'subject-1', code: 'MAT', name: 'MATEMÁTICA'),
    ],
    classrooms: [
      ScheduleClassroom(id: 'room-1', code: '4B', name: 'Aula 4.º B'),
    ],
    blocks: [
      TeacherScheduleBlock(
        id: 'block-1',
        courseId: 'course-1',
        courseName: '4.º Secundaria B',
        subjectId: 'subject-1',
        subjectName: 'MATEMÁTICA',
        classroomId: 'room-1',
        classroomName: 'Aula 4.º B',
        weekday: DateTime.monday,
        startTime: '08:00',
        endTime: '09:00',
      ),
    ],
  );
}
