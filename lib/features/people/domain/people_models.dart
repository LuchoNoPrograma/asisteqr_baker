class CourseOption {
  const CourseOption({required this.id, required this.name});
  final String id;
  final String name;
}

class StudentEntry {
  const StudentEntry({
    required this.id,
    required this.studentCode,
    required this.firstNames,
    required this.lastNames,
    required this.status,
    this.birthDate,
    this.documentNumber,
    this.guardianName,
    this.guardianPhone,
    this.photoUrl,
    this.course,
  });

  final String id;
  final int studentCode;
  final String firstNames;
  final String lastNames;
  final DateTime? birthDate;
  final String? documentNumber;
  final String? guardianName;
  final String? guardianPhone;
  final String? photoUrl;
  final String status;
  final CourseOption? course;

  String get fullName => '$firstNames $lastNames';

  StudentEntry copyWith({String? status}) => StudentEntry(
    id: id,
    studentCode: studentCode,
    firstNames: firstNames,
    lastNames: lastNames,
    birthDate: birthDate,
    documentNumber: documentNumber,
    guardianName: guardianName,
    guardianPhone: guardianPhone,
    photoUrl: photoUrl,
    status: status ?? this.status,
    course: course,
  );
}

class TeacherEntry {
  const TeacherEntry({
    required this.id,
    required this.teacherCode,
    required this.firstNames,
    required this.lastNames,
    required this.specialty,
    required this.status,
    this.documentNumber,
    this.email,
    this.phone,
    this.photoUrl,
  });

  final String id;
  final int teacherCode;
  final String firstNames;
  final String lastNames;
  final String specialty;
  final String? documentNumber;
  final String? email;
  final String? phone;
  final String? photoUrl;
  final String status;

  String get fullName => '$firstNames $lastNames';

  TeacherEntry copyWith({String? status}) => TeacherEntry(
    id: id,
    teacherCode: teacherCode,
    firstNames: firstNames,
    lastNames: lastNames,
    specialty: specialty,
    documentNumber: documentNumber,
    email: email,
    phone: phone,
    photoUrl: photoUrl,
    status: status ?? this.status,
  );
}

class StudentDraft {
  const StudentDraft({
    required this.firstNames,
    required this.lastNames,
    required this.courseId,
    required this.birthDate,
    required this.guardianName,
    this.documentNumber,
    this.guardianPhone,
    this.photoUrl,
  });

  final String firstNames;
  final String lastNames;
  final DateTime birthDate;
  final String courseId;
  final String? documentNumber;
  final String guardianName;
  final String? guardianPhone;
  final String? photoUrl;
}

class TeacherDraft {
  const TeacherDraft({
    required this.firstNames,
    required this.lastNames,
    required this.specialty,
    this.documentNumber,
    this.email,
    this.phone,
    this.photoUrl,
  });

  final String firstNames;
  final String lastNames;
  final String specialty;
  final String? documentNumber;
  final String? email;
  final String? phone;
  final String? photoUrl;
}
