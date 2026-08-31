import 'dart:async';

import 'package:asisteqr_baker/features/people/domain/people_models.dart';
import 'package:asisteqr_baker/features/people/domain/people_repository.dart';
import 'package:asisteqr_baker/features/people/presentation/students_view_model.dart';
import 'package:asisteqr_baker/features/people/presentation/teachers_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final studentDraft = StudentDraft(
    firstNames: 'Valeria',
    lastNames: 'Mendoza',
    courseId: 1,
    birthDate: DateTime(2010, 3, 12),
    guardianName: 'Ana Mendoza',
  );
  const teacherDraft = TeacherDraft(
    firstNames: 'Julia',
    lastNames: 'Flores',
    specialty: 'Matematica',
  );

  test('estudiantes crea, actualiza y retira sin recargar la API', () async {
    final repository = _PeopleRepository();
    final model = StudentsViewModel(repository);

    expect(await model.save(studentDraft), isTrue);
    expect(model.students.single.fullName, 'Valeria Mendoza');

    final updated = StudentDraft(
      firstNames: 'Valeria',
      lastNames: 'Mendoza Rojas',
      courseId: 1,
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
    );
    expect(await model.save(updated, current: model.teachers.single), isTrue);
    expect(model.teachers.single.specialty, 'Fisica');

    expect(await model.deactivate(model.teachers.single), isTrue);
    expect(model.teachers.single.status, 'INACTIVO');
    expect(model.saving, isFalse);
  });

  test('un conflicto de baja conserva al docente activo', () async {
    final repository = _PeopleRepository(failOnDeactivate: true);
    final teachers = TeachersViewModel(repository);
    await teachers.save(teacherDraft);

    expect(await teachers.deactivate(teachers.teachers.single), isFalse);
    expect(teachers.teachers.single.status, 'ACTIVO');
    expect(teachers.error, contains('dependencias activas'));
  });

  test('solo estudiantes depende del catálogo de cursos', () async {
    final repository = _PeopleRepository(failCourses: true);
    final students = StudentsViewModel(repository);
    final teachers = TeachersViewModel(repository);

    await students.load();
    await teachers.load();

    expect(students.loading, isFalse);
    expect(teachers.loading, isFalse);
    expect(students.error, 'No se pudieron cargar los cursos');
    expect(teachers.error, isNull);
  });

  test('filtra estudiantes por curso sin perder la busqueda', () async {
    final repository = _PeopleRepository();
    final model = StudentsViewModel(repository);

    model.search('Valeria');
    await model.filterCourse(1);

    expect(repository.lastStudentSearch, 'Valeria');
    expect(repository.lastStudentCourseId, 1);
    model.dispose();
  });

  test('estudiantes conserva el resultado de la carga mas reciente', () async {
    final repository = _DeferredPeopleRepository();
    final model = StudentsViewModel(repository);

    final oldLoad = model.load(search: 'anterior');
    final currentLoad = model.load(search: 'vigente');

    repository.studentLoads[1].complete([_student(2)]);
    await currentLoad;

    expect(model.students.single.id, 2);
    expect(model.loading, isFalse);

    repository.studentLoads[0].complete([_student(1)]);
    await oldLoad;

    expect(model.students.single.id, 2);
    expect(model.loading, isFalse);
  });

  test('docentes ignora errores de una carga reemplazada', () async {
    final repository = _DeferredPeopleRepository();
    final model = TeachersViewModel(repository);

    final oldLoad = model.load(search: 'anterior');
    final currentLoad = model.load(search: 'vigente');

    repository.teacherLoads[1].complete([_teacher(2)]);
    await currentLoad;

    expect(model.teachers.single.id, 2);
    expect(model.loading, isFalse);

    repository.teacherLoads[0].completeError(
      const PeopleException('Error de una busqueda anterior'),
    );
    await oldLoad;

    expect(model.teachers.single.id, 2);
    expect(model.error, isNull);
    expect(model.loading, isFalse);
  });
}

