import 'package:sis_amerinst/features/schedules/domain/schedule_planner_models.dart';
import 'package:sis_amerinst/features/schedules/domain/schedule_planner_repository.dart';
import 'package:sis_amerinst/features/schedules/domain/teacher_schedule_editor_models.dart';
import 'package:sis_amerinst/features/schedules/domain/teaching_schedule_models.dart';
import 'package:flutter/foundation.dart';

class SchedulePlannerViewModel extends ChangeNotifier {
  SchedulePlannerViewModel(this._repository);

  final SchedulePlannerRepository _repository;

  SchedulePlannerData? data;
  List<AcademicAssignment> assignments = const [];
  List<PlannerScheduleBlock> blocks = const [];
  final Set<int> removedAssignmentIds = {};
  final Set<int> removedBlockIds = {};
  final List<_PlannerDraftSnapshot> _undo = [];
  final List<_PlannerDraftSnapshot> _redo = [];
  _PlannerDraftSnapshot? _original;
  bool loading = false;
  bool saving = false;
  bool catalogSaving = false;
  bool dirty = false;
  bool refreshPending = false;
  String? error;
  String? refreshMessage;
  SchedulePlannerSaveException? conflict;

  bool get canUndo => _undo.isNotEmpty && !saving && !refreshPending;
  bool get canRedo => _redo.isNotEmpty && !saving && !refreshPending;

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

  int pendingMinutes(AcademicAssignment assignment) {
    final difference = assignment.weeklyMinutes - scheduledMinutes(assignment);
    return difference < 0 ? 0 : difference;
  }

  bool blockHasConflict(PlannerScheduleBlock block) {
    final value = conflict;
    if (value == null || value.weekday != block.weekday) return false;
    final start = value.startTime;
    final end = value.endTime;
    if (start == null || end == null) return true;
    return scheduleTimeToMinutes(start) < block.endMinutes &&
        scheduleTimeToMinutes(end) > block.startMinutes;
  }

  bool saveAssignment(
    AcademicAssignment assignment, {
    AcademicAssignment? current,
    bool recordHistory = true,
  }) {
    if (!_ensureEditable()) return false;
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
    if (recordHistory) _remember();
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
    conflict = null;
    notifyListeners();
    return true;
  }

  Future<bool> persistAssignment(
    AcademicAssignment assignment, {
    AcademicAssignment? current,
  }) async => saveAssignment(assignment, current: current);

  Future<bool> persistClass(
    AcademicAssignment assignment,
    PlannerBlockDraft draft, {
    AcademicAssignment? currentAssignment,
    PlannerScheduleBlock? currentBlock,
  }) async {
    final before = _snapshot();
    if (currentBlock != null) {
      if (!saveBlock(draft, current: currentBlock, recordHistory: false)) {
        return false;
      }
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
      if (!saveAssignment(
        assignment,
        current: refreshedCurrent,
        recordHistory: false,
      )) {
        final message = error;
        _restoreSnapshot(before);
        error = message;
        notifyListeners();
        return false;
      }
      _rememberSnapshot(before);
      notifyListeners();
      return true;
    }
    if (!saveAssignment(
      assignment,
      current: currentAssignment,
      recordHistory: false,
    )) {
      return false;
    }
    final savedAssignment = assignments.firstWhere(
      (item) => item.key == assignment.key,
    );
    if (!saveBlock(
      PlannerBlockDraft(
        assignment: savedAssignment,
        classroomId: draft.classroomId,
        weekday: draft.weekday,
        startMinutes: draft.startMinutes,
        endMinutes: draft.endMinutes,
      ),
      recordHistory: false,
    )) {
      final message = error;
      _restoreSnapshot(before);
      error = message;
      notifyListeners();
      return false;
    }
    _rememberSnapshot(before);
    notifyListeners();
    return true;
  }

  void removeAssignment(
    AcademicAssignment assignment, {
    bool recordHistory = true,
  }) {
    if (!_ensureEditable()) return;
    if (!assignments.contains(assignment)) return;
    if (recordHistory) _remember();
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
    conflict = null;
    notifyListeners();
  }

  Future<bool> persistRemoveAssignment(AcademicAssignment assignment) async {
    removeAssignment(assignment);
    return true;
  }

  bool saveBlock(
    PlannerBlockDraft draft, {
    PlannerScheduleBlock? current,
    bool recordHistory = true,
  }) {
    if (!_ensureEditable()) return false;
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
    final hasLocalConflict = blocks.any(
      (item) =>
          !identical(item, current) &&
          item.weekday == draft.weekday &&
          draft.startMinutes < item.endMinutes &&
          draft.endMinutes > item.startMinutes &&
          (item.teacherId == draft.assignment.teacherId ||
              item.courseId == draft.assignment.courseId ||
              item.classroomId == draft.classroomId),
    );
    if (hasLocalConflict) {
      error = 'El docente, curso o aula ya está ocupado en ese rango.';
      notifyListeners();
      return false;
    }
    if (recordHistory) _remember();
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
    conflict = null;
    notifyListeners();
    return true;
  }

  Future<bool> persistBlock(
    PlannerBlockDraft draft, {
    PlannerScheduleBlock? current,
  }) async => saveBlock(draft, current: current);

  void removeBlock(PlannerScheduleBlock block, {bool recordHistory = true}) {
    if (!_ensureEditable()) return;
    if (!blocks.contains(block)) return;
    if (recordHistory) _remember();
    if (block.id != null) removedBlockIds.add(block.id!);
    blocks = List.unmodifiable(blocks.where((item) => !identical(item, block)));
    dirty = true;
    conflict = null;
    notifyListeners();
  }

