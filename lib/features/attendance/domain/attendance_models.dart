import 'package:equatable/equatable.dart';

enum AttendanceStatus { punctual, late, absent }

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
  });

  final String id;
  final String code;
  final String fullName;
  final String course;
  final String? photoSource;

  @override
  List<Object?> get props => [id, code, fullName, course, photoSource];
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
  });

  final int expected;
  final int present;
  final int punctual;
  final int late;
  final int absent;
  final List<AttendanceRecord> recent;

  double get attendanceRate => expected == 0 ? 0 : present / expected;

  @override
  List<Object?> get props => [
    expected,
    present,
    punctual,
    late,
    absent,
    recent,
  ];
}

enum AttendanceFailureKind {
  invalidQr,
  unreadableQr,
  inactiveStudent,
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
