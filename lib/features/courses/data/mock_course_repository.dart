import 'package:asisteqr_baker/features/courses/domain/course_models.dart';
import 'package:asisteqr_baker/features/courses/domain/course_repository.dart';

class MockCourseRepository implements CourseRepository {
  final courses = <CourseEntry>[
    const CourseEntry(
      id: 'course-4b',
      name: '4.º Secundaria B',
      level: '4.º Secundaria',
      parallel: 'B',
      year: 2026,
      studentCount: 32,
      teacherCount: 4,
      schedules: [
        CourseSchedule(
          id: 'schedule-1',
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
    final item = _fromDraft('course-${courses.length + 1}', draft);
    courses.add(item);
    return item;
  }

  @override
  Future<CourseEntry> updateCourse(String id, CourseDraft draft) async {
    final index = courses.indexWhere((item) => item.id == id);
    final current = courses[index];
    final item = _fromDraft(id, draft, current: current);
    courses[index] = item;
    return item;
  }

  @override
  Future<void> deactivateCourse(String id) async {
    courses.removeWhere((item) => item.id == id);
  }

  @override
  Future<CourseSchedule> createSchedule(
    String courseId,
    ScheduleDraft draft,
  ) async {
    final schedule = _schedule(
      'schedule-${DateTime.now().microsecondsSinceEpoch}',
      draft,
    );
    _replaceSchedules(courseId, (items) => [...items, schedule]);
    return schedule;
  }

  @override
  Future<CourseSchedule> updateSchedule(
    String courseId,
    String scheduleId,
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
  Future<void> deactivateSchedule(String courseId, String scheduleId) async {
    _replaceSchedules(
      courseId,
      (items) => items.where((item) => item.id != scheduleId).toList(),
    );
  }

  CourseEntry _fromDraft(
    String id,
    CourseDraft draft, {
    CourseEntry? current,
  }) => CourseEntry(
    id: id,
    name: draft.name,
    level: draft.level,
    parallel: draft.parallel,
    year: draft.year,
    studentCount: current?.studentCount ?? 0,
    teacherCount: current?.teacherCount ?? 0,
    schedules: current?.schedules ?? const [],
  );

  CourseSchedule _schedule(String id, ScheduleDraft draft) => CourseSchedule(
    id: id,
    shift: draft.shift,
    deadline: draft.deadline,
    toleranceMinutes: draft.toleranceMinutes,
    timeZone: draft.timeZone,
  );

  void _replaceSchedules(
    String courseId,
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
