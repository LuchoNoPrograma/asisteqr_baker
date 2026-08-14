import 'package:asisteqr_baker/features/courses/domain/course_models.dart';
import 'package:asisteqr_baker/features/courses/domain/course_repository.dart';
import 'package:asisteqr_baker/features/courses/presentation/courses_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const draft = CourseDraft(
    name: '1.º Secundaria A',
    level: '1.º Secundaria',
    parallel: 'A',
    year: 2026,
  );

  test(
    'habilita nuevamente las acciones después de registrar un curso',
    () async {
      final model = CoursesViewModel(_CourseRepository());

      expect(await model.saveCourse(draft), isTrue);
      expect(model.saving, isFalse);
      expect(model.courses, hasLength(1));
    },
  );

  test('habilita nuevamente las acciones cuando guardar falla', () async {
    final model = CoursesViewModel(_CourseRepository(failOnSave: true));

    expect(await model.saveCourse(draft), isFalse);
    expect(model.saving, isFalse);
    expect(model.error, 'Fallo controlado');
  });

  test(
    'mantiene el CRUD de cursos y horarios sincronizado localmente',
    () async {
      final repository = _CourseRepository();
      final model = CoursesViewModel(repository);
      await model.saveCourse(draft);

      const updatedDraft = CourseDraft(
        name: '2. Secundaria B',
        level: '2. Secundaria',
        parallel: 'B',
        year: 2026,
      );
      expect(
        await model.saveCourse(updatedDraft, current: model.courses.single),
        isTrue,
      );
      expect(model.courses.single.name, updatedDraft.name);

      const morning = ScheduleDraft(
        shift: 'MANANA',
        deadline: '08:00',
        toleranceMinutes: 10,
      );
      expect(await model.saveSchedule(model.courses.single, morning), isTrue);
      expect(model.courses.single.schedules.single.deadline, '08:00');

      const updatedMorning = ScheduleDraft(
        shift: 'MANANA',
        deadline: '08:15',
        toleranceMinutes: 5,
      );
      final schedule = model.courses.single.schedules.single;
      expect(
        await model.saveSchedule(
          model.courses.single,
          updatedMorning,
          current: schedule,
        ),
        isTrue,
      );
      expect(model.courses.single.schedules.single.deadline, '08:15');

      expect(
        await model.deactivateSchedule(
          model.courses.single,
          model.courses.single.schedules.single,
        ),
        isTrue,
      );
      expect(model.courses.single.schedules, isEmpty);

      expect(await model.deactivateCourse(model.courses.single), isTrue);
      expect(model.courses, isEmpty);
      expect(model.saving, isFalse);
    },
  );
}

class _CourseRepository implements CourseRepository {
  _CourseRepository({this.failOnSave = false});

  final bool failOnSave;
  final courses = <CourseEntry>[];

  @override
  Future<CourseEntry> createCourse(CourseDraft draft) async {
    if (failOnSave) throw const CourseException('Fallo controlado');
    final course = CourseEntry(
      id: 'course-1',
      name: draft.name,
      level: draft.level,
      parallel: draft.parallel,
      year: draft.year,
      studentCount: 0,
      teacherCount: 0,
      schedules: const [],
    );
    courses.add(course);
    return course;
  }

  @override
  Future<List<CourseEntry>> getCourses({String? search}) async => courses;

  @override
  Future<CourseEntry> updateCourse(String id, CourseDraft draft) async {
    final index = courses.indexWhere((course) => course.id == id);
    if (index < 0) throw const CourseException('Curso no encontrado');
    final current = courses[index];
    final updated = CourseEntry(
      id: current.id,
      name: draft.name,
      level: draft.level,
      parallel: draft.parallel,
      year: draft.year,
      studentCount: current.studentCount,
      teacherCount: current.teacherCount,
      schedules: current.schedules,
    );
    courses[index] = updated;
    return updated;
  }

  @override
  Future<void> deactivateCourse(String id) async {
    courses.removeWhere((course) => course.id == id);
  }

  @override
  Future<CourseSchedule> createSchedule(
    String courseId,
    ScheduleDraft draft,
  ) async {
    final schedule = _scheduleFromDraft('schedule-1', draft);
    _replaceSchedules(courseId, [
      ...courses.singleWhere((course) => course.id == courseId).schedules,
      schedule,
    ]);
    return schedule;
  }

  @override
  Future<CourseSchedule> updateSchedule(
    String courseId,
    String scheduleId,
    ScheduleDraft draft,
  ) async {
    final updated = _scheduleFromDraft(scheduleId, draft);
    final current = courses.singleWhere((course) => course.id == courseId);
    _replaceSchedules(courseId, [
      for (final schedule in current.schedules)
        schedule.id == scheduleId ? updated : schedule,
    ]);
    return updated;
  }

  @override
  Future<void> deactivateSchedule(String courseId, String scheduleId) async {
    final current = courses.singleWhere((course) => course.id == courseId);
    _replaceSchedules(
      courseId,
      current.schedules.where((schedule) => schedule.id != scheduleId).toList(),
    );
  }

  CourseSchedule _scheduleFromDraft(String id, ScheduleDraft draft) =>
      CourseSchedule(
        id: id,
        shift: draft.shift,
        deadline: draft.deadline,
        toleranceMinutes: draft.toleranceMinutes,
        timeZone: draft.timeZone,
      );

  void _replaceSchedules(String courseId, List<CourseSchedule> schedules) {
    final index = courses.indexWhere((course) => course.id == courseId);
    if (index < 0) throw const CourseException('Curso no encontrado');
    courses[index] = courses[index].copyWith(schedules: schedules);
  }
}
