import 'package:sis_amerinst/features/people/domain/people_models.dart';

abstract interface class PeopleRepository {
  Future<List<CourseOption>> getCourses();
  Future<List<StudentEntry>> getStudents({String? search, int? courseId});
  Future<StudentEntry> createStudent(StudentDraft draft);
  Future<StudentEntry> updateStudent(int id, StudentDraft draft);
  Future<void> retireStudent(int id);
  Future<List<TeacherEntry>> getTeachers({String? search});
  Future<TeacherEntry> createTeacher(TeacherDraft draft);
  Future<TeacherEntry> updateTeacher(int id, TeacherDraft draft);
  Future<void> deactivateTeacher(int id);
}

class PeopleException implements Exception {
  const PeopleException(this.message);
  final String message;
}
