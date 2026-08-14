import 'package:asisteqr_baker/features/schedules/domain/schedule_planner_models.dart';
import 'package:asisteqr_baker/features/schedules/domain/schedule_planner_repository.dart';
import 'package:asisteqr_baker/features/schedules/domain/teacher_schedule_editor_models.dart';
import 'package:asisteqr_baker/features/schedules/domain/teaching_schedule_models.dart';
import 'package:asisteqr_baker/features/schedules/presentation/schedule_planner_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'calcula la carga semanal desde los bloques y no impone un tope',
    () async {
      final repository = _PlannerRepository();
      final viewModel = SchedulePlannerViewModel(repository);

      await viewModel.load();

      expect(viewModel.scheduledMinutes(viewModel.assignments.single), 0);
      expect(viewModel.assignments.single.weeklyMinutes, 30);

      expect(
        viewModel.saveBlock(
          PlannerBlockDraft(
            assignment: viewModel.assignments.single,
            classroomId: 'classroom-1',
            weekday: 1,
            startMinutes: 8 * 60,
            endMinutes: 9 * 60 + 30,
          ),
        ),
        isTrue,
      );
      expect(viewModel.assignments.single.weeklyMinutes, 90);

      expect(
        viewModel.saveBlock(
          PlannerBlockDraft(
            assignment: viewModel.assignments.single,
            classroomId: 'classroom-1',
            weekday: 2,
            startMinutes: 8 * 60,
            endMinutes: 10 * 60,
          ),
        ),
        isTrue,
      );
      expect(viewModel.assignments.single.weeklyMinutes, 210);

      viewModel.removeBlock(
        viewModel.blocks.singleWhere((block) => block.weekday == 2),
      );
      expect(viewModel.assignments.single.weeklyMinutes, 90);

      expect(await viewModel.save(), isTrue);
      expect(repository.savedAssignments.single.weeklyMinutes, 90);
    },
  );

  test(
    'programar una clase guarda asignación y bloque en un solo batch',
    () async {
      final repository = _PlannerRepository(assignments: const []);
      final viewModel = SchedulePlannerViewModel(repository);
      await viewModel.load();
      const assignment = AcademicAssignment(
        courseId: 'course-1',
        subjectId: 'subject-1',
        teacherId: 'teacher-1',
        weeklyMinutes: 30,
      );

      final saved = await viewModel.persistClass(
        assignment,
        const PlannerBlockDraft(
          assignment: assignment,
          classroomId: 'classroom-1',
          weekday: 1,
          startMinutes: 8 * 60,
          endMinutes: 9 * 60,
        ),
      );

      expect(saved, isTrue);
      expect(repository.saveCalls, 1);
      expect(repository.savedAssignments, hasLength(1));
      expect(repository.savedBlocks, hasLength(1));
      expect(repository.savedAssignments.single.weeklyMinutes, 60);
      expect(viewModel.dirty, isFalse);
    },
  );

  test('reasigna el docente y actualiza la clase en un solo batch', () async {
    const currentBlock = PlannerScheduleBlock(
      id: 'block-1',
      courseId: 'course-1',
      subjectId: 'subject-1',
      teacherId: 'teacher-1',
      classroomId: 'classroom-1',
      weekday: 1,
      startTime: '08:00',
      endTime: '09:00',
    );
    final repository = _PlannerRepository(blocks: const [currentBlock]);
    final viewModel = SchedulePlannerViewModel(repository);
    await viewModel.load();
    final currentAssignment = viewModel.assignments.single;
    final updatedAssignment = currentAssignment.copyWith(
      teacherId: 'teacher-2',
    );

    final saved = await viewModel.persistClass(
      updatedAssignment,
      PlannerBlockDraft(
        assignment: updatedAssignment,
        classroomId: 'classroom-1',
        weekday: 1,
        startMinutes: 8 * 60,
        endMinutes: 9 * 60 + 30,
      ),
      currentAssignment: currentAssignment,
      currentBlock: viewModel.blocks.single,
    );

    expect(saved, isTrue);
    expect(repository.saveCalls, 1);
    expect(repository.savedAssignments.single.teacherId, 'teacher-2');
    expect(repository.savedAssignments.single.weeklyMinutes, 90);
    expect(repository.savedBlocks, hasLength(1));
    expect(repository.savedBlocks.single.teacherId, 'teacher-2');
    expect(repository.savedBlocks.single.endTime, '09:30');
  });

  test('reasigna el docente al agregar otra clase en un solo batch', () async {
    const existingBlock = PlannerScheduleBlock(
      id: 'block-1',
      courseId: 'course-1',
      subjectId: 'subject-1',
      teacherId: 'teacher-1',
      classroomId: 'classroom-1',
      weekday: 2,
      startTime: '08:00',
      endTime: '09:00',
    );
    final repository = _PlannerRepository(blocks: const [existingBlock]);
    final viewModel = SchedulePlannerViewModel(repository);
    await viewModel.load();
    final currentAssignment = viewModel.assignments.single;
    final updatedAssignment = currentAssignment.copyWith(
      teacherId: 'teacher-2',
    );

    final saved = await viewModel.persistClass(
      updatedAssignment,
      PlannerBlockDraft(
        assignment: updatedAssignment,
        classroomId: 'classroom-1',
        weekday: 1,
        startMinutes: 8 * 60,
        endMinutes: 9 * 60,
      ),
      currentAssignment: currentAssignment,
    );

    expect(saved, isTrue);
    expect(repository.saveCalls, 1);
    expect(repository.savedAssignments.single.teacherId, 'teacher-2');
    expect(repository.savedAssignments.single.weeklyMinutes, 120);
    expect(repository.savedBlocks, hasLength(2));
    expect(
      repository.savedBlocks.map((block) => block.teacherId),
      everyElement('teacher-2'),
    );
  });

  test(
    'restaura el estado local cuando una acción no se puede persistir',
    () async {
      final repository = _PlannerRepository()..failNextSave = true;
      final viewModel = SchedulePlannerViewModel(repository);
      await viewModel.load();

      final saved = await viewModel.persistBlock(
        PlannerBlockDraft(
          assignment: viewModel.assignments.single,
          classroomId: 'classroom-1',
          weekday: 1,
          startMinutes: 8 * 60,
          endMinutes: 9 * 60,
        ),
      );

      expect(saved, isFalse);
      expect(repository.saveCalls, 1);
      expect(viewModel.blocks, isEmpty);
      expect(viewModel.assignments.single.weeklyMinutes, 30);
      expect(viewModel.dirty, isFalse);
      expect(viewModel.error, 'No se pudo guardar la acción.');
    },
  );
}

