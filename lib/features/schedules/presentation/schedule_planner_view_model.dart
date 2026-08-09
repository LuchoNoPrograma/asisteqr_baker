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

  int remainingMinutes(AcademicAssignment assignment) =>
      assignment.weeklyMinutes - scheduledMinutes(assignment);

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
    final scheduled = current == null ? 0 : scheduledMinutes(current);
    if (assignment.weeklyMinutes < scheduled) {
      error = 'La carga semanal no puede ser menor a los bloques programados.';
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
    dirty = true;
    error = null;
    notifyListeners();
    return true;
  }

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
    final scheduledWithoutCurrent =
        scheduledMinutes(draft.assignment) -
        (current != null &&
                current.courseId == draft.assignment.courseId &&
                current.subjectId == draft.assignment.subjectId &&
                current.teacherId == draft.assignment.teacherId
            ? current.durationMinutes
            : 0);
    if (scheduledWithoutCurrent + draft.endMinutes - draft.startMinutes >
        draft.assignment.weeklyMinutes) {
      error = 'El bloque supera la carga semanal de la asignación.';
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
    dirty = true;
    error = null;
    notifyListeners();
    return true;
  }

  void removeBlock(PlannerScheduleBlock block) {
    if (block.id != null) removedBlockIds.add(block.id!);
    blocks = List.unmodifiable(blocks.where((item) => !identical(item, block)));
    dirty = true;
    notifyListeners();
  }

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

  String? takeError() {
    final value = error;
    error = null;
    return value;
  }

  void _setLoaded(SchedulePlannerData loaded) {
    data = loaded;
    assignments = List.unmodifiable(loaded.assignments);
    blocks = List.unmodifiable(loaded.blocks);
    removedAssignmentIds.clear();
    removedBlockIds.clear();
    dirty = false;
    error = null;
  }

  static int _compareBlocks(
    PlannerScheduleBlock left,
    PlannerScheduleBlock right,
  ) {
    final day = left.weekday.compareTo(right.weekday);
    return day != 0 ? day : left.startMinutes.compareTo(right.startMinutes);
  }
}
