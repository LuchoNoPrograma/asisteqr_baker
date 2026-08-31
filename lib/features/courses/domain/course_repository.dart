import 'package:asisteqr_baker/features/courses/domain/course_models.dart';

abstract interface class CourseRepository {
  Future<List<CourseEntry>> getCourses({String? search});
  Future<CourseEntry> createCourse(CourseDraft draft);
  Future<CourseEntry> updateCourse(int id, CourseDraft draft);
  Future<void> deactivateCourse(int id);
  Future<CourseSchedule> createSchedule(int courseId, ScheduleDraft draft);
  Future<CourseSchedule> updateSchedule(
    int courseId,
    int scheduleId,
    ScheduleDraft draft,
  );
  Future<void> deactivateSchedule(int courseId, int scheduleId);
}

class CourseException implements Exception {
  const CourseException(this.message);
  final String message;
}
