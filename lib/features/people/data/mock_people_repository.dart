import 'package:asisteqr_baker/features/people/domain/people_models.dart';
import 'package:asisteqr_baker/features/people/domain/people_repository.dart';

class MockPeopleRepository implements PeopleRepository {
  final courses = const [
    CourseOption(id: 'course-4b', name: '4.º Secundaria B'),
    CourseOption(id: 'course-5a', name: '5.º Secundaria A'),
  ];
  final students = <StudentEntry>[
    StudentEntry(
      id: 'student-1',
      studentCode: 1,
      firstNames: 'Valeria',
      lastNames: 'Mendoza Rojas',
      birthDate: DateTime(2010, 5, 14),
      documentNumber: '9876543',
      guardianName: 'Ana Rojas',
      guardianPhone: '71234567',
      status: 'ACTIVO',
      course: CourseOption(id: 'course-4b', name: '4.º Secundaria B'),
    ),
  ];
  final teachers = <TeacherEntry>[
    const TeacherEntry(
      id: 'teacher-1',
      teacherCode: 1,
      firstNames: 'María Elena',
      lastNames: 'Rodríguez Flores',
      specialty: 'Matemática y Física',
      documentNumber: '4567890',
      email: 'm.rodriguez@baker.edu.bo',
      phone: '70112233',
      status: 'ACTIVO',
      courses: [CourseOption(id: 'course-4b', name: '4.º Secundaria B')],
    ),
  ];

  @override
  Future<List<CourseOption>> getCourses() async => courses;

  @override
  Future<List<StudentEntry>> getStudents({
    String? search,
    String? courseId,
  }) async => students.where((item) {
    final normalizedSearch = search?.trim().toLowerCase();
    final matchesSearch =
        normalizedSearch == null ||
        normalizedSearch.isEmpty ||
        item.fullName.toLowerCase().contains(normalizedSearch) ||
        item.documentNumber?.toLowerCase().contains(normalizedSearch) == true ||
        item.studentCode.toString().contains(normalizedSearch);
    final matchesCourse = courseId == null || item.course?.id == courseId;
    return matchesSearch && matchesCourse;
  }).toList();

  @override
  Future<StudentEntry> createStudent(StudentDraft draft) async {
    final item = StudentEntry(
      id: 'student-${students.length + 1}',
      studentCode:
          students.fold<int>(
            0,
            (value, item) =>
                item.studentCode > value ? item.studentCode : value,
          ) +
          1,
      firstNames: draft.firstNames,
      lastNames: draft.lastNames,
      birthDate: draft.birthDate,
      documentNumber: draft.documentNumber,
      guardianName: draft.guardianName,
      guardianPhone: draft.guardianPhone,
      photoUrl: draft.photoUrl,
      status: 'ACTIVO',
      course: courses.firstWhere((item) => item.id == draft.courseId),
    );
    students.add(item);
    return item;
  }

  @override
  Future<StudentEntry> updateStudent(String id, StudentDraft draft) async {
    final index = students.indexWhere((item) => item.id == id);
    final current = students[index];
    final item = StudentEntry(
      id: id,
      studentCode: current.studentCode,
      firstNames: draft.firstNames,
      lastNames: draft.lastNames,
      birthDate: draft.birthDate,
      documentNumber: draft.documentNumber,
      guardianName: draft.guardianName,
      guardianPhone: draft.guardianPhone,
      photoUrl: draft.photoUrl,
      status: current.status,
      course: courses.firstWhere((item) => item.id == draft.courseId),
    );
    students[index] = item;
    return item;
  }

  @override
  Future<void> retireStudent(String id) async {
    final index = students.indexWhere((item) => item.id == id);
    final item = students[index];
    students[index] = StudentEntry(
      id: item.id,
      studentCode: item.studentCode,
      firstNames: item.firstNames,
      lastNames: item.lastNames,
      birthDate: item.birthDate,
      documentNumber: item.documentNumber,
      guardianName: item.guardianName,
      guardianPhone: item.guardianPhone,
      photoUrl: item.photoUrl,
      status: 'RETIRADO',
      course: item.course,
    );
  }

  @override
  Future<List<TeacherEntry>> getTeachers({String? search}) async => teachers
      .where(
        (item) =>
            search == null ||
            item.fullName.toLowerCase().contains(search.toLowerCase()),
      )
      .toList();

  @override
  Future<TeacherEntry> createTeacher(TeacherDraft draft) async {
    final code = teachers.length + 1;
    final item = _teacher('teacher-$code', code, draft);
    teachers.add(item);
    return item;
  }

  @override
  Future<TeacherEntry> updateTeacher(String id, TeacherDraft draft) async {
    final index = teachers.indexWhere((item) => item.id == id);
    final item = _teacher(id, teachers[index].teacherCode, draft);
    teachers[index] = item;
    return item;
  }

  TeacherEntry _teacher(String id, int teacherCode, TeacherDraft draft) =>
      TeacherEntry(
        id: id,
        teacherCode: teacherCode,
        firstNames: draft.firstNames,
        lastNames: draft.lastNames,
        specialty: draft.specialty,
        documentNumber: draft.documentNumber,
        email: draft.email,
        phone: draft.phone,
        photoUrl: draft.photoUrl,
        status: 'ACTIVO',
        courses: courses
            .where((item) => draft.courseIds.contains(item.id))
            .toList(),
      );

  @override
  Future<void> deactivateTeacher(String id) async {
    final index = teachers.indexWhere((item) => item.id == id);
    final item = teachers[index];
    teachers[index] = TeacherEntry(
      id: item.id,
      teacherCode: item.teacherCode,
      firstNames: item.firstNames,
      lastNames: item.lastNames,
      specialty: item.specialty,
      documentNumber: item.documentNumber,
      email: item.email,
      phone: item.phone,
      photoUrl: item.photoUrl,
      status: 'INACTIVO',
      courses: item.courses,
    );
  }
}
