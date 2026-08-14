import 'package:asisteqr_baker/features/schedules/domain/schedule_planner_models.dart';
import 'package:asisteqr_baker/features/schedules/domain/schedule_planner_repository.dart';
import 'package:asisteqr_baker/features/schedules/domain/teacher_schedule_editor_models.dart';
import 'package:asisteqr_baker/features/schedules/domain/teaching_schedule_models.dart';
import 'package:flutter/foundation.dart';

class SchedulePlannerViewModel extends ChangeNotifier {
  SchedulePlannerViewModel(this._repository);

  final SchedulePlannerRepository _repository;

  SchedulePlannerData? data;
  List<AcademicAssignment> assignments = const [];
  List<PlannerScheduleBlock> blocks = const [];
  final Set<String> removedAssignmentIds = {};
  final Set<String> removedBlockIds = {};
  bool loading = false;
  bool saving = false;
  bool catalogSaving = false;
  bool dirty = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      _setLoaded(await _repository.getPlanner());
    } on TeachingScheduleException catch (exception) {
      error = exception.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  int scheduledMinutes(AcademicAssignment assignment) => blocks
      .where(
        (item) =>
            item.courseId == assignment.courseId &&
            item.subjectId == assignment.subjectId &&
            item.teacherId == assignment.teacherId,
      )
      .fold(0, (total, item) => total + item.durationMinutes);

  bool saveAssignment(
    AcademicAssignment assignment, {
    AcademicAssignment? current,
  }) {
    final duplicate = assignments.any(
      (item) =>
          !identical(item, current) &&
          item.courseId == assignment.courseId &&
          item.subjectId == assignment.subjectId,
    );
    if (duplicate) {
      error = 'La materia ya está asignada a ese curso.';
      notifyListeners();
      return false;
    }
    assignments = List.unmodifiable(
      current == null
          ? [...assignments, assignment]
          : assignments.map(
              (item) => identical(item, current) ? assignment : item,
            ),
    );
    if (current != null &&
        (current.courseId != assignment.courseId ||
            current.subjectId != assignment.subjectId ||
            current.teacherId != assignment.teacherId)) {
      blocks = List.unmodifiable(
        blocks.map(
          (item) =>
              item.courseId == current.courseId &&
                  item.subjectId == current.subjectId &&
                  item.teacherId == current.teacherId
              ? item.copyWith(
                  courseId: assignment.courseId,
                  subjectId: assignment.subjectId,
                  teacherId: assignment.teacherId,
                )
              : item,
        ),
      );
    }
    _synchronizeAutomaticWeeklyMinutes();
    dirty = true;
    error = null;
    notifyListeners();
    return true;
  }

  Future<bool> persistAssignment(
    AcademicAssignment assignment, {
    AcademicAssignment? current,
  }) => _persistMutation(() => saveAssignment(assignment, current: current));

  Future<bool> persistClass(
    AcademicAssignment assignment,
    PlannerBlockDraft draft, {
    AcademicAssignment? currentAssignment,
    PlannerScheduleBlock? currentBlock,
  }) => _persistMutation(() {
    if (currentBlock != null) {
      if (!saveBlock(draft, current: currentBlock)) return false;
      AcademicAssignment? refreshedCurrent;
      if (currentAssignment != null) {
        for (final item in assignments) {
          final sameId =
              currentAssignment.id != null && item.id == currentAssignment.id;
          if (sameId || item.key == currentAssignment.key) {
            refreshedCurrent = item;
            break;
          }
        }
      }
      return saveAssignment(assignment, current: refreshedCurrent);
    }
    if (!saveAssignment(assignment, current: currentAssignment)) return false;
    final savedAssignment = assignments.firstWhere(
      (item) => item.key == assignment.key,
    );
    return saveBlock(
      PlannerBlockDraft(
        assignment: savedAssignment,
        classroomId: draft.classroomId,
        weekday: draft.weekday,
        startMinutes: draft.startMinutes,
        endMinutes: draft.endMinutes,
      ),
    );
  });

  void removeAssignment(AcademicAssignment assignment) {
    if (assignment.id != null) removedAssignmentIds.add(assignment.id!);
    final related = blocks.where(
      (item) =>
          item.courseId == assignment.courseId &&
          item.subjectId == assignment.subjectId &&
          item.teacherId == assignment.teacherId,
    );
    for (final block in related) {
      if (block.id != null) removedBlockIds.add(block.id!);
    }
    assignments = List.unmodifiable(
      assignments.where((item) => !identical(item, assignment)),
    );
    blocks = List.unmodifiable(
      blocks.where(
        (item) =>
            item.courseId != assignment.courseId ||
            item.subjectId != assignment.subjectId ||
            item.teacherId != assignment.teacherId,
      ),
    );
    dirty = true;
    notifyListeners();
  }

  Future<bool> persistRemoveAssignment(AcademicAssignment assignment) =>
      _persistMutation(() {
        removeAssignment(assignment);
        return true;
      });

  bool saveBlock(PlannerBlockDraft draft, {PlannerScheduleBlock? current}) {
    final loaded = data;
    if (loaded == null || draft.endMinutes <= draft.startMinutes) return false;
    if (draft.startMinutes < loaded.config.startMinutes ||
        draft.endMinutes > loaded.config.endMinutes) {
      error = 'El bloque está fuera de la jornada general.';
      notifyListeners();
      return false;
    }
    if (loaded.breaks.any(
      (item) => item.includesRange(draft.startMinutes, draft.endMinutes),
    )) {
      error = 'El bloque ocupa un recreo general.';
      notifyListeners();
      return false;
    }
    final conflict = blocks.any(
      (item) =>
          !identical(item, current) &&
          item.weekday == draft.weekday &&
          draft.startMinutes < item.endMinutes &&
          draft.endMinutes > item.startMinutes &&
          (item.teacherId == draft.assignment.teacherId ||
              item.courseId == draft.assignment.courseId ||
              item.classroomId == draft.classroomId),
    );
    if (conflict) {
      error = 'El docente, curso o aula ya está ocupado en ese rango.';
      notifyListeners();
      return false;
    }
    final block = PlannerScheduleBlock(
      id: current?.id,
      courseId: draft.assignment.courseId,
      subjectId: draft.assignment.subjectId,
      teacherId: draft.assignment.teacherId,
      classroomId: draft.classroomId,
      weekday: draft.weekday,
      startTime: scheduleMinutesToTime(draft.startMinutes),
      endTime: scheduleMinutesToTime(draft.endMinutes),
    );
    final updatedBlocks = current == null
        ? <PlannerScheduleBlock>[...blocks, block]
        : blocks
              .map((item) => identical(item, current) ? block : item)
              .toList();
    updatedBlocks.sort(_compareBlocks);
    blocks = List.unmodifiable(updatedBlocks);
    _synchronizeAutomaticWeeklyMinutes();
    dirty = true;
    error = null;
    notifyListeners();
    return true;
  }

  Future<bool> persistBlock(
    PlannerBlockDraft draft, {
    PlannerScheduleBlock? current,
  }) => _persistMutation(() => saveBlock(draft, current: current));

  void removeBlock(PlannerScheduleBlock block) {
    if (block.id != null) removedBlockIds.add(block.id!);
    blocks = List.unmodifiable(blocks.where((item) => !identical(item, block)));
    _synchronizeAutomaticWeeklyMinutes();
    dirty = true;
    notifyListeners();
  }

  Future<bool> persistRemoveBlock(PlannerScheduleBlock block) =>
      _persistMutation(() {
        removeBlock(block);
        return true;
      });

  Future<bool> save() async {
    final loaded = data;
    if (loaded == null || saving || !dirty) return false;
    saving = true;
    error = null;
    notifyListeners();
    try {
      await _repository.savePlanner(
        periodId: loaded.period.id,
        version: loaded.config.version,
        assignments: assignments,
        blocks: blocks,
        removedAssignmentIds: removedAssignmentIds,
        removedBlockIds: removedBlockIds,
      );
      _setLoaded(await _repository.getPlanner());
      return true;
    } on TeachingScheduleException catch (exception) {
      error = exception.message;
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<bool> _persistMutation(bool Function() mutate) async {
    if (saving) {
      error = 'Espere a que termine el cambio anterior.';
      notifyListeners();
      return false;
    }
    final snapshot = _PlannerDraftSnapshot(
      assignments: assignments,
      blocks: blocks,
      removedAssignmentIds: Set.of(removedAssignmentIds),
      removedBlockIds: Set.of(removedBlockIds),
      dirty: dirty,
    );
    if (!mutate()) {
      final mutationError = error;
      _restoreSnapshot(snapshot);
      error = mutationError;
      notifyListeners();
      return false;
    }
    if (await save()) return true;

    final persistenceError = error;
    _restoreSnapshot(snapshot);
    error = persistenceError;
    notifyListeners();
    return false;
  }

  void _restoreSnapshot(_PlannerDraftSnapshot snapshot) {
    assignments = snapshot.assignments;
    blocks = snapshot.blocks;
    removedAssignmentIds
      ..clear()
      ..addAll(snapshot.removedAssignmentIds);
    removedBlockIds
      ..clear()
      ..addAll(snapshot.removedBlockIds);
    dirty = snapshot.dirty;
  }

  Future<bool> saveGeneralConfig(GeneralScheduleDraft draft) async {
    if (dirty) {
      error = 'Guarde los cambios de la matriz antes de cambiar la jornada.';
      notifyListeners();
      return false;
    }
    saving = true;
    error = null;
    notifyListeners();
    try {
      await _repository.saveGeneralConfig(draft);
      _setLoaded(await _repository.getPlanner());
      return true;
    } on TeachingScheduleException catch (exception) {
      error = exception.message;
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<bool> saveSubject(
    ScheduleSubjectDraft draft, {
    ScheduleSubject? current,
  }) async {
    if (catalogSaving) return false;
    catalogSaving = true;
    error = null;
    notifyListeners();
    try {
      final saved = await _repository.saveSubject(draft, id: current?.id);
      final subjects = [
        for (final item in data!.subjects)
          if (item.id == saved.id) saved else item,
        if (current == null) saved,
      ]..sort((left, right) => left.name.compareTo(right.name));
      data = data!.copyWith(subjects: List.unmodifiable(subjects));
      return true;
    } on TeachingScheduleException catch (exception) {
      error = exception.message;
      return false;
    } finally {
      catalogSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deactivateSubject(ScheduleSubject subject) async {
    if (assignments.any((item) => item.subjectId == subject.id)) {
      error = 'Retire primero las asignaciones académicas de esta materia.';
      notifyListeners();
      return false;
    }
    if (catalogSaving) return false;
    catalogSaving = true;
    error = null;
    notifyListeners();
    try {
      await _repository.deactivateSubject(subject.id);
      data = data!.copyWith(
        subjects: List.unmodifiable(
          data!.subjects.where((item) => item.id != subject.id),
        ),
      );
      return true;
    } on TeachingScheduleException catch (exception) {
      error = exception.message;
      return false;
    } finally {
      catalogSaving = false;
      notifyListeners();
    }
  }

  Future<bool> saveClassroom(
    ScheduleClassroomDraft draft, {
    ScheduleClassroom? current,
  }) async {
    if (catalogSaving) return false;
    catalogSaving = true;
    error = null;
    notifyListeners();
    try {
      final saved = await _repository.saveClassroom(draft, id: current?.id);
      final classrooms = [
        for (final item in data!.classrooms)
          if (item.id == saved.id) saved else item,
        if (current == null) saved,
      ]..sort((left, right) => left.name.compareTo(right.name));
      data = data!.copyWith(classrooms: List.unmodifiable(classrooms));
      return true;
    } on TeachingScheduleException catch (exception) {
      error = exception.message;
      return false;
    } finally {
      catalogSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deactivateClassroom(ScheduleClassroom classroom) async {
    if (blocks.any((item) => item.classroomId == classroom.id)) {
      error = 'Retire primero los bloques programados en esta aula.';
      notifyListeners();
      return false;
    }
    if (catalogSaving) return false;
    catalogSaving = true;
    error = null;
    notifyListeners();
    try {
      await _repository.deactivateClassroom(classroom.id);
      data = data!.copyWith(
        classrooms: List.unmodifiable(
          data!.classrooms.where((item) => item.id != classroom.id),
        ),
      );
      return true;
    } on TeachingScheduleException catch (exception) {
      error = exception.message;
      return false;
    } finally {
      catalogSaving = false;
      notifyListeners();
    }
  }

  String? takeError() {
    final value = error;
    error = null;
    return value;
  }

  void _setLoaded(SchedulePlannerData loaded) {
    data = loaded;
    blocks = List.unmodifiable(loaded.blocks);
    assignments = List.unmodifiable(loaded.assignments);
    _synchronizeAutomaticWeeklyMinutes();
    removedAssignmentIds.clear();
    removedBlockIds.clear();
    dirty = false;
    error = null;
  }

  void _synchronizeAutomaticWeeklyMinutes() {
    assignments = List.unmodifiable(
      assignments.map((assignment) {
        final total = scheduledMinutes(assignment);
        return assignment.copyWith(weeklyMinutes: total == 0 ? 30 : total);
      }),
    );
  }

  static int _compareBlocks(
    PlannerScheduleBlock left,
    PlannerScheduleBlock right,
  ) {
    final day = left.weekday.compareTo(right.weekday);
    return day != 0 ? day : left.startMinutes.compareTo(right.startMinutes);
  }
}

class _PlannerDraftSnapshot {
  const _PlannerDraftSnapshot({
    required this.assignments,
    required this.blocks,
    required this.removedAssignmentIds,
    required this.removedBlockIds,
    required this.dirty,
  });

  final List<AcademicAssignment> assignments;
  final List<PlannerScheduleBlock> blocks;
  final Set<String> removedAssignmentIds;
  final Set<String> removedBlockIds;
  final bool dirty;
}
