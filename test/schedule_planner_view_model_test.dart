import 'package:sis_amerinst/features/schedules/domain/schedule_planner_models.dart';
import 'package:sis_amerinst/features/schedules/domain/schedule_planner_repository.dart';
import 'package:sis_amerinst/features/schedules/domain/teacher_schedule_editor_models.dart';
import 'package:sis_amerinst/features/schedules/domain/teaching_schedule_models.dart';
import 'package:sis_amerinst/features/schedules/presentation/schedule_planner_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'calcula la carga semanal desde los bloques y no impone un tope',
    () async {
      final repository = _PlannerRepository();
      final viewModel = SchedulePlannerViewModel(repository);

      await viewModel.load();

      expect(viewModel.scheduledMinutes(viewModel.assignments.single), 0);
      expect(viewModel.assignments.single.weeklyMinutes, 600);

      expect(
        viewModel.saveBlock(
          PlannerBlockDraft(
            assignment: viewModel.assignments.single,
            classroomId: 1,
            weekday: 1,
            startMinutes: 8 * 60,
            endMinutes: 9 * 60 + 30,
          ),
        ),
        isTrue,
      );
      expect(viewModel.assignments.single.weeklyMinutes, 600);

      expect(
        viewModel.saveBlock(
          PlannerBlockDraft(
            assignment: viewModel.assignments.single,
            classroomId: 1,
            weekday: 2,
            startMinutes: 8 * 60,
            endMinutes: 10 * 60,
          ),
        ),
        isTrue,
      );
      expect(viewModel.assignments.single.weeklyMinutes, 600);

      viewModel.removeBlock(
        viewModel.blocks.singleWhere((block) => block.weekday == 2),
      );
      expect(viewModel.assignments.single.weeklyMinutes, 600);

      expect(await viewModel.save(), isTrue);
      expect(repository.savedAssignments.single.weeklyMinutes, 600);
    },
  );

  test(
    'programar una clase conserva el borrador hasta el guardado batch',
    () async {
      final repository = _PlannerRepository(assignments: const []);
      final viewModel = SchedulePlannerViewModel(repository);
      await viewModel.load();
      const assignment = AcademicAssignment(
        courseId: 1,
        subjectId: 1,
        teacherId: 1,
        weeklyMinutes: 30,
      );

      final saved = await viewModel.persistClass(
        assignment,
        const PlannerBlockDraft(
          assignment: assignment,
          classroomId: 1,
          weekday: 1,
          startMinutes: 8 * 60,
          endMinutes: 9 * 60,
        ),
      );

      expect(saved, isTrue);
      expect(repository.saveCalls, 0);
      expect(viewModel.dirty, isTrue);
      expect(await viewModel.save(), isTrue);
      expect(repository.saveCalls, 1);
      expect(repository.savedAssignments, hasLength(1));
      expect(repository.savedBlocks, hasLength(1));
      expect(repository.savedAssignments.single.weeklyMinutes, 30);
      expect(viewModel.dirty, isFalse);
    },
  );

  test('reasigna el docente y actualiza la clase en un solo batch', () async {
    const currentBlock = PlannerScheduleBlock(
      id: 1,
      courseId: 1,
      subjectId: 1,
      teacherId: 1,
      classroomId: 1,
      weekday: 1,
      startTime: '08:00',
      endTime: '09:00',
    );
    final repository = _PlannerRepository(blocks: const [currentBlock]);
    final viewModel = SchedulePlannerViewModel(repository);
    await viewModel.load();
    final currentAssignment = viewModel.assignments.single;
    final updatedAssignment = currentAssignment.copyWith(teacherId: 2);

    final saved = await viewModel.persistClass(
      updatedAssignment,
      PlannerBlockDraft(
        assignment: updatedAssignment,
        classroomId: 1,
        weekday: 1,
        startMinutes: 8 * 60,
        endMinutes: 9 * 60 + 30,
      ),
      currentAssignment: currentAssignment,
      currentBlock: viewModel.blocks.single,
    );

    expect(saved, isTrue);
    expect(repository.saveCalls, 0);
    expect(await viewModel.save(), isTrue);
    expect(repository.saveCalls, 1);
    expect(repository.savedAssignments.single.teacherId, 2);
    expect(repository.savedAssignments.single.weeklyMinutes, 600);
    expect(repository.savedBlocks, hasLength(1));
    expect(repository.savedBlocks.single.teacherId, 2);
    expect(repository.savedBlocks.single.endTime, '09:30');
  });

  test('reasigna el docente al agregar otra clase en un solo batch', () async {
    const existingBlock = PlannerScheduleBlock(
      id: 1,
      courseId: 1,
      subjectId: 1,
      teacherId: 1,
      classroomId: 1,
      weekday: 2,
      startTime: '08:00',
      endTime: '09:00',
    );
    final repository = _PlannerRepository(blocks: const [existingBlock]);
    final viewModel = SchedulePlannerViewModel(repository);
    await viewModel.load();
    final currentAssignment = viewModel.assignments.single;
    final updatedAssignment = currentAssignment.copyWith(teacherId: 2);

    final saved = await viewModel.persistClass(
      updatedAssignment,
      PlannerBlockDraft(
        assignment: updatedAssignment,
        classroomId: 1,
        weekday: 1,
        startMinutes: 8 * 60,
        endMinutes: 9 * 60,
      ),
      currentAssignment: currentAssignment,
    );

    expect(saved, isTrue);
    expect(repository.saveCalls, 0);
    expect(await viewModel.save(), isTrue);
    expect(repository.saveCalls, 1);
    expect(repository.savedAssignments.single.teacherId, 2);
    expect(repository.savedAssignments.single.weeklyMinutes, 600);
    expect(repository.savedBlocks, hasLength(2));
    expect(
      repository.savedBlocks.map((block) => block.teacherId),
      everyElement(2),
    );
  });

  test('conserva el borrador cuando el guardado batch falla', () async {
    final repository = _PlannerRepository()..failNextSave = true;
    final viewModel = SchedulePlannerViewModel(repository);
    await viewModel.load();

    final changed = await viewModel.persistBlock(
      PlannerBlockDraft(
        assignment: viewModel.assignments.single,
        classroomId: 1,
        weekday: 1,
        startMinutes: 8 * 60,
        endMinutes: 9 * 60,
      ),
    );

    expect(changed, isTrue);
    final saved = await viewModel.save();
    expect(saved, isFalse);
    expect(repository.saveCalls, 1);
    expect(viewModel.blocks, hasLength(1));
    expect(viewModel.assignments.single.weeklyMinutes, 600);
    expect(viewModel.dirty, isTrue);
    expect(viewModel.error, 'No se pudo guardar la acción.');
  });

  test(
    'confirma el PUT y permite recargar sin repetirlo cuando falla el GET',
    () async {
      final repository = _PlannerRepository();
      final viewModel = SchedulePlannerViewModel(repository);
      await viewModel.load();
      expect(
        viewModel.saveBlock(
          PlannerBlockDraft(
            assignment: viewModel.assignments.single,
            classroomId: 1,
            weekday: 1,
            startMinutes: 8 * 60,
            endMinutes: 9 * 60,
          ),
        ),
        isTrue,
      );
      repository.failNextLoad = true;

      expect(await viewModel.save(), isTrue);
      expect(repository.saveCalls, 1);
      expect(viewModel.data!.config.version, 2);
      expect(viewModel.dirty, isFalse);
      expect(viewModel.refreshPending, isTrue);
      expect(viewModel.refreshMessage, contains('se guardaron'));

      expect(await viewModel.save(), isFalse);
      expect(repository.saveCalls, 1);
      expect(await viewModel.refreshAfterCommit(), isTrue);
      expect(repository.saveCalls, 1);
      expect(viewModel.refreshPending, isFalse);
      expect(viewModel.blocks, hasLength(1));
    },
  );

  test('confirma la configuración antes de una recarga fallida', () async {
    final repository = _PlannerRepository();
    final viewModel = SchedulePlannerViewModel(repository);
    await viewModel.load();
    repository.failNextLoad = true;

    expect(
      await viewModel.saveGeneralConfig(
        const GeneralScheduleDraft(
          periodId: 1,
          version: 1,
          startTime: '08:00',
          endTime: '18:00',
          toleranceMinutes: 10,
          breaks: [],
        ),
      ),
      isTrue,
    );
    expect(repository.generalConfigSaveCalls, 1);
    expect(viewModel.data!.config.version, 2);
    expect(viewModel.data!.config.startTime, '08:00');
    expect(viewModel.refreshPending, isTrue);

    expect(await viewModel.refreshAfterCommit(), isTrue);
    expect(repository.generalConfigSaveCalls, 1);
    expect(viewModel.refreshPending, isFalse);
  });

  test('permite deshacer, rehacer y descartar el borrador completo', () async {
    final repository = _PlannerRepository();
    final viewModel = SchedulePlannerViewModel(repository);
    await viewModel.load();

    expect(
      viewModel.saveBlock(
        PlannerBlockDraft(
          assignment: viewModel.assignments.single,
          classroomId: 1,
          weekday: 1,
          startMinutes: 8 * 60,
          endMinutes: 9 * 60,
        ),
      ),
      isTrue,
    );
    expect(viewModel.blocks, hasLength(1));
    expect(viewModel.canUndo, isTrue);

    viewModel.undo();
    expect(viewModel.blocks, isEmpty);
    expect(viewModel.dirty, isFalse);
    expect(viewModel.canRedo, isTrue);

    viewModel.redo();
    expect(viewModel.blocks, hasLength(1));
    expect(viewModel.dirty, isTrue);

    viewModel.discard();
    expect(viewModel.blocks, isEmpty);
    expect(viewModel.dirty, isFalse);
    expect(viewModel.canUndo, isFalse);
    expect(repository.saveCalls, 0);
  });

  test('mantiene el borrador sucio al alcanzar el límite de undo', () async {
    final viewModel = SchedulePlannerViewModel(_PlannerRepository());
    await viewModel.load();

    for (var index = 1; index <= 51; index += 1) {
      final current = viewModel.assignments.single;
      expect(
        viewModel.saveAssignment(
          current.copyWith(weeklyMinutes: 600 + index * 30),
          current: current,
        ),
        isTrue,
      );
    }
    for (var index = 0; index < 50; index += 1) {
      viewModel.undo();
    }

    expect(viewModel.assignments.single.weeklyMinutes, 630);
    expect(viewModel.canUndo, isFalse);
    expect(viewModel.dirty, isTrue);
  });
}

