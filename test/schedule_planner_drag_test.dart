import 'package:asisteqr_baker/app/providers.dart';
import 'package:asisteqr_baker/features/schedules/domain/schedule_planner_models.dart';
import 'package:asisteqr_baker/features/schedules/domain/schedule_planner_repository.dart';
import 'package:asisteqr_baker/features/schedules/domain/teacher_schedule_editor_models.dart';
import 'package:asisteqr_baker/features/schedules/presentation/teaching_schedules_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('el arrastre precarga el rango completo en el planificador', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          schedulePlannerRepositoryProvider.overrideWithValue(
            _PlannerRepository(),
          ),
        ],
        child: const MaterialApp(home: TeachingSchedulesPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));

    final grid = find.byKey(const ValueKey('schedule-matrix-grid'));
    expect(grid, findsOneWidget);
    final origin = tester.getTopLeft(grid);
    const headerHeight = 36.0;
    const rowHeight = 42.0;
    const mondayX = 82.0;
    final gesture = await tester.startGesture(
      origin + const Offset(mondayX, headerHeight + rowHeight * 1.5),
    );
    await gesture.moveTo(
      origin + const Offset(mondayX, headerHeight + rowHeight * 3.5),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('schedule-range-preview')),
      findsOneWidget,
    );
    final previewText = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('schedule-range-preview')),
        matching: find.byType(Text),
      ),
    );
    expect(previewText.data, '08:00–09:30');

    await gesture.up();
    await tester.pumpAndSettle();

    final dialog = find.byType(Dialog);
    expect(
      find.descendant(of: dialog, matching: find.text('Programar clase')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dialog, matching: find.text('08:00')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dialog, matching: find.text('09:30')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'los diálogos del planificador caben a 320 px con texto al 130%',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            schedulePlannerRepositoryProvider.overrideWithValue(
              _PlannerRepository(),
            ),
          ],
          child: const MaterialApp(home: TeachingSchedulesPage()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);

      final assignmentButton = find.widgetWithText(OutlinedButton, 'Clase');
      await tester.ensureVisible(assignmentButton);
      await tester.tap(assignmentButton);
      await tester.pumpAndSettle();
      expect(find.text('Nueva clase · carga académica'), findsOneWidget);
      expect(find.text('Continuar al horario'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();
      final classButton = find.widgetWithText(FilledButton, 'Clase');
      await tester.ensureVisible(classButton);
      await tester.tap(classButton);
      await tester.pumpAndSettle();
      expect(find.text('Programar clase'), findsOneWidget);
      expect(find.text('Agregar al horario'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Configuración general'));
      await tester.pumpAndSettle();
      expect(find.text('Configuración del horario'), findsOneWidget);
      expect(find.text('Guardar configuración'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _PlannerRepository implements SchedulePlannerRepository {
  @override
  Future<void> deactivateClassroom(String id) async {}

  @override
  Future<void> deactivateSubject(String id) async {}

  @override
  Future<SchedulePlannerData> getPlanner() async => const SchedulePlannerData(
    period: SchedulePeriod(
      id: 'period-1',
      name: 'Segundo semestre',
      year: 2026,
    ),
    config: GeneralScheduleConfig(
      id: 'config-1',
      periodId: 'period-1',
      startTime: '07:30',
      endTime: '20:00',
      intervalMinutes: 30,
      toleranceMinutes: 5,
      timeZone: 'America/La_Paz',
      version: 1,
    ),
    breaks: [],
    courses: [ScheduleCourse(id: 'course-1', name: '4.º Secundaria B')],
    subjects: [ScheduleSubject(id: 'subject-1', name: 'Matemática')],
    classrooms: [ScheduleClassroom(id: 'classroom-1', name: 'Aula 4')],
    teachers: [
      ScheduleTeacher(
        id: 'teacher-1',
        code: 1,
        fullName: 'María Elena Rodríguez Flores',
        specialty: 'Matemática y Física',
      ),
    ],
    assignments: [
      AcademicAssignment(
        id: 'assignment-1',
        courseId: 'course-1',
        subjectId: 'subject-1',
        teacherId: 'teacher-1',
        weeklyMinutes: 300,
      ),
    ],
    blocks: [],
  );

  @override
  Future<void> saveGeneralConfig(GeneralScheduleDraft draft) async {}

  @override
  Future<ScheduleClassroom> saveClassroom(
    ScheduleClassroomDraft draft, {
    String? id,
  }) async => ScheduleClassroom(
    id: id ?? 'classroom-new',
    name: draft.name,
    capacity: draft.capacity,
    location: draft.location,
  );

  @override
  Future<int> savePlanner({
    required String periodId,
    required int version,
    required List<AcademicAssignment> assignments,
    required List<PlannerScheduleBlock> blocks,
    required Set<String> removedAssignmentIds,
    required Set<String> removedBlockIds,
  }) async => version + 1;

  @override
  Future<ScheduleSubject> saveSubject(
    ScheduleSubjectDraft draft, {
    String? id,
  }) async => ScheduleSubject(id: id ?? 'subject-new', name: draft.name);
}
