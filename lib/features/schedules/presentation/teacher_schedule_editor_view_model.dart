import 'package:asisteqr_baker/features/schedules/domain/teacher_schedule_editor_models.dart';
import 'package:asisteqr_baker/features/schedules/domain/teacher_schedule_editor_repository.dart';
import 'package:asisteqr_baker/features/schedules/domain/teaching_schedule_models.dart';
import 'package:flutter/foundation.dart';

class TeacherScheduleEditorViewModel extends ChangeNotifier {
  TeacherScheduleEditorViewModel(this._repository, this.teacherId);

  final TeacherScheduleEditorRepository _repository;
  final String teacherId;

  TeacherScheduleEditorData? data;
  List<TeacherScheduleBlock> blocks = const [];
  String? selectedCourseId;
  String? selectedSubjectId;
  String? selectedClassroomId;
  bool loading = false;
  bool saving = false;
  bool dirty = false;
  String? error;
  final List<List<TeacherScheduleBlock>> _undo = [];
  final List<List<TeacherScheduleBlock>> _redo = [];
  int _temporaryId = 0;

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  bool get canCreateBlock =>
      selectedCourseId != null &&
      selectedSubjectId != null &&
      selectedClassroomId != null;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final loaded = await _repository.getEditor(teacherId);
      data = loaded;
      blocks = List.unmodifiable(loaded.blocks);
      selectedCourseId = _validSelection(
        selectedCourseId,
        loaded.courses.map((item) => item.id),
      );
      selectedSubjectId = _validSelection(
        selectedSubjectId,
        loaded.subjects.map((item) => item.id),
      );
      selectedClassroomId = _validSelection(
        selectedClassroomId,
        loaded.classrooms.map((item) => item.id),
      );
      selectedCourseId ??= loaded.courses.firstOrNull?.id;
      selectedSubjectId ??= loaded.subjects.firstOrNull?.id;
      selectedClassroomId ??= loaded.classrooms.firstOrNull?.id;
      _undo.clear();
      _redo.clear();
      dirty = false;
    } on TeachingScheduleException catch (exception) {
      error = exception.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void selectCourse(String? value) {
    selectedCourseId = value;
    notifyListeners();
  }

  void selectSubject(String? value) {
    selectedSubjectId = value;
    notifyListeners();
  }

  void selectClassroom(String? value) {
    selectedClassroomId = value;
    notifyListeners();
  }

  bool addRange({
    required int weekday,
    required int startMinutes,
    required int endMinutes,
  }) {
    final current = data;
    if (current == null || !canCreateBlock) return false;
    if (endMinutes <= startMinutes) return false;
    if (current.breaks.any(
      (item) => item.includesRange(startMinutes, endMinutes),
    )) {
      error = 'El rango seleccionado ocupa el recreo general.';
      notifyListeners();
      return false;
    }
    if (blocks.any(
      (item) =>
          item.weekday == weekday &&
          startMinutes < item.endMinutes &&
          endMinutes > item.startMinutes,
    )) {
      error = 'El docente ya tiene una clase en ese rango.';
      notifyListeners();
      return false;
    }
    final course = current.courses.firstWhere(
      (item) => item.id == selectedCourseId,
    );
    final subject = current.subjects.firstWhere(
      (item) => item.id == selectedSubjectId,
    );
    final classroom = current.classrooms.firstWhere(
      (item) => item.id == selectedClassroomId,
    );
    _remember();
    final updated = <TeacherScheduleBlock>[
      ...blocks,
      TeacherScheduleBlock(
        id: 'nuevo-${_temporaryId++}',
        courseId: course.id,
        courseName: course.name,
        subjectId: subject.id,
        subjectName: subject.name,
        classroomId: classroom.id,
        classroomName: classroom.name,
        weekday: weekday,
        startTime: scheduleMinutesToTime(startMinutes),
        endTime: scheduleMinutesToTime(endMinutes),
      ),
    ]..sort(_compareBlocks);
    blocks = List.unmodifiable(updated);
    dirty = true;
    error = null;
    notifyListeners();
    return true;
  }

  void removeBlock(String id) {
    if (!blocks.any((item) => item.id == id)) return;
    _remember();
    blocks = List.unmodifiable(blocks.where((item) => item.id != id));
    dirty = true;
    notifyListeners();
  }

  void undo() {
    if (_undo.isEmpty) return;
    _redo.add(blocks);
    blocks = List.unmodifiable(_undo.removeLast());
    dirty = true;
    notifyListeners();
  }

  void redo() {
    if (_redo.isEmpty) return;
    _undo.add(blocks);
    blocks = List.unmodifiable(_redo.removeLast());
    dirty = true;
    notifyListeners();
  }

  Future<bool> save() async {
    final current = data;
    if (current == null || saving) return false;
    saving = true;
    error = null;
    notifyListeners();
    try {
      final saved = await _repository.saveMatrix(
        teacherId: teacherId,
        periodId: current.period.id,
        version: current.config.version,
        blocks: blocks,
      );
      final config = GeneralScheduleConfig(
        id: current.config.id,
        periodId: current.config.periodId,
        startTime: current.config.startTime,
        endTime: current.config.endTime,
        intervalMinutes: current.config.intervalMinutes,
        toleranceMinutes: current.config.toleranceMinutes,
        timeZone: current.config.timeZone,
        version: saved.version,
      );
      blocks = List.unmodifiable(saved.blocks);
      data = TeacherScheduleEditorData(
        teacher: current.teacher,
        period: current.period,
        config: config,
        breaks: current.breaks,
        courses: current.courses,
        subjects: current.subjects,
        classrooms: current.classrooms,
        blocks: blocks,
      );
      _undo.clear();
      _redo.clear();
      dirty = false;
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
      error = 'Guarde o deshaga los cambios de la matriz antes de configurar.';
      notifyListeners();
      return false;
    }
    saving = true;
    error = null;
    notifyListeners();
    try {
      await _repository.saveGeneralConfig(draft);
      await load();
      return error == null;
    } on TeachingScheduleException catch (exception) {
      error = exception.message;
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  String? takeError() {
    final message = error;
    error = null;
    notifyListeners();
    return message;
  }

  void _remember() {
    _undo.add(blocks);
    if (_undo.length > 30) _undo.removeAt(0);
    _redo.clear();
  }

  String? _validSelection(String? value, Iterable<String> ids) =>
      value != null && ids.contains(value) ? value : null;

  static int _compareBlocks(
    TeacherScheduleBlock first,
    TeacherScheduleBlock second,
  ) {
    final day = first.weekday.compareTo(second.weekday);
    return day != 0 ? day : first.startMinutes.compareTo(second.startMinutes);
  }
}
