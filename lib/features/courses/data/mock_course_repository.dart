import 'package:sis_amerinst/features/courses/domain/course_models.dart';
import 'package:sis_amerinst/features/courses/domain/course_repository.dart';

class MockCourseRepository implements CourseRepository {
  final courses = <CourseEntry>[
    const CourseEntry(
      id: 1,
      name: '4.º Secundaria B',
      level: '4.º Secundaria',
      parallel: 'B',
      year: 2026,
      studentCount: 32,
      teacherCount: 4,
      schedules: [
        CourseSchedule(
          id: 1,
          shift: 'MANANA',
          deadline: '08:00',
          toleranceMinutes: 5,
          timeZone: 'America/La_Paz',
        ),
      ],
    ),
  ];

  @override
  Future<List<CourseEntry>> getCourses({String? search}) async {
    final term = search?.trim().toLowerCase();
    if (term == null || term.isEmpty) return List.unmodifiable(courses);
    return courses
        .where((item) => item.name.toLowerCase().contains(term))
        .toList();
  }

  @override
  Future<CourseEntry> createCourse(CourseDraft draft) async {
    final item = _fromDraft(courses.length + 1, draft);
    courses.add(item);
    return item;
  }

  @override
  Future<CourseEntry> updateCourse(int id, CourseDraft draft) async {
    final index = courses.indexWhere((item) => item.id == id);
    final current = courses[index];
    final item = _fromDraft(id, draft, current: current);
    courses[index] = item;
    return item;
  }

  @override
  Future<void> deactivateCourse(int id) async {
    courses.removeWhere((item) => item.id == id);
  }

  @override
  Future<CourseSchedule> createSchedule(
    int courseId,
    ScheduleDraft draft,
  ) async {
    final schedule = _schedule(
      courses.expand((course) => course.schedules).length + 1,
      draft,
    );
    _replaceSchedules(courseId, (items) => [...items, schedule]);
    return schedule;
  }

  @override
  Future<CourseSchedule> updateSchedule(
    int courseId,
    int scheduleId,
    ScheduleDraft draft,
  ) async {
    final schedule = _schedule(scheduleId, draft);
    _replaceSchedules(
      courseId,
      (items) =>
          items.map((item) => item.id == scheduleId ? schedule : item).toList(),
    );
    return schedule;
  }

  @override
  Future<void> deactivateSchedule(int courseId, int scheduleId) async {
    _replaceSchedules(
      courseId,
      (items) => items.where((item) => item.id != scheduleId).toList(),
    );
  }

  CourseEntry _fromDraft(int id, CourseDraft draft, {CourseEntry? current}) =>
      CourseEntry(
        id: id,
        name: draft.name,
        level: draft.level,
        parallel: draft.parallel,
        year: draft.year,
        studentCount: current?.studentCount ?? 0,
        teacherCount: current?.teacherCount ?? 0,
        schedules: current?.schedules ?? const [],
      );

  CourseSchedule _schedule(int id, ScheduleDraft draft) => CourseSchedule(
    id: id,
    shift: draft.shift,
    deadline: draft.deadline,
    toleranceMinutes: draft.toleranceMinutes,
    timeZone: draft.timeZone,
  );

  void _replaceSchedules(
    int courseId,
    List<CourseSchedule> Function(List<CourseSchedule>) update,
  ) {
    final index = courses.indexWhere((item) => item.id == courseId);
    final current = courses[index];
    courses[index] = CourseEntry(
      id: current.id,
      name: current.name,
      level: current.level,
      parallel: current.parallel,
      year: current.year,
      studentCount: current.studentCount,
      teacherCount: current.teacherCount,
      schedules: update(current.schedules),
    );
  }
}