class _PlannerRepository implements SchedulePlannerRepository {
  _PlannerRepository({
    List<AcademicAssignment>? assignments,
    List<PlannerScheduleBlock>? blocks,
  }) : _assignments = List.of(assignments ?? _defaultAssignments),
       _blocks = List.of(blocks ?? const []);

  static const _defaultAssignments = [
    AcademicAssignment(
      id: 'assignment-1',
      courseId: 'course-1',
      subjectId: 'subject-1',
      teacherId: 'teacher-1',
      weeklyMinutes: 600,
    ),
  ];

  List<AcademicAssignment> _assignments;
  List<PlannerScheduleBlock> _blocks;
  int _version = 1;
  int saveCalls = 0;
  bool failNextSave = false;
  List<AcademicAssignment> savedAssignments = const [];
  List<PlannerScheduleBlock> savedBlocks = const [];

  @override
  Future<void> deactivateClassroom(String id) async {}

  @override
  Future<void> deactivateSubject(String id) async {}

  @override
  Future<SchedulePlannerData> getPlanner() async => SchedulePlannerData(
    period: const SchedulePeriod(
      id: 'period-1',
      name: 'Gestión 2026',
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
      version: _version,
    ),
    breaks: const [],
    courses: const [ScheduleCourse(id: 'course-1', name: '1.º Secundaria A')],
    subjects: const [ScheduleSubject(id: 'subject-1', name: 'Matemática')],
    classrooms: const [ScheduleClassroom(id: 'classroom-1', name: 'Aula 1')],
    teachers: const [
      ScheduleTeacher(
        id: 'teacher-1',
        code: 1,
        fullName: 'Rodrigo Flores',
        specialty: 'Matemática',
      ),
    ],
    assignments: List.unmodifiable(_assignments),
    blocks: List.unmodifiable(_blocks),
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
    String? id,
  }) async => ScheduleSubject(id: id ?? 'subject-new', name: draft.name);
}
