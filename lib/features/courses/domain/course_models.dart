class CourseSchedule {
  const CourseSchedule({
    required this.id,
    required this.shift,
    required this.deadline,
    required this.toleranceMinutes,
    required this.timeZone,
  });

  final String id;
  final String shift;
  final String deadline;
  final int toleranceMinutes;
  final String timeZone;

  String get shiftLabel => switch (shift) {
    'MANANA' => 'Mañana',
    'TARDE' => 'Tarde',
    'NOCHE' => 'Noche',
    _ => shift,
  };
}

class CourseEntry {
  const CourseEntry({
    required this.id,
    required this.name,
    required this.level,
    required this.parallel,
    required this.year,
    required this.studentCount,
    required this.teacherCount,
    required this.schedules,
  });

  final String id;
  final String name;
  final String level;
  final String parallel;
  final int year;
  final int studentCount;
  final int teacherCount;
  final List<CourseSchedule> schedules;

  CourseEntry copyWith({List<CourseSchedule>? schedules}) => CourseEntry(
    id: id,
    name: name,
    level: level,
    parallel: parallel,
    year: year,
    studentCount: studentCount,
    teacherCount: teacherCount,
    schedules: schedules ?? this.schedules,
  );
}

class CourseDraft {
  const CourseDraft({
    required this.name,
    required this.level,
    required this.parallel,
    required this.year,
  });

  final String name;
  final String level;
  final String parallel;
  final int year;
}

class ScheduleDraft {
  const ScheduleDraft({
    required this.shift,
    required this.deadline,
    required this.toleranceMinutes,
    this.timeZone = 'America/La_Paz',
  });

  final String shift;
  final String deadline;
  final int toleranceMinutes;
  final String timeZone;
}
