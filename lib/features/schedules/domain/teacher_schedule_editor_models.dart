import 'package:asisteqr_baker/features/schedules/domain/teaching_schedule_models.dart';

class ScheduleTeacher {
  const ScheduleTeacher({
    required this.id,
    required this.code,
    required this.fullName,
    required this.specialty,
    this.phone,
    this.email,
    this.photoUrl,
  });

  final String id;
  final int code;
  final String fullName;
  final String specialty;
  final String? phone;
  final String? email;
  final String? photoUrl;
}

class SchedulePeriod {
  const SchedulePeriod({
    required this.id,
    required this.name,
    required this.year,
  });

  final String id;
  final String name;
  final int year;
}

class GeneralScheduleConfig {
  const GeneralScheduleConfig({
    required this.id,
    required this.periodId,
    required this.startTime,
    required this.endTime,
    required this.intervalMinutes,
    required this.toleranceMinutes,
    required this.timeZone,
    required this.version,
  });

  final String id;
  final String periodId;
  final String startTime;
  final String endTime;
  final int intervalMinutes;
  final int toleranceMinutes;
  final String timeZone;
  final int version;

  int get startMinutes => scheduleTimeToMinutes(startTime);
  int get endMinutes => scheduleTimeToMinutes(endTime);
}

class GeneralScheduleDraft {
  const GeneralScheduleDraft({
    required this.periodId,
    required this.version,
    required this.startTime,
    required this.endTime,
    required this.toleranceMinutes,
    required this.breaks,
    this.intervalMinutes = 30,
    this.timeZone = 'America/La_Paz',
  });

  final String periodId;
  final int version;
  final String startTime;
  final String endTime;
  final int intervalMinutes;
  final int toleranceMinutes;
  final String timeZone;
  final List<ScheduleBreak> breaks;
}

class ScheduleBreak {
  const ScheduleBreak({
    required this.name,
    required this.startTime,
    required this.endTime,
    this.id,
  });

  final String? id;
  final String name;
  final String startTime;
  final String endTime;

  bool includesRange(int start, int end) =>
      start < scheduleTimeToMinutes(endTime) &&
      end > scheduleTimeToMinutes(startTime);
}

class ScheduleCourse {
  const ScheduleCourse({required this.id, required this.name});
  final String id;
  final String name;
}

class ScheduleSubject {
  const ScheduleSubject({
    required this.id,
    required this.code,
    required this.name,
  });
  final String id;
  final String code;
  final String name;
}

class ScheduleClassroom {
  const ScheduleClassroom({
    required this.id,
    required this.code,
    required this.name,
    this.capacity,
    this.location,
  });
  final String id;
  final String code;
  final String name;
  final int? capacity;
  final String? location;
}

class TeacherScheduleBlock {
  const TeacherScheduleBlock({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.subjectId,
    required this.subjectName,
    required this.classroomId,
    required this.classroomName,
    required this.weekday,
    required this.startTime,
    required this.endTime,
  });

  final String id;
  final String courseId;
  final String courseName;
  final String subjectId;
  final String subjectName;
  final String classroomId;
  final String classroomName;
  final int weekday;
  final String startTime;
  final String endTime;

  int get startMinutes => scheduleTimeToMinutes(startTime);
  int get endMinutes => scheduleTimeToMinutes(endTime);
  String get weekdayLabel => weekdayLabels[weekday] ?? 'Día $weekday';
}

class TeacherScheduleEditorData {
  const TeacherScheduleEditorData({
    required this.teacher,
    required this.period,
    required this.config,
    required this.breaks,
    required this.courses,
    required this.subjects,
    required this.classrooms,
    required this.blocks,
  });

  final ScheduleTeacher teacher;
  final SchedulePeriod period;
  final GeneralScheduleConfig config;
  final List<ScheduleBreak> breaks;
  final List<ScheduleCourse> courses;
  final List<ScheduleSubject> subjects;
  final List<ScheduleClassroom> classrooms;
  final List<TeacherScheduleBlock> blocks;
}

int scheduleTimeToMinutes(String value) {
  final parts = value.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

String scheduleMinutesToTime(int value) {
  final hours = value ~/ 60;
  final minutes = value % 60;
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
}
