import 'package:asisteqr_baker/features/schedules/domain/teacher_schedule_editor_models.dart';

class AcademicAssignment {
  const AcademicAssignment({
    this.id,
    required this.courseId,
    required this.subjectId,
    required this.teacherId,
    required this.weeklyMinutes,
  });

  final String? id;
  final String courseId;
  final String subjectId;
  final String teacherId;
  final int weeklyMinutes;

  String get key => '$courseId|$subjectId|$teacherId';

  AcademicAssignment copyWith({
    String? id,
    String? courseId,
    String? subjectId,
    String? teacherId,
    int? weeklyMinutes,
  }) => AcademicAssignment(
    id: id ?? this.id,
    courseId: courseId ?? this.courseId,
    subjectId: subjectId ?? this.subjectId,
    teacherId: teacherId ?? this.teacherId,
    weeklyMinutes: weeklyMinutes ?? this.weeklyMinutes,
  );
}

class PlannerScheduleBlock {
  const PlannerScheduleBlock({
    this.id,
    required this.courseId,
    required this.subjectId,
    required this.teacherId,
    required this.classroomId,
    required this.weekday,
    required this.startTime,
    required this.endTime,
  });

  final String? id;
  final String courseId;
  final String subjectId;
  final String teacherId;
  final String classroomId;
  final int weekday;
  final String startTime;
  final String endTime;

  int get startMinutes => scheduleTimeToMinutes(startTime);
  int get endMinutes => scheduleTimeToMinutes(endTime);
  int get durationMinutes => endMinutes - startMinutes;

  PlannerScheduleBlock copyWith({
    String? id,
    String? courseId,
    String? subjectId,
    String? teacherId,
    String? classroomId,
    int? weekday,
    String? startTime,
    String? endTime,
  }) => PlannerScheduleBlock(
    id: id ?? this.id,
    courseId: courseId ?? this.courseId,
    subjectId: subjectId ?? this.subjectId,
    teacherId: teacherId ?? this.teacherId,
    classroomId: classroomId ?? this.classroomId,
    weekday: weekday ?? this.weekday,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
  );
}

class SchedulePlannerData {
  const SchedulePlannerData({
    required this.period,
    required this.config,
    required this.breaks,
    required this.courses,
    required this.subjects,
    required this.classrooms,
    required this.teachers,
    required this.assignments,
    required this.blocks,
  });

  final SchedulePeriod period;
  final GeneralScheduleConfig config;
  final List<ScheduleBreak> breaks;
  final List<ScheduleCourse> courses;
  final List<ScheduleSubject> subjects;
  final List<ScheduleClassroom> classrooms;
  final List<ScheduleTeacher> teachers;
  final List<AcademicAssignment> assignments;
  final List<PlannerScheduleBlock> blocks;
}

class PlannerBlockDraft {
  const PlannerBlockDraft({
    required this.assignment,
    required this.classroomId,
    required this.weekday,
    required this.startMinutes,
    required this.endMinutes,
  });

  final AcademicAssignment assignment;
  final String classroomId;
  final int weekday;
  final int startMinutes;
  final int endMinutes;
}