class _PlannerRepository implements SchedulePlannerRepository {
  _PlannerRepository({
    List<AcademicAssignment>? assignments,
    List<PlannerScheduleBlock>? blocks,
  }) : _assignments = List.of(assignments ?? _defaultAssignments),
       _blocks = List.of(blocks ?? const []);

  static const _defaultAssignments = [
    AcademicAssignment(
      id: 1,
      courseId: 1,
      subjectId: 1,
      teacherId: 1,
      weeklyMinutes: 600,
    ),
  ];

  List<AcademicAssignment> _assignments;
  List<PlannerScheduleBlock> _blocks;
  int _version = 1;
  int saveCalls = 0;
  int generalConfigSaveCalls = 0;
  bool failNextSave = false;
  bool failNextLoad = false;
  List<AcademicAssignment> savedAssignments = const [];
  List<PlannerScheduleBlock> savedBlocks = const [];

  @override
  Future<void> deactivateClassroom(int id) async {}

  @override
  Future<void> deactivateSubject(int id) async {}

  @override
  Future<SchedulePlannerData> getPlanner() async {
    if (failNextLoad) {
      failNextLoad = false;
      throw const TeachingScheduleException('No se pudo recargar.');
    }
    return SchedulePlannerData(
      period: const SchedulePeriod(id: 1, name: 'Gestión 2026', year: 2026),
      config: GeneralScheduleConfig(
        id: 1,
        periodId: 1,
        startTime: '07:30',
        endTime: '20:00',
        intervalMinutes: 30,
        toleranceMinutes: 5,
        timeZone: 'America/La_Paz',
        version: _version,
      ),
      breaks: const [],
      courses: const [ScheduleCourse(id: 1, name: '1.º Secundaria A')],
      subjects: const [ScheduleSubject(id: 1, name: 'Matemática')],
      classrooms: const [ScheduleClassroom(id: 1, name: 'Aula 1')],
      teachers: const [
        ScheduleTeacher(
          id: 1,
          code: 1,
          fullName: 'Rodrigo Flores',
          specialty: 'Matemática',
        ),
      ],
      assignments: List.unmodifiable(_assignments),
      blocks: List.unmodifiable(_blocks),
    );
  }

