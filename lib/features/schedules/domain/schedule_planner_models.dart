import 'package:asisteqr_baker/features/schedules/domain/teacher_schedule_editor_models.dart';

class AcademicAssignment {
  const AcademicAssignment({
    this.id,
    required this.courseId,
    required this.subjectId,
    required this.teacherId,
    required this.weeklyMinutes,
  });

  final int? id;
  final int courseId;
  final int subjectId;
  final int teacherId;
  final int weeklyMinutes;

  String get key => '$courseId|$subjectId|$teacherId';

  AcademicAssignment copyWith({
    int? id,
    int? courseId,
    int? subjectId,
    int? teacherId,
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

  final int? id;
  final int courseId;
  final int subjectId;
  final int teacherId;
  final int classroomId;
  final int weekday;
  final String startTime;
  final String endTime;

  int get startMinutes => scheduleTimeToMinutes(startTime);
  int get endMinutes => scheduleTimeToMinutes(endTime);
  int get durationMinutes => endMinutes - startMinutes;

  PlannerScheduleBlock copyWith({
    int? id,
    int? courseId,
    int? subjectId,
    int? teacherId,
    int? classroomId,
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
    this.configurationPending = false,
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
  final bool configurationPending;

  SchedulePlannerData copyWith({
    GeneralScheduleConfig? config,
    List<ScheduleBreak>? breaks,
    List<ScheduleSubject>? subjects,
    List<ScheduleClassroom>? classrooms,
    List<AcademicAssignment>? assignments,
    List<PlannerScheduleBlock>? blocks,
    bool? configurationPending,
  }) => SchedulePlannerData(
    period: period,
    config: config ?? this.config,
    breaks: breaks ?? this.breaks,
    courses: courses,
    subjects: subjects ?? this.subjects,
    classrooms: classrooms ?? this.classrooms,
    teachers: teachers,
    assignments: assignments ?? this.assignments,
    blocks: blocks ?? this.blocks,
    configurationPending: configurationPending ?? this.configurationPending,
  );
}

class ScheduleSubjectDraft {
  const ScheduleSubjectDraft({required this.name});

  final String name;
}

class ScheduleClassroomDraft {
  const ScheduleClassroomDraft({
    required this.name,
    this.capacity,
    this.location,
  });

  final String name;
  final int? capacity;
  final String? location;
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
  final int classroomId;
  final int weekday;
  final int startMinutes;
  final int endMinutes;
}
