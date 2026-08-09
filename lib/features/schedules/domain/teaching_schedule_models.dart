class TeachingSchedule {
  const TeachingSchedule({
    required this.id,
    required this.teacherId,
    required this.teacherCode,
    required this.teacherName,
    required this.teacherSpecialty,
    required this.courseId,
    required this.courseName,
    required this.subject,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    required this.active,
    this.teacherPhone,
  });

  final String id;
  final String teacherId;
  final int teacherCode;
  final String teacherName;
  final String teacherSpecialty;
  final String? teacherPhone;
  final String courseId;
  final String courseName;
  final String subject;
  final int weekday;
  final String startTime;
  final String endTime;
  final bool active;

  String get weekdayLabel => weekdayLabels[weekday] ?? 'Día $weekday';
  String get timeRange => '$startTime - $endTime';
}

class TeachingScheduleDraft {
  const TeachingScheduleDraft({
    required this.teacherId,
    required this.courseId,
    required this.subject,
    required this.weekday,
    required this.startTime,
    required this.endTime,
  });

  final String teacherId;
  final String courseId;
  final String subject;
  final int weekday;
  final String startTime;
  final String endTime;
}

const weekdayLabels = {
  DateTime.monday: 'Lunes',
  DateTime.tuesday: 'Martes',
  DateTime.wednesday: 'Miércoles',
  DateTime.thursday: 'Jueves',
  DateTime.friday: 'Viernes',
};

class TeachingScheduleException implements Exception {
  const TeachingScheduleException(this.message);

  final String message;
}
