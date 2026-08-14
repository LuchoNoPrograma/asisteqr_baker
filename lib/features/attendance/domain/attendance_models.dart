import 'package:equatable/equatable.dart';

enum AttendanceStatus { punctual, late, absent }

enum StudentGender { male, female }

extension AttendanceStatusLabel on AttendanceStatus {
  String get label => switch (this) {
    AttendanceStatus.punctual => 'Puntual',
    AttendanceStatus.late => 'Atraso',
    AttendanceStatus.absent => 'Ausente',
  };
}

class Student extends Equatable {
  const Student({
    required this.id,
    required this.code,
    required this.fullName,
    required this.course,
    this.photoSource,
    this.gender,
  });

  final String id;
  final String code;
  final String fullName;
  final String course;
  final String? photoSource;
  final StudentGender? gender;

  @override
  List<Object?> get props => [id, code, fullName, course, photoSource, gender];
}

class CourseAttendanceSummary extends Equatable {
  const CourseAttendanceSummary({
    required this.course,
    required this.expected,
    required this.present,
    required this.male,
    required this.female,
    required this.genderNotRegistered,
  });

  final String course;
  final int expected;
  final int present;
  final int male;
  final int female;
  final int genderNotRegistered;

  double get attendanceRate => expected == 0 ? 0 : present / expected;

  @override
  List<Object?> get props => [
    course,
    expected,
    present,
    male,
    female,
    genderNotRegistered,
  ];
}

class AttendanceRecord extends Equatable {
  const AttendanceRecord({
    required this.id,
    required this.student,
    required this.timestamp,
    required this.status,
  });

  final String id;
  final Student student;
  final DateTime timestamp;
  final AttendanceStatus status;

  @override
  List<Object?> get props => [id, student, timestamp, status];
}

class ScanResult extends Equatable {
  const ScanResult({
    required this.record,
    this.duplicate = false,
    this.originalTimestamp,
  });

  final AttendanceRecord record;
  final bool duplicate;
  final DateTime? originalTimestamp;

  @override
  List<Object?> get props => [record, duplicate, originalTimestamp];
}

class DashboardSummary extends Equatable {
  const DashboardSummary({
    required this.expected,
    required this.present,
    required this.punctual,
    required this.late,
    required this.absent,
    required this.recent,
    this.courses = const [],
  });

  final int expected;
  final int present;
  final int punctual;
  final int late;
  final int absent;
  final List<AttendanceRecord> recent;
  final List<CourseAttendanceSummary> courses;

  double get attendanceRate => expected == 0 ? 0 : present / expected;

  @override
  List<Object?> get props => [
    expected,
    present,
    punctual,
    late,
    absent,
    recent,
    courses,
  ];
}

enum AttendanceFailureKind {
  invalidQr,
  unreadableQr,
  inactiveStudent,
  studentNotFound,
  network,
  unauthorized,
  unknown,
}

class AttendanceException implements Exception {
  const AttendanceException(this.kind, this.message);
  final AttendanceFailureKind kind;
  final String message;

  @override
  String toString() => message;
}
