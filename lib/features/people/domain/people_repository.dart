import 'package:asisteqr_baker/features/people/domain/people_models.dart';

abstract interface class PeopleRepository {
  Future<List<CourseOption>> getCourses();
  Future<List<StudentEntry>> getStudents({String? search});
  Future<StudentEntry> createStudent(StudentDraft draft);
  Future<StudentEntry> updateStudent(String id, StudentDraft draft);
  Future<void> retireStudent(String id);
  Future<List<TeacherEntry>> getTeachers({String? search});
  Future<TeacherEntry> createTeacher(TeacherDraft draft);
  Future<TeacherEntry> updateTeacher(String id, TeacherDraft draft);
  Future<void> deactivateTeacher(String id);
}

class PeopleException implements Exception {
  const PeopleException(this.message);
  final String message;
}