StudentEntry _student(int id) => StudentEntry(
  id: id,
  studentCode: 1,
  firstNames: 'Valeria',
  lastNames: 'Estudiante $id',
  status: 'ACTIVO',
);

TeacherEntry _teacher(int id) => TeacherEntry(
  id: id,
  teacherCode: 1,
  firstNames: 'Julia',
  lastNames: 'Docente $id',
  specialty: 'Matematica',
  status: 'ACTIVO',
);

class _DeferredPeopleRepository extends _PeopleRepository {
  final studentLoads = <Completer<List<StudentEntry>>>[];
  final teacherLoads = <Completer<List<TeacherEntry>>>[];

  @override
  Future<List<StudentEntry>> getStudents({String? search, int? courseId}) {
    final load = Completer<List<StudentEntry>>();
    studentLoads.add(load);
    return load.future;
  }

  @override
  Future<List<TeacherEntry>> getTeachers({String? search}) {
    final load = Completer<List<TeacherEntry>>();
    teacherLoads.add(load);
    return load.future;
  }
}

class _PeopleRepository implements PeopleRepository {
  _PeopleRepository({this.failCourses = false, this.failOnDeactivate = false});

  final bool failCourses;
  final bool failOnDeactivate;
  final students = <StudentEntry>[];
  final teachers = <TeacherEntry>[];
  String? lastStudentSearch;
  int? lastStudentCourseId;
  static const course = CourseOption(id: 1, name: '4. Secundaria B');

  @override
  Future<List<CourseOption>> getCourses() async {
    if (failCourses) {
      throw const PeopleException('No se pudieron cargar los cursos');
    }
    return const [course];
  }

  @override
  Future<List<StudentEntry>> getStudents({
    String? search,
    int? courseId,
  }) async {
    lastStudentSearch = search;
    lastStudentCourseId = courseId;
    return students;
  }

  @override
  Future<StudentEntry> createStudent(StudentDraft draft) async {
    final student = _studentFromDraft(1, draft);
    students.add(student);
    return student;
  }

  @override
  Future<StudentEntry> updateStudent(int id, StudentDraft draft) async {
    final index = students.indexWhere((student) => student.id == id);
    if (index < 0) throw const PeopleException('Estudiante no encontrado');
    final updated = _studentFromDraft(id, draft);
    students[index] = updated;
    return updated;
  }

  @override
  Future<void> retireStudent(int id) async {
    final index = students.indexWhere((student) => student.id == id);
    if (index < 0) throw const PeopleException('Estudiante no encontrado');
    students[index] = students[index].copyWith(status: 'INACTIVO');
  }

  @override
  Future<List<TeacherEntry>> getTeachers({String? search}) async => teachers;

  @override
  Future<TeacherEntry> createTeacher(TeacherDraft draft) async {
    final teacher = _teacherFromDraft(1, draft);
    teachers.add(teacher);
    return teacher;
  }

  @override
  Future<TeacherEntry> updateTeacher(int id, TeacherDraft draft) async {
    final index = teachers.indexWhere((teacher) => teacher.id == id);
    if (index < 0) throw const PeopleException('Docente no encontrado');
    final updated = _teacherFromDraft(id, draft);
    teachers[index] = updated;
    return updated;
  }

  @override
  Future<void> deactivateTeacher(int id) async {
    if (failOnDeactivate) {
      throw const PeopleException('Existen dependencias activas');
    }
    final index = teachers.indexWhere((teacher) => teacher.id == id);
    if (index < 0) throw const PeopleException('Docente no encontrado');
    teachers[index] = teachers[index].copyWith(status: 'INACTIVO');
  }

  StudentEntry _studentFromDraft(int id, StudentDraft draft) => StudentEntry(
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

  TeacherEntry _teacherFromDraft(int id, TeacherDraft draft) => TeacherEntry(
    id: id,
    teacherCode: 1,
    firstNames: draft.firstNames,
    lastNames: draft.lastNames,
    specialty: draft.specialty,
    status: 'ACTIVO',
    documentNumber: draft.documentNumber,
    email: draft.email,
    phone: draft.phone,
    photoUrl: draft.photoUrl,
  );
}