  @override
  Future<int> saveGeneralConfig(GeneralScheduleDraft draft) async {
    generalConfigSaveCalls += 1;
    _version = draft.version + 1;
    return _version;
  }

  @override
  Future<ScheduleClassroom> saveClassroom(
    ScheduleClassroomDraft draft, {
    int? id,
  }) async => ScheduleClassroom(
    id: id ?? 2,
    name: draft.name,
    capacity: draft.capacity,
    location: draft.location,
  );

  @override
  Future<int> savePlanner({
    required int periodId,
    required int version,
    required List<AcademicAssignment> assignments,
    required List<PlannerScheduleBlock> blocks,
    required Set<int> removedAssignmentIds,
    required Set<int> removedBlockIds,
  }) async {
    saveCalls += 1;
    if (failNextSave) {
      failNextSave = false;
      throw const TeachingScheduleException('No se pudo guardar la acción.');
    }
    savedAssignments = List.unmodifiable(assignments);
    savedBlocks = List.unmodifiable(blocks);
    _assignments = List.of(assignments);
    _blocks = List.of(blocks);
    _version = version + 1;
    return _version;
  }

  @override
  Future<ScheduleSubject> saveSubject(
    ScheduleSubjectDraft draft, {
    int? id,
  }) async => ScheduleSubject(id: id ?? 2, name: draft.name);
}
