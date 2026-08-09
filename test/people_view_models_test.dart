import 'package:asisteqr_baker/features/people/domain/people_models.dart';
import 'package:asisteqr_baker/features/people/domain/people_repository.dart';
import 'package:asisteqr_baker/features/people/presentation/students_view_model.dart';
import 'package:asisteqr_baker/features/people/presentation/teachers_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final studentDraft = StudentDraft(
    firstNames: 'Valeria',
    lastNames: 'Mendoza',
    courseId: 'course-1',
    birthDate: DateTime(2010, 3, 12),
    guardianName: 'Ana Mendoza',
  );
  const teacherDraft = TeacherDraft(
    firstNames: 'Julia',
    lastNames: 'Flores',
    specialty: 'Matematica',
    courseIds: ['course-1'],
  );

  test('estudiantes crea, actualiza y retira sin recargar la API', () async {
    final repository = _PeopleRepository();
    final model = StudentsViewModel(repository);

    expect(await model.save(studentDraft), isTrue);
    expect(model.students.single.fullName, 'Valeria Mendoza');

    final updated = StudentDraft(
      firstNames: 'Valeria',
      lastNames: 'Mendoza Rojas',
      courseId: 'course-1',
      birthDate: DateTime(2010, 3, 12),
      guardianName: 'Ana Mendoza',
    );
    expect(await model.save(updated, current: model.students.single), isTrue);
    expect(model.students.single.lastNames, 'Mendoza Rojas');

    expect(await model.retire(model.students.single), isTrue);
    expect(model.students.single.status, 'INACTIVO');
    expect(model.saving, isFalse);
  });

  test('docentes crea, actualiza e inactiva sin recargar la API', () async {
    final repository = _PeopleRepository();
    final model = TeachersViewModel(repository);

    expect(await model.save(teacherDraft), isTrue);
    expect(model.teachers.single.specialty, 'Matematica');

    const updated = TeacherDraft(
      firstNames: 'Julia',
      lastNames: 'Flores',
      specialty: 'Fisica',
      courseIds: ['course-1'],
    );
    expect(await model.save(updated, current: model.teachers.single), isTrue);
    expect(model.teachers.single.specialty, 'Fisica');

    expect(await model.deactivate(model.teachers.single), isTrue);
    expect(model.teachers.single.status, 'INACTIVO');
    expect(model.saving, isFalse);
  });

  test('expone el error cuando no se pueden cargar los cursos', () async {
    final repository = _PeopleRepository(failCourses: true);
    final students = StudentsViewModel(repository);
    final teachers = TeachersViewModel(repository);

    await students.load();
    await teachers.load();

    expect(students.loading, isFalse);
    expect(teachers.loading, isFalse);
    expect(students.error, 'No se pudieron cargar los cursos');
    expect(teachers.error, 'No se pudieron cargar los cursos');
  });
}

class _PeopleRepository implements PeopleRepository {
  _PeopleRepository({this.failCourses = false});

  final bool failCourses;
  final students = <StudentEntry>[];
  final teachers = <TeacherEntry>[];
  static const course = CourseOption(id: 'course-1', name: '4. Secundaria B');

  @override
  Future<List<CourseOption>> getCourses() async {
    if (failCourses) {
      throw const PeopleException('No se pudieron cargar los cursos');
    }
    return const [course];
  }

  @override
  Future<List<StudentEntry>> getStudents({String? search}) async => students;

  @override
  Future<StudentEntry> createStudent(StudentDraft draft) async {
    final student = _studentFromDraft('student-1', draft);
    students.add(student);
    return student;
  }

  @override
  Future<StudentEntry> updateStudent(String id, StudentDraft draft) async {
    final index = students.indexWhere((student) => student.id == id);
    if (index < 0) throw const PeopleException('Estudiante no encontrado');
    final updated = _studentFromDraft(id, draft);
    students[index] = updated;
    return updated;
  }

  @override
  Future<void> retireStudent(String id) async {
    final index = students.indexWhere((student) => student.id == id);
    if (index < 0) throw const PeopleException('Estudiante no encontrado');
    students[index] = students[index].copyWith(status: 'INACTIVO');
  }

  @override
  Future<List<TeacherEntry>> getTeachers({String? search}) async => teachers;

  @override
  Future<TeacherEntry> createTeacher(TeacherDraft draft) async {
    final teacher = _teacherFromDraft('teacher-1', draft);
    teachers.add(teacher);
    return teacher;
  }

  @override
  Future<TeacherEntry> updateTeacher(String id, TeacherDraft draft) async {
    final index = teachers.indexWhere((teacher) => teacher.id == id);
    if (index < 0) throw const PeopleException('Docente no encontrado');
    final updated = _teacherFromDraft(id, draft);
    teachers[index] = updated;
    return updated;
  }

  @override
  Future<void> deactivateTeacher(String id) async {
    final index = teachers.indexWhere((teacher) => teacher.id == id);
    if (index < 0) throw const PeopleException('Docente no encontrado');
    teachers[index] = teachers[index].copyWith(status: 'INACTIVO');
  }

  StudentEntry _studentFromDraft(String id, StudentDraft draft) => StudentEntry(
    id: id,
    studentCode: 1,
    firstNames: draft.firstNames,
    lastNames: draft.lastNames,
    status: 'ACTIVO',
    birthDate: draft.birthDate,
    documentNumber: draft.documentNumber,
    guardianName: draft.guardianName,
    guardianPhone: draft.guardianPhone,
    photoUrl: draft.photoUrl,
    course: course,
  );

  TeacherEntry _teacherFromDraft(String id, TeacherDraft draft) => TeacherEntry(
    id: id,
    teacherCode: 1,
    firstNames: draft.firstNames,
    lastNames: draft.lastNames,
    specialty: draft.specialty,
    status: 'ACTIVO',
    courses: const [course],
    documentNumber: draft.documentNumber,
    email: draft.email,
    phone: draft.phone,
    photoUrl: draft.photoUrl,
  );
}
