import 'package:asisteqr_baker/features/courses/domain/course_models.dart';

abstract interface class CourseRepository {
  Future<List<CourseEntry>> getCourses({String? search});
  Future<CourseEntry> createCourse(CourseDraft draft);
  Future<CourseEntry> updateCourse(String id, CourseDraft draft);
  Future<void> deactivateCourse(String id);
  Future<CourseSchedule> createSchedule(String courseId, ScheduleDraft draft);
  Future<CourseSchedule> updateSchedule(
    String courseId,
    String scheduleId,
    ScheduleDraft draft,
  );
  Future<void> deactivateSchedule(String courseId, String scheduleId);
}

class CourseException implements Exception {
  const CourseException(this.message);
  final String message;
}