  Future<bool> persistRemoveBlock(PlannerScheduleBlock block) async {
    removeBlock(block);
    return true;
  }

  Future<bool> save() async {
    final loaded = data;
    if (loaded == null || saving || refreshPending || !dirty) return false;
    saving = true;
    error = null;
    refreshMessage = null;
    conflict = null;
    notifyListeners();
    try {
      final version = await _repository.savePlanner(
        periodId: loaded.period.id,
        version: loaded.config.version,
        assignments: assignments,
        blocks: blocks,
        removedAssignmentIds: removedAssignmentIds,
        removedBlockIds: removedBlockIds,
      );
      _markPlannerCommitted(version);
    } on SchedulePlannerSaveException catch (exception) {
      conflict = exception;
      error = exception.message;
      saving = false;
      notifyListeners();
      return false;
    } on TeachingScheduleException catch (exception) {
      error = exception.message;
      saving = false;
      notifyListeners();
      return false;
    }
    await _refreshCommittedState();
    saving = false;
    notifyListeners();
    return true;
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

  void undo() {
    if (!canUndo) return;
    _redo.add(_snapshot());
    _restoreSnapshot(_undo.removeLast());
    error = null;
    conflict = null;
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    _undo.add(_snapshot());
    _restoreSnapshot(_redo.removeLast());
    dirty = true;
    error = null;
    conflict = null;
    notifyListeners();
  }

  void discard() {
    final original = _original;
    if (!dirty || saving || original == null) return;
    _restoreSnapshot(original);
    _undo.clear();
    _redo.clear();
    dirty = false;
    error = null;
    conflict = null;
    notifyListeners();
  }

  Future<bool> saveGeneralConfig(GeneralScheduleDraft draft) async {
    if (refreshPending) {
      error = 'Recargue la planificación confirmada antes de editarla.';
      notifyListeners();
      return false;
    }
    if (dirty) {
      error = 'Guarde los cambios de la matriz antes de cambiar la jornada.';
      notifyListeners();
      return false;
    }
    saving = true;
    error = null;
    refreshMessage = null;
    notifyListeners();
    try {
      final version = await _repository.saveGeneralConfig(draft);
      _markGeneralConfigCommitted(draft, version);
    } on TeachingScheduleException catch (exception) {
      error = exception.message;
      saving = false;
      notifyListeners();
      return false;
    }
    await _refreshCommittedState();
    saving = false;
    notifyListeners();
    return true;
  }

  Future<bool> refreshAfterCommit() async {
    if (!refreshPending || loading || saving) return false;
    loading = true;
    error = null;
    notifyListeners();
    final refreshed = await _refreshCommittedState();
    loading = false;
    notifyListeners();
    return refreshed;
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
    removedAssignmentIds.clear();
    removedBlockIds.clear();
    _undo.clear();
    _redo.clear();
    dirty = false;
    refreshPending = false;
    error = null;
    refreshMessage = null;
    conflict = null;
    _original = _snapshot();
  }

  void _markPlannerCommitted(int version) {
    final loaded = data!;
    data = loaded.copyWith(
      config: loaded.config.copyWith(version: version),
      assignments: List.unmodifiable(assignments),
      blocks: List.unmodifiable(blocks),
    );
    _markDraftCommitted();
  }

  void _markGeneralConfigCommitted(GeneralScheduleDraft draft, int version) {
    final loaded = data!;
    data = loaded.copyWith(
      config: loaded.config.copyWith(
        periodId: draft.periodId,
        startTime: draft.startTime,
        endTime: draft.endTime,
        intervalMinutes: draft.intervalMinutes,
        toleranceMinutes: draft.toleranceMinutes,
        timeZone: draft.timeZone,
        version: version,
      ),
      breaks: List.unmodifiable(draft.breaks),
      configurationPending: false,
    );
    _markDraftCommitted();
  }

  void _markDraftCommitted() {
    removedAssignmentIds.clear();
    removedBlockIds.clear();
    _undo.clear();
    _redo.clear();
    dirty = false;
    conflict = null;
    _original = _snapshot();
  }

  Future<bool> _refreshCommittedState() async {
    try {
      _setLoaded(await _repository.getPlanner());
      return true;
    } on TeachingScheduleException catch (exception) {
      refreshPending = true;
      refreshMessage =
          'Los cambios se guardaron, pero no se pudo recargar la planificación: ${exception.message}';
      return false;
    }
  }

  bool _ensureEditable() {
    if (!refreshPending) return true;
    error = 'Recargue la planificación confirmada antes de editarla.';
    notifyListeners();
    return false;
  }

  _PlannerDraftSnapshot _snapshot() => _PlannerDraftSnapshot(
    assignments: assignments,
    blocks: blocks,
    removedAssignmentIds: Set.of(removedAssignmentIds),
    removedBlockIds: Set.of(removedBlockIds),
    dirty: dirty,
  );

  void _remember() => _rememberSnapshot(_snapshot());

  void _rememberSnapshot(_PlannerDraftSnapshot snapshot) {
    _undo.add(snapshot);
    if (_undo.length > 50) _undo.removeAt(0);
    _redo.clear();
    dirty = true;
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
  final Set<int> removedAssignmentIds;
  final Set<int> removedBlockIds;
  final bool dirty;
}
